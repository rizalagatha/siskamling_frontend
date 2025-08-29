// lib/models/shift_model.dart

class Shift {
  final int id;
  final String nama;
  final String jamMulai;
  final String jamSelesai;

  Shift({
    required this.id,
    required this.nama,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id_shift'],
      nama: json['nama_shift'],
      jamMulai: json['waktu_mulai'],
      jamSelesai: json['waktu_selesai'],
    );
  }
}
