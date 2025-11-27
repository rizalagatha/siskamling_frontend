// lib/pages/admin/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_page.dart';
import 'laporan_checkpoint_page.dart';
import 'laporan_apar_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const LaporanCheckPointPage(),
    const LaporanAparPage(),
    const Center(child: Text('Segera Hadir: Manajemen User')),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    // Gunakan MediaQuery untuk mengecek lebar layar
    final screenWidth = MediaQuery.of(context).size.width;
    // Tentukan breakpoint, misalnya 600 piksel
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - ${user?.namaLengkap ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          )
        ],
      ),
      // Tampilkan BottomNavigationBar jika mobile
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  label: 'Check Point',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fire_extinguisher_outlined),
                  label: 'APAR',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Users',
                ),
              ],
            )
          : null, // Jangan tampilkan jika desktop
      body: Row(
        children: [
          // Tampilkan NavigationRail HANYA jika bukan mobile
          if (!isMobile)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.qr_code_scanner),
                  label: Text('Check Point'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.fire_extinguisher_outlined),
                  selectedIcon: Icon(Icons.fire_extinguisher),
                  label: Text('Laporan APAR'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Manajemen User'),
                ),
              ],
            ),

          if (!isMobile) const VerticalDivider(thickness: 1, width: 1),

          // Konten Halaman Utama
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
