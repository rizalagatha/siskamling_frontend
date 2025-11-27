// lib/pages/riwayat_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late Future<List<dynamic>> _futureRiwayat;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _futureRiwayat = ApiService.fetchLaporanSaya(user.id);
    } else {
      _futureRiwayat = Future.value([]); // Inisialisasi kosong jika user null
    }
  }

  // Helper format tanggal
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('HH:mm')
          .format(dateTime); // Hanya tampilkan jam dan menit
    } catch (e) {
      return dateTimeString;
    }
  }

  // Helper untuk ikon
  IconData _getIconForTipe(String tipe, bool adaTemuan) {
    if (tipe == 'apar') {
      return adaTemuan
          ? Icons.fire_extinguisher_outlined
          : Icons.fire_extinguisher;
    }
    // Default (checkpoint)
    return adaTemuan ? Icons.warning_amber_rounded : Icons.check_circle_outline;
  }

  Color _getColorForTipe(String tipe, bool adaTemuan) {
    if (adaTemuan) return Colors.red;
    if (tipe == 'apar') return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Patroli Hari Ini'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Belum ada riwayat patroli hari ini.'));
          }

          final riwayatList = snapshot.data!;
          return ListView.builder(
            itemCount: riwayatList.length,
            itemBuilder: (context, index) {
              final item = riwayatList[index];
              final bool adaTemuan = item['ada_temuan'] == 1;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    _getIconForTipe(item['tipe'], adaTemuan),
                    color: _getColorForTipe(item['tipe'], adaTemuan),
                    size: 40,
                  ),
                  title: Text(
                    item['nama_laporan'] ?? 'Laporan',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    adaTemuan
                        ? ('Catatan: ' +
                            (item['catatan'] ?? 'Tidak ada catatan'))
                        : 'Dilaporkan Aman',
                  ),
                  trailing: Text(
                    _formatDateTime(item['waktu']),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
