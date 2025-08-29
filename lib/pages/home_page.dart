// lib/pages/home_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/titik_model.dart';
import 'selfie_capture_page.dart';
import 'scanner_page.dart';
import '../providers/auth_provider.dart';
import '../providers/checkpoint_provider.dart';
import '../models/checkpoint_args_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _compressedSelfieData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<CheckpointProvider>().fetchTitik(user.idCabang);
      }
      //_takeSelfieOnce();
    });
  }

  // Future<void> _takeSelfieOnce() async {
  //   // Sekarang mengharapkan hasil berupa Uint8List
  //   final selfieData = await Navigator.push<Uint8List>(
  //     context,
  //     MaterialPageRoute(builder: (context) => const SelfieCapturePage()),
  //   );

  //   if (selfieData != null) {
  //     setState(() {
  //       _compressedSelfieData = selfieData;
  //     });
  //   } else {
  //     if (mounted) {
  //       Navigator.of(context).pop();
  //     }
  //   }
  // }

  Color _getColorForStatus(ScanStatus status) {
    switch (status) {
      case ScanStatus.scannedOK:
        return Colors.green;
      case ScanStatus.scannedWithFinding:
        return Colors.red;
      case ScanStatus.notScanned:
      default:
        return const Color(0xFFC8E6C9);
    }
  }

  Color _getTextColorForStatus(ScanStatus status) {
    return status == ScanStatus.notScanned ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckpointProvider>(
      builder: (context, checkpointProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFE8F5E9),
          appBar: AppBar(
            title: Text('Daftar Check Point', style: Theme.of(context).appBarTheme.titleTextStyle),
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: checkpointProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : checkpointProvider.errorMessage.isNotEmpty
                  ? Center(child: Text('Error: ${checkpointProvider.errorMessage}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5,
                      ),
                      itemCount: checkpointProvider.titikList.length,
                      itemBuilder: (context, index) {
                        final titik = checkpointProvider.titikList[index];
                        return Card(
                          clipBehavior: Clip.antiAlias, // Penting agar stack tidak keluar dari border
                          elevation: 4,
                          color: _getColorForStatus(titik.status),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: titik.status == ScanStatus.notScanned ? Theme.of(context).primaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Stack( // Gunakan Stack untuk menumpuk widget
                            children: [
                              // Konten utama (ikon dan teks)
                              InkWell(
                                onTap: () async {
                                  final waktuMulai = DateTime.now();
                                  final authProvider = context.read<AuthProvider>();
                                  if (authProvider.user == null || authProvider.shift == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi tidak valid. Silakan login ulang.')));
                                    return;
                                  }
                                  
                                  final args = CheckpointArgs(
                                    titik: titik,
                                    user: authProvider.user!,
                                    shift: authProvider.shift!,
                                    compressedSelfieData: _compressedSelfieData,
                                    waktuMulai: waktuMulai,
                                  );
                                  
                                  final result = await Navigator.push<ScanStatus>(
                                    context,
                                    MaterialPageRoute(builder: (context) => ScannerPage(args: args)),
                                  );

                                  if (result != null) {
                                    checkpointProvider.updateTitikStatus(titik.id, result);
                                  }
                                },
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 40, color: _getTextColorForStatus(titik.status)),
                                        const SizedBox(height: 8),
                                        Text(
                                          titik.nama,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: _getTextColorForStatus(titik.status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Widget untuk nomor
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(titik.nomorUrut.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
