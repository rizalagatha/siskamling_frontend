// lib/pages/apar_report_page.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AparReportPage extends StatefulWidget {
  // Tidak perlu lagi menerima selfieData
  const AparReportPage({super.key});

  @override
  State<AparReportPage> createState() => _AparReportPageState();
}

class _AparReportPageState extends State<AparReportPage> {
  final _formKey = GlobalKey<FormState>();
  bool _sudahDibalik = false;
  bool _adaTemuan = false;
  final _catatanController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_sudahDibalik) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastikan Anda sudah membolak-balikkan APAR.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Panggil fungsi API baru yang mengirim JSON
      await ApiService.submitLaporanAparMingguan(
        context: context, // Kirim context untuk ambil data auth
        sudahDibalik: _sudahDibalik,
        adaTemuan: _adaTemuan,
        catatan: _catatanController.text,
      );

      if (mounted) {
        Navigator.pop(context, true); // Kirim 'true' (sukses)
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Cek APAR')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Form Laporan Mingguan APAR',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: const Text('Saya sudah membolak-balikkan APAR'),
                      value: _sudahDibalik,
                      onChanged: (val) => setState(() => _sudahDibalik = val!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Apakah ada temuan?'),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Tidak Ada'),
                            value: false,
                            groupValue: _adaTemuan,
                            onChanged: (val) => setState(() => _adaTemuan = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Ada'),
                            value: true,
                            groupValue: _adaTemuan,
                            onChanged: (val) => setState(() => _adaTemuan = val!),
                          ),
                        ),
                      ],
                    ),
                    if (_adaTemuan)
                      TextFormField(
                        controller: _catatanController,
                        decoration: const InputDecoration(labelText: 'Catatan Temuan'),
                        maxLines: 3,
                      ),
                    
                    // Tombol foto bukti sudah dihapus

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitLaporan,
                      child: const Text('SIMPAN LAPORAN'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}