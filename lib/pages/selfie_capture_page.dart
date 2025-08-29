// lib/pages/selfie_capture_page.dart

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_page.dart';

class SelfieCapturePage extends StatefulWidget {
  const SelfieCapturePage({super.key});

  @override
  State<SelfieCapturePage> createState() => _SelfieCapturePageState();
}

// --- PERBAIKAN 1: Tambahkan WidgetsBindingObserver ---
class _SelfieCapturePageState extends State<SelfieCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Daftarkan observer untuk mendengarkan perubahan siklus hidup aplikasi
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  // --- PERBAIKAN 2: Implementasikan didChangeAppLifecycleState ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Buat instance controller baru
      _controller = CameraController(frontCamera, ResolutionPreset.high,
          enableAudio: false);
      _initializeControllerFuture = _controller!.initialize();

      // Refresh UI
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menginisialisasi kamera: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _takeAndContinue() async {
    if (_isProcessing ||
        _controller == null ||
        !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    setState(() => _isProcessing = true);

    try {
      await _initializeControllerFuture;

      final image = await _controller!.takePicture();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      // Kompres
      final imgBytes = await image.readAsBytes();
      final compressedList = await FlutterImageCompress.compressWithList(
        imgBytes,
        minHeight: 1080,
        minWidth: 1080,
        quality: 50,
      );

      // Simpan path di provider
      context.read<AuthProvider>().setSelfie(image.path);

      // 🔧 jangan langsung dispose, beri delay cukup lama
      await Future.delayed(const Duration(milliseconds: 500));

      // Pindah halaman
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    // Buang observer dan controller saat halaman ditutup
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Foto Selfie')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              // --- PERBAIKAN 3: Tambahkan pengecekan controller ---
              if (snapshot.connectionState == ConnectionState.done &&
                  _controller != null &&
                  _controller!.value.isInitialized) {
                return CameraPreview(_controller!);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          // UI Overlay (tidak berubah)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), BlendMode.srcOut),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                    decoration: const BoxDecoration(color: Colors.transparent)),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'Posisikan Wajah Anda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'di dalam area yang tersedia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const Spacer(flex: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: IconButton(
                  onPressed: _isProcessing ? null : _takeAndContinue,
                  icon: const Icon(Icons.camera_alt, size: 60),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Memproses foto...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
