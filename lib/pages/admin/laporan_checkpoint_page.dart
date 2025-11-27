// lib/pages/admin/laporan_checkpoint_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config.dart';

class LaporanCheckPointPage extends StatefulWidget {
  const LaporanCheckPointPage({super.key});

  @override
  State<LaporanCheckPointPage> createState() => _LaporanCheckPointPageState();
}

class _LaporanCheckPointPageState extends State<LaporanCheckPointPage> {
  List<dynamic> _laporan = [];
  List<dynamic> _cabangList = [];
  bool _isLoading = false;

  // State untuk filter
  String? _selectedCabangId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchDataAwal();
  }

  Future<void> _fetchDataAwal() async {
    await _fetchCabang();
    await _fetchLaporan();
  }

  Future<void> _fetchCabang() async {
    try {
      final data = await ApiService.fetchCabangList();
      setState(() {
        _cabangList = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat cabang: ${e.toString()}')));
    }
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tanggalFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await ApiService.fetchLaporanCheckpoint(
        idCabang: _selectedCabangId,
        tanggal: tanggalFormatted,
      );
      setState(() {
        _laporan = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat laporan: ${e.toString()}')));
    }
  }

  // --- Fungsi helper untuk format & detail ---
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('dd MMM, HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchLaporan();
    }
  }

  void _showDetailDialog(dynamic laporan) {
    showDialog(
      context: context,
      builder: (context) {
        final bool adaTemuan = laporan['ada_temuan'] == 1;

        return AlertDialog(
          title: Text('Detail: ${laporan['titik']}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Petugas: ${laporan['petugas']}'),
                // --- GUNAKAN FUNGSI FORMAT TANGGAL ---
                Text('Waktu Mulai: ${_formatDateTime(laporan['waktu_mulai'])}'),
                Text(
                    'Waktu Selesai: ${_formatDateTime(laporan['waktu_selesai'])}'),
                Text('Status: ${adaTemuan ? 'Ada Temuan' : 'Aman'}'),
                if (adaTemuan) Text('Catatan: ${laporan['catatan']}'),
                const SizedBox(height: 16),
                // --- TAMPILKAN FOTO SELFIE ---
                if (laporan['foto_selfie'] != null &&
                    (laporan['foto_selfie'] as String).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto Selfie:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Image.network(
                        // Hapus "/selfies" dari path URL
                        '${Config.baseUrl.replaceAll("/api", "")}/uploads/${laporan['foto_selfie']}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('Gagal memuat gambar.');
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Tutup'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- UI FILTER ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCabangId,
                    hint: const Text('Semua Cabang'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCabangId = newValue;
                      });
                      _fetchLaporan();
                    },
                    items: _cabangList.map<DropdownMenuItem<String>>((cabang) {
                      return DropdownMenuItem<String>(
                        value: cabang['id_cabang'].toString(),
                        child: Text(cabang['nama_cabang']),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ),
              ],
            ),
          ),
          // --- KONTEN UTAMA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return _buildMobileView();
                      }
                      return _buildDesktopView();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Tampilan untuk Desktop (DataTable)
  Widget _buildDesktopView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Laporan Check Point',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Waktu Mulai')),
                DataColumn(label: Text('Petugas')),
                DataColumn(label: Text('Titik')),
                DataColumn(label: Text('Status')),
              ],
              rows: _laporan.map((laporan) {
                final bool adaTemuan = laporan['ada_temuan'] == 1;
                return DataRow(
                  onSelectChanged: (selected) {
                    if (selected == true) _showDetailDialog(laporan);
                  },
                  cells: [
                    DataCell(Text(_formatDateTime(
                        laporan['waktu_mulai']))), // <-- Gunakan format
                    DataCell(Text(laporan['petugas'] ?? '-')),
                    DataCell(Text(laporan['titik'] ?? '-')),
                    DataCell(
                      Text(
                        adaTemuan ? 'Ada Temuan' : 'Aman',
                        style: TextStyle(
                          color: adaTemuan ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan untuk Mobile (ListView)
  Widget _buildMobileView() {
    return ListView.builder(
      itemCount: _laporan.length,
      itemBuilder: (context, index) {
        final laporan = _laporan[index];
        final bool adaTemuan = laporan['ada_temuan'] == 1;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(laporan['titik'] ?? 'Tanpa Nama Titik',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Petugas: ${laporan['petugas'] ?? '-'}'),
                Text(
                    'Waktu: ${_formatDateTime(laporan['waktu_mulai'])}'), // <-- Gunakan format
              ],
            ),
            trailing: Icon(
              adaTemuan ? Icons.warning : Icons.check_circle,
              color: adaTemuan ? Colors.red : Colors.green,
            ),
            onTap: () => _showDetailDialog(laporan),
          ),
        );
      },
    );
  }
}
