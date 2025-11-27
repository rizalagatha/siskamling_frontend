// lib/pages/scanner_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/checkpoint_args_model.dart';
import '../models/lokasi_barcode.dart';
import '../models/titik_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ScannerPage extends StatefulWidget {
  final CheckpointArgs args;

  const ScannerPage({super.key, required this.args});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    returnImage: false,
  );

  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Mengambil lokasi GPS...';
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog("Layanan lokasi tidak aktif. Mohon aktifkan GPS.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog("Izin lokasi ditolak.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog("Izin lokasi ditolak permanen. Ubah di pengaturan.");
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _isProcessing = false;
      _processingMessage = '';
    });
  }

  Future<void> _handleBarcodeDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'QR Code Terbaca...';
    });

    await _cameraController.stop(); // PENTING: await

    try {
      final barcode = capture.barcodes.firstWhere((b) => b.rawValue != null);
      final data = jsonDecode(barcode.rawValue!) as Map<String, dynamic>;
      final lokasiBarcode = LokasiBarcode.fromJson(data);

      if (lokasiBarcode.idTitik != widget.args.titik.id) {
        throw Exception("QR Code tidak sesuai checkpoint.");
      }

      setState(() {
        _processingMessage = 'Memvalidasi Lokasi GPS...';
      });

      final posisiPerangkat = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final jarak = Geolocator.distanceBetween(
        posisiPerangkat.latitude,
        posisiPerangkat.longitude,
        lokasiBarcode.latitude,
        lokasiBarcode.longitude,
      );

      if (jarak > 10.0) {
        throw Exception(
            "Lokasi Anda terlalu jauh (${jarak.toStringAsFixed(1)}m).");
      }

      // selfie
      final authProvider = context.read<AuthProvider>();
      final selfieBytes = await authProvider.getSelfieBytes();
      if (selfieBytes == null) throw Exception("Selfie belum diambil");

      setState(() {
        _processingMessage = 'Mengisi Laporan Temuan...';
      });

      final temuanResult = await _showFormTemuan();
      if (temuanResult == null) return;

      setState(() {
        _isProcessing = true;
        _processingMessage = 'Mengirim Laporan...';
      });

      await ApiService.submitAbsensi(
        user: widget.args.user,
        shift: widget.args.shift,
        titik: widget.args.titik,
        compressedSelfieData: selfieBytes,
        adaTemuan: temuanResult['adaTemuan'],
        catatan: temuanResult['catatan'],
        waktuMulai: widget.args.waktuMulai,
        waktuSelesai: DateTime.now(),
      );

      Navigator.pop(
        context,
        temuanResult['adaTemuan']
            ? ScanStatus.scannedWithFinding
            : ScanStatus.scannedOK,
      );
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      // Apapun yang terjadi, kamera kembali hidup
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _cameraController.start();
      }
    }
  }

  void _resetScanner() async {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _processingMessage = '';
    });

    // delay kecil untuk memastikan kamera siap
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      await _cameraController.start();
    } catch (_) {}
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showFormTemuan() {
    final catatanController = TextEditingController();
    bool adaTemuan = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Laporan Temuan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Apakah terdapat temuan di lokasi ini?'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ChoiceChip(
                          label: const Text('Tidak Ada'),
                          selected: !adaTemuan,
                          onSelected: (_) {
                            setDialogState(() {
                              adaTemuan = false;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Ada'),
                          selected: adaTemuan,
                          onSelected: (_) {
                            setDialogState(() {
                              adaTemuan = true;
                            });
                          },
                        ),
                      ],
                    ),
                    if (adaTemuan)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextField(
                          controller: catatanController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan Temuan',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('BATAL'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('SIMPAN'),
                  onPressed: () {
                    Navigator.of(context).pop({
                      'adaTemuan': adaTemuan,
                      'catatan': catatanController.text,
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR: ${widget.args.titik.nama}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              try {
                await _cameraController.toggleTorch();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Tidak bisa mengubah lampu flash: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleBarcodeDetection,
            scanWindow: scanWindow,
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: scanWindow.width,
                  height: scanWindow.height,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Posisikan QR Code di dalam kotak',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      _processingMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 🔧 Catatan: tambahkan method di AuthProvider
// Future<Uint8List> getSelfieBytes() async {
//   if (selfiePath == null) throw Exception("Selfie belum ada");
//   final file = File(selfiePath!);
//   return await file.readAsBytes();
// }
