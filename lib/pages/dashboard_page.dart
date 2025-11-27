// lib/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/apar_provider.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'apar_report_page.dart';
import 'riwayat_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<AparProvider>().fetchAparStatus(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan status dari AparProvider
    final aparProvider = context.watch<AparProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final shift = authProvider.shift;

    Color aparButtonColor;
    switch (aparProvider.status) {
      case AparCheckStatus.sudahCek:
        aparButtonColor = Colors.grey.shade400; // abu-abu = sudah dicek
        break;
      case AparCheckStatus.perluCek:
        aparButtonColor = Colors.redAccent.shade100; // merah muda = perlu dicek
        break;
      case AparCheckStatus.loading:
        aparButtonColor = Colors.amber.shade300; // kuning = loading
        break;
      default:
        aparButtonColor = Colors.grey.shade300; // default / error ringan
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32), // hijau pekat
        title: Text(
          'Siskamling Dashboard',
          style:
              Theme.of(context).appBarTheme.titleTextStyle, // dari theme global
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: const Color(0xFF2E7D32)
                .withOpacity(0.9), // strip hijau pekat transparan
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Petugas: ${user?.namaLengkap ?? 'Tidak Dikenal'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  'Shift: ${shift?.nama ?? ''} (${shift?.jamMulai ?? ''} - ${shift?.jamSelesai ?? ''})',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Hari Ini',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RiwayatPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuItem(
              context: context,
              ikon: Icons.qr_code_scanner,
              label: 'Check Point',
              // --- PERUBAHAN DI SINI ---
              // Menggunakan warna utama dari tema aplikasi
              warna: Theme.of(context).primaryColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              ikon: Icons.fire_extinguisher,
              label: 'Cek APAR',
              warna: aparProvider.status == AparCheckStatus.perluCek
                  ? Colors.redAccent // 🔴 warna merah saat belum dicek
                  : aparProvider.status == AparCheckStatus.sudahCek
                      ? Colors.grey.shade400 // abu-abu jika sudah dicek
                      : Theme.of(context).primaryColor, // hijau default
              onTap: () async {
                if (aparProvider.status == AparCheckStatus.sudahCek) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('APAR sudah dicek minggu ini.')),
                  );
                  return;
                }
                if (aparProvider.status != AparCheckStatus.perluCek) return;

                final laporanSukses = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AparReportPage()),
                );

                if (laporanSukses == true) {
                  aparProvider.updateStatusSelesai();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData ikon,
    required String label,
    required Color warna,
    required VoidCallback onTap,
    AparCheckStatus? aparStatus,
  }) {
    return Card(
      elevation: 4,
      color: warna,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: aparStatus == AparCheckStatus.perluCek
              ? Colors.redAccent
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 50, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
