// lib/services/api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // Diperlukan untuk context.read
import 'package:flutter/material.dart'; // Diperlukan untuk BuildContext

import '../config.dart';
import '../models/user_model.dart';
import '../models/shift_model.dart';
import '../models/titik_model.dart';
import '../providers/auth_provider.dart';

class ApiService {
  // --- FUNGSI LOGIN ---
  static Future<User> loginUser(String username, String password) async {
    final url = Uri.parse('${Config.baseUrl}/user/login');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return User.fromJson(responseData['user']);
      } else {
        throw Exception(responseData['message'] ?? 'Login gagal');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server. Periksa koneksi.');
    }
  }

  // --- FUNGSI SHIFT ---
  static Future<List<Shift>> fetchShifts() async {
    final url = Uri.parse('${Config.baseUrl}/shift');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Jika response langsung berupa array
        if (responseData is List) {
          return responseData
              .map<Shift>((data) => Shift.fromJson(data))
              .toList();
        }

        // Jika response berupa objek dengan 'data'
        if (responseData is Map && responseData['data'] != null) {
          List jsonList = responseData['data'];
          return jsonList.map<Shift>((data) => Shift.fromJson(data)).toList();
        }

        throw Exception('Format respons tidak dikenal');
      } else {
        throw Exception('Gagal memuat shift: kode ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  // --- FUNGSI CHECKPOINT ---
  static Future<List<Titik>> fetchTitikPatroli(int idCabang) async {
    final url = Uri.parse('${Config.baseUrl}/titik/$idCabang');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Jika response langsung berupa array
        if (responseData is List) {
          return responseData
              .map<Titik>((data) => Titik.fromJson(data))
              .toList();
        }
        // Jika response berupa objek dengan 'data'
        if (responseData is Map && responseData['data'] != null) {
          List jsonList = responseData['data'];
          return jsonList.map<Titik>((data) => Titik.fromJson(data)).toList();
        }
        throw Exception('Format respons titik tidak dikenal');
      } else {
        throw Exception('Gagal memuat data titik');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  // --- FUNGSI SUBMIT ABSENSI CHECKPOINT (tetap menggunakan multipart) ---
  static Future<void> submitAbsensi({
    required User user,
    required Shift shift,
    required Titik titik,
    required Uint8List compressedSelfieData,
    required bool adaTemuan,
    String? catatan,
    required DateTime waktuMulai,
    required DateTime waktuSelesai,
  }) async {
    final url = Uri.parse('${Config.baseUrl}/absensi');
    try {
      var request = http.MultipartRequest('POST', url)
        ..fields['id_user'] = user.id.toString()
        ..fields['id_shift'] = shift.id.toString()
        ..fields['id_titik'] = titik.id.toString()
        ..fields['ada_temuan'] = adaTemuan.toString()
        ..fields['catatan'] = catatan ?? ''
        ..fields['waktu_mulai'] = waktuMulai.toIso8601String()
        ..fields['waktu_selesai'] = waktuSelesai.toIso8601String()
        ..files.add(http.MultipartFile.fromBytes(
          'selfie',
          compressedSelfieData,
          filename:
              'selfie_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

      final response =
          await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 201) {
        throw Exception(
            json.decode(responseBody)['message'] ?? 'Gagal mengirim laporan');
      }
    } catch (e) {
      throw Exception('Upload Gagal: ${e.toString()}');
    }
  }

  // --- FUNGSI LAPORAN APAR ---

  /// Mengambil status laporan APAR mingguan.
  static Future<String> fetchAparStatusMingguan(int idUser) async {
    final url = Uri.parse('${Config.baseUrl}/laporan/status/$idUser');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return responseData[
            'data']; // Mengembalikan 'Perlu Cek' atau 'Sudah Cek'
      } else {
        throw Exception(responseData['message'] ?? 'Gagal memuat status APAR');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server.');
    }
  }

  /// Mengirim laporan APAR mingguan (JSON sederhana).
  static Future<void> submitLaporanAparMingguan({
    required BuildContext context,
    required bool sudahDibalik,
    required bool adaTemuan,
    String? catatan,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final shift = authProvider.shift;

    if (user == null || shift == null) {
      throw Exception("Sesi tidak valid. Silakan login ulang.");
    }

    final url = Uri.parse('${Config.baseUrl}/laporan/apar-mingguan');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id_user': user.id,
              'id_cabang': user.idCabang,
              'sudah_dibalik': sudahDibalik,
              'ada_temuan': adaTemuan,
              'catatan': catatan ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);
      if (response.statusCode != 201) {
        throw Exception(
            responseData['message'] ?? 'Gagal menyimpan laporan APAR');
      }
    } catch (e) {
      throw Exception('Gagal terhubung: ${e.toString()}');
    }
  }

  // --- FUNGSI BARU UNTUK ADMIN ---

  /// Mengambil laporan checkpoint (untuk admin).
  static Future<List<dynamic>> fetchLaporanCheckpoint(
      {String? tanggal, String? idCabang}) async {
    // Membangun query string
    Map<String, String> queryParams = {};
    if (tanggal != null) queryParams['tanggal'] = tanggal;
    if (idCabang != null) queryParams['cabang'] = idCabang;

    final url = Uri.parse('${Config.baseUrl}/laporan/checkpoint')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return responseData['data']; // Mengembalikan List<Map<String, dynamic>>
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal memuat laporan checkpoint');
      }
    } catch (e) {
      throw Exception('Gagal terhubung: ${e.toString()}');
    }
  }

  /// Mengambil laporan APAR (untuk admin).
  static Future<List<dynamic>> fetchLaporanApar(
      {String? tanggal, String? idCabang}) async {
    Map<String, String> queryParams = {};
    if (tanggal != null) queryParams['tanggal'] = tanggal;
    if (idCabang != null) queryParams['cabang'] = idCabang;

    final url = Uri.parse('${Config.baseUrl}/laporan/apar')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return responseData['data']; // Mengembalikan List<Map<String, dynamic>>
      } else {
        throw Exception(responseData['message'] ?? 'Gagal memuat laporan APAR');
      }
    } catch (e) {
      throw Exception('Gagal terhubung: ${e.toString()}');
    }
  }

  // --- FUNGSI BARU UNTUK RIWAYAT SAYA ---
  static Future<List<dynamic>> fetchLaporanSaya(int idUser) async {
    final url = Uri.parse('${Config.baseUrl}/laporan/saya/$idUser');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return responseData['data']; // Mengembalikan List<Map<String, dynamic>>
      } else {
        throw Exception(responseData['message'] ?? 'Gagal memuat riwayat');
      }
    } catch (e) {
      throw Exception('Gagal terhubung: ${e.toString()}');
    }
  }

  // --- FUNGSI BARU UNTUK MENGAMBIL DAFTAR CABANG (UNTUK FILTER) ---
  static Future<List<dynamic>> fetchCabangList() async {
    final url =
        Uri.parse('${Config.baseUrl}/cabang'); // Asumsi endpoint ini ada
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return responseData['data']; // Mengembalikan List<Map<String, dynamic>>
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal memuat daftar cabang');
      }
    } catch (e) {
      throw Exception('Gagal terhubung: ${e.toString()}');
    }
  }
}
