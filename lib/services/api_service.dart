// lib/services/api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/titik_model.dart';
import '../models/user_model.dart';
import '../models/shift_model.dart';

/// Kelas ini mengelola semua panggilan jaringan (API calls) ke server backend.
/// Dengan memusatkan semua logika API di sini, kode menjadi lebih rapi dan mudah dikelola.
class ApiService {
  /// Mengirim data login ke API dan mengembalikan objek User jika berhasil.
  /// Melemparkan Exception jika login gagal atau terjadi error.
  static Future<User> loginUser(String username, String password) async {
    final url = Uri.parse('${Config.baseUrl}/user/login');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: json.encode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['status'] == 'success') {
      return User.fromJson(responseData['user']);
    } else {
      throw Exception(responseData['message'] ?? 'Login gagal');
    }
  }

  /// Mengambil daftar titik patroli dari API berdasarkan idCabang.
  static Future<List<Titik>> fetchTitikPatroli(int idCabang) async {
    final url = Uri.parse('${Config.baseUrl}/titik/$idCabang');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Titik.fromJson(data)).toList();
    } else {
      throw Exception('Gagal memuat data titik patroli');
    }
  }

  /// Membuat catatan absensi awal dengan meng-upload foto selfie.
  /// Mengembalikan ID absensi yang baru dibuat oleh database.
  static Future<void> submitAbsensi({
    required User user,
    required Shift shift,
    required Titik titik,
    Uint8List? compressedSelfieData,
    required bool adaTemuan,
    String? catatan,
    required DateTime waktuMulai,   // <-- Tambahan
    required DateTime waktuSelesai, // <-- Tambahan
  }) async {
    final url = Uri.parse('${Config.baseUrl}/absensi');
    var request = http.MultipartRequest('POST', url);

    // Menambahkan semua data teks (fields)
    request.fields['id_user'] = user.id.toString();
    request.fields['id_shift'] = shift.id.toString();
    request.fields['id_titik'] = titik.id.toString();
    request.fields['ada_temuan'] = adaTemuan.toString();
    if (catatan != null && catatan.isNotEmpty) {
      request.fields['catatan'] = catatan;
    }
    // Mengubah DateTime menjadi string format ISO 8601 (standar untuk API)
    request.fields['waktu_mulai'] = waktuMulai.toIso8601String();
    request.fields['waktu_selesai'] = waktuSelesai.toIso8601String();

    // Menambahkan file foto
    if (compressedSelfieData != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'selfie',
        compressedSelfieData,
        filename: 'selfie-${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
  }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final responseData = json.decode(response.body);

    if (response.statusCode != 201) {
      throw Exception(responseData['message'] ?? 'Gagal menyimpan absensi');
    }
  }

  /// Meng-update catatan absensi dengan hasil scan dan laporan temuan.
  // static Future<void> updateAbsensiReport({
  //   required int idAbsensi,
  //   required int idTitik,
  //   required bool adaTemuan,
  //   String? catatan,
  // }) async {
  //   // TODO: Pastikan endpoint PUT/PATCH ini sudah dibuat di backend Express Anda.
  //   final url = Uri.parse('${Config.baseUrl}/absensi/update');

  //   final response = await http.put(
  //     url,
  //     headers: {'Content-Type': 'application/json; charset=UTF-8'},
  //     body: json.encode({
  //       'id_absensi': idAbsensi,
  //       'id_titik': idTitik,
  //       'ada_temuan': adaTemuan,
  //       'catatan': catatan,
  //     }),
  //   ).timeout(const Duration(seconds: 15));

  //   if (response.statusCode != 200) {
  //     final responseData = json.decode(response.body);
  //     throw Exception(responseData['message'] ?? 'Gagal memperbarui laporan absensi');
  //   }
  // }
  static Future<List<Shift>> fetchShifts() async {
    final url = Uri.parse('${Config.baseUrl}/shift');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Shift.fromJson(data)).toList();
    } else {
      throw Exception('Gagal memuat data shift');
    }
  }
}
