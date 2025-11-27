// lib/pages/admin/laporan_apar_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class LaporanAparPage extends StatefulWidget {
  const LaporanAparPage({super.key});

  @override
  State<LaporanAparPage> createState() => _LaporanAparPageState();
}

class _LaporanAparPageState extends State<LaporanAparPage> {
  List<dynamic> _laporanApar = [];
  List<dynamic> _cabangList = [];
  bool _isLoading = false;

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
      final data = await ApiService.fetchLaporanApar(
        idCabang: _selectedCabangId,
        tanggal: tanggalFormatted,
      );
      setState(() {
        _laporanApar = data;
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
          Text('Laporan Cek APAR Mingguan',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Waktu Lapor')),
                DataColumn(label: Text('Petugas')),
                DataColumn(label: Text('Cabang')),
                DataColumn(label: Text('Dibalik')),
                DataColumn(label: Text('Temuan')),
              ],
              rows: _laporanApar.map((laporan) {
                final bool sudahDibalik = laporan['sudah_dibalik'] == 1;
                final bool adaTemuan = laporan['ada_temuan'] == 1;
                return DataRow(
                  cells: [
                    DataCell(Text(_formatDateTime(
                        laporan['waktu_lapor']))), // <-- Gunakan format
                    DataCell(Text(laporan['petugas'] ?? '-')),
                    DataCell(Text(laporan['cabang'] ?? '-')),
                    DataCell(
                      Icon(
                        sudahDibalik ? Icons.check_circle : Icons.cancel,
                        color: sudahDibalik ? Colors.green : Colors.grey,
                      ),
                    ),
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
      itemCount: _laporanApar.length,
      itemBuilder: (context, index) {
        final laporan = _laporanApar[index];
        final bool sudahDibalik = laporan['sudah_dibalik'] == 1;
        final bool adaTemuan = laporan['ada_temuan'] == 1;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text('Laporan oleh: ${laporan['petugas'] ?? '-'}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cabang: ${laporan['cabang'] ?? '-'}'),
                Text(
                    'Waktu: ${_formatDateTime(laporan['waktu_lapor'])}'), // <-- Gunakan format
                Text('Catatan: ${laporan['catatan'] ?? 'Tidak ada catatan'}'),
              ],
            ),
            trailing: Icon(
              adaTemuan ? Icons.warning : Icons.check_circle,
              color: adaTemuan ? Colors.red : Colors.green,
            ),
          ),
        );
      },
    );
  }
}
