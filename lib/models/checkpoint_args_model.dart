// lib/models/checkpoint_args_model.dart

import 'dart:typed_data'; // <-- Pastikan import ini ada
import 'titik_model.dart';
import 'user_model.dart';
import 'shift_model.dart';

class CheckpointArgs {
  final Titik titik;
  final User user;
  final Shift shift;
  final DateTime waktuMulai;
  final Uint8List? compressedSelfieData; // <-- Ganti dari String ke Uint8List

  CheckpointArgs({
    required this.titik,
    required this.user,
    required this.shift,
    required this.waktuMulai,
    this.compressedSelfieData, // <-- Perbarui tipe data
  });
}
