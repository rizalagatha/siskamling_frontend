// lib/models/user_model.dart

/// Model ini merepresentasikan data user yang login.
/// Data ini didapat dari server API setelah proses otentikasi berhasil.
class User {
  final int id;
  final String username;
  final String namaLengkap;
  final int idCabang;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.namaLengkap,
    required this.idCabang,
    required this.role,
  });

  /// Factory constructor untuk membuat objek User dari data JSON.
  /// Pastikan backend Anda mengirimkan response JSON dengan key yang sesuai
  /// ('id', 'username', 'namaLengkap', 'idCabang').
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      namaLengkap: json['namaLengkap'] as String,
      idCabang: json['idCabang'] as int,
      role: json['role'] as String,
    );
  }
}
