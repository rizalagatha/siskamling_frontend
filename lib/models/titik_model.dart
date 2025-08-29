// lib/models/titik_model.dart

// Enum untuk merepresentasikan status scan sebuah titik checkpoint.
enum ScanStatus {
  notScanned, // Belum di-scan
  scannedOK, // Sudah di-scan, tidak ada temuan
  scannedWithFinding // Sudah di-scan, ada temuan
}

class Titik {
  final int id;
  final String nama;
  final int nomorUrut;
  final double latitude;
  final double longitude;
  final int idCabang; // kalau API belum kasih, fallback 0
  ScanStatus status;

  Titik({
    required this.id,
    required this.nama,
    required this.nomorUrut,
    required this.latitude,
    required this.longitude,
    this.idCabang = 0,
    this.status = ScanStatus.notScanned,
  });

  factory Titik.fromJson(Map<String, dynamic> json) {
    return Titik(
      id: int.tryParse(json['id_titik']?.toString() ?? '') ?? 0,
      nama: json['nama_titik']?.toString() ?? '',
      nomorUrut: int.tryParse(json['nomor_urut']?.toString() ?? '') ?? 0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      idCabang: int.tryParse(json['id_cabang']?.toString() ?? '') ?? 0,
    );
  }
}
