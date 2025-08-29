// lib/providers/auth_provider.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/shift_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Shift? _shift;
  String? _selfieImagePath; // <-- simpan path foto

  User? get user => _user;
  Shift? get shift => _shift;
  String? get selfieImagePath => _selfieImagePath;

  void login(User user) {
    _user = user;
    notifyListeners();
  }

  void selectShift(Shift shift) {
    _shift = shift;
    notifyListeners();
  }

  // Simpan path foto selfie
  void setSelfie(String path) {
    _selfieImagePath = path;
    notifyListeners();
  }

  // Convert selfie ke bytes supaya bisa dikirim ke backend
  Future<Uint8List?> getSelfieBytes() async {
    if (_selfieImagePath == null) return null;
    try {
      final file = File(_selfieImagePath!);
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Gagal membaca file selfie: \$e');
      return null;
    }
  }

  void logout() {
    _user = null;
    _shift = null;
    _selfieImagePath = null;
    notifyListeners();
  }
}
