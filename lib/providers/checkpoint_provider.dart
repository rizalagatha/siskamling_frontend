// lib/providers/checkpoint_provider.dart

import 'package:flutter/material.dart';
import '../models/titik_model.dart';
import '../services/api_service.dart';

class CheckpointProvider extends ChangeNotifier {
  List<Titik> _titikList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Titik> get titikList => _titikList;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fungsi untuk mengambil data titik dari API
  Future<void> fetchTitik(int idCabang) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _titikList = await ApiService.fetchTitikPatroli(idCabang);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk memperbarui status titik
  void updateTitikStatus(int titikId, ScanStatus status) {
    final index = _titikList.indexWhere((titik) => titik.id == titikId);
    if (index != -1) {
      _titikList[index].status = status;
      notifyListeners();
    }
  }
}
