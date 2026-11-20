class LokasiBarcode {
  final int idTitik;
  final int idCabang;
  final String namaTitik;
  final int nomorUrut;
  final double latitude;
  final double longitude;

  LokasiBarcode({
    required this.idTitik,
    required this.idCabang,
    required this.namaTitik,
    required this.nomorUrut,
    required this.latitude,
    required this.longitude,
  });

  factory LokasiBarcode.fromJson(Map<String, dynamic> json) {
    return LokasiBarcode(
      idTitik: json['id_titik'] ?? 0,
      idCabang: json['id_cabang'] ?? 0,
      namaTitik: json['nama_titik'] ?? '',
      nomorUrut: json['nomor_urut'] ?? 0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
    );
  }
}
