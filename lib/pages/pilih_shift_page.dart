// lib/pages/pilih_shift_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'selfie_capture_page.dart';
import 'dashboard_page.dart';
import '../models/shift_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class PilihShiftPage extends StatefulWidget {
  // Constructor tidak lagi memerlukan parameter user
  const PilihShiftPage({super.key});

  @override
  State<PilihShiftPage> createState() => _PilihShiftPageState();
}

class _PilihShiftPageState extends State<PilihShiftPage> {
  late Future<List<Shift>> _futureShifts;

  @override
  void initState() {
    super.initState();
    _futureShifts = ApiService.fetchShifts();
  }

  IconData _getIconForShift(String namaShift) {
    switch (namaShift.toLowerCase()) {
      case 'pagi':
        return Icons.wb_sunny_outlined;
      case 'siang':
        return Icons.wb_twilight_outlined;
      case 'sore':
        return Icons.brightness_4_outlined;
      case 'malam':
        return Icons.nights_stay_outlined;
      default:
        return Icons.schedule;
    }
  }

  void _pilihShift(Shift shift) {
    // Simpan shift yang dipilih ke Provider
    context.read<AuthProvider>().selectShift(shift);
    
    // Navigasi ke Halaman Selfie, bukan Dashboard
    Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const SelfieCapturePage()),
  );
}

  @override
  Widget build(BuildContext context) {
    // Baca nama user dari Provider
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 🌿 hijau lembut
      appBar: AppBar(
        title: Text(
          'Pilih Shift Jaga',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary, // hijau pekat
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selamat Datang, ${user?.namaLengkap ?? 'Petugas'}!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan pilih shift jaga Anda untuk hari ini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: FutureBuilder<List<Shift>>(
                future: _futureShifts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Tidak ada shift yang tersedia.'));
                  }

                  final shifts = snapshot.data!;
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: shifts.length,
                    itemBuilder: (context, index) {
                      final shift = shifts[index];
                      return Card(
                        color: const Color(0xFF2E7D32), // hijau pekat
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => _pilihShift(shift),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_getIconForShift(shift.nama),
                                  size: 40, color: Colors.white),
                              const SizedBox(height: 12),
                              Text(
                                shift.nama,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shift.jamMulai} - ${shift.jamSelesai}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
