// lib/providers/apar_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart'; // Import service notifikasi

enum AparCheckStatus { loading, perluCek, sudahCek, error }

class AparProvider extends ChangeNotifier {
  AparCheckStatus _status = AparCheckStatus.loading;
  String _errorMessage = '';

  AparCheckStatus get status => _status;
  String get errorMessage => _errorMessage;

  /// Fungsi baru untuk mengambil status laporan mingguan.
  Future<void> fetchAparStatus(int idUser) async {
    _status = AparCheckStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final statusString = await ApiService.fetchAparStatusMingguan(idUser);
      
      if (statusString == 'Perlu Cek') {
        _status = AparCheckStatus.perluCek;
        // Panggil notifikasi jika statusnya 'Perlu Cek'
        NotificationService().showNotification(
          id: 1,
          title: 'Pengingat Cek APAR',
          body: 'Anda belum melakukan pengecekan APAR minggu ini.',
        );
      } else {
        _status = AparCheckStatus.sudahCek;
      }

    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AparCheckStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Fungsi untuk memperbarui status di UI secara manual setelah submit berhasil.
  void updateStatusSelesai() {
    _status = AparCheckStatus.sudahCek;
    notifyListeners();
  }
}