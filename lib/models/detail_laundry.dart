class DetailLaundry {
  final String id;
  final String idTransaksi;
  final String jenisLayanan; // laundry_kiloan, sepatu, jaket, helm, tas, boneka, karpet
  final String jenisBarang; // baju, celana, jaket, dll atau opsi layanan
  final int jumlah;
  final String? ukuran; // kecil, sedang, besar, jumbo, carrier (untuk tas/boneka)
  final double? berat; // untuk laundry kiloan (kg)
  final double? luas; // untuk karpet (m²)
  final String? catatan; // misal: noda, rusak
  final String? foto; // path atau URL foto

  DetailLaundry({
    required this.id,
    required this.idTransaksi,
    required this.jenisLayanan,
    required this.jenisBarang,
    required this.jumlah,
    this.ukuran,
    this.berat,
    this.luas,
    this.catatan,
    this.foto,
  });

  // Convert from JSON
  factory DetailLaundry.fromJson(Map<String, dynamic> json) {
    return DetailLaundry(
      id: json['id'] as String,
      idTransaksi: json['id_transaksi'] as String,
      jenisLayanan: json['jenis_layanan'] as String,
      jenisBarang: json['jenis_barang'] as String,
      jumlah: json['jumlah'] as int,
      ukuran: json['ukuran'] as String?,
      berat: json['berat'] != null ? (json['berat'] as num).toDouble() : null,
      luas: json['luas'] != null ? (json['luas'] as num).toDouble() : null,
      catatan: json['catatan'] as String?,
      foto: json['foto'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_transaksi': idTransaksi,
      'jenis_layanan': jenisLayanan,
      'jenis_barang': jenisBarang,
      'jumlah': jumlah,
      'ukuran': ukuran,
      'berat': berat,
      'luas': luas,
      'catatan': catatan,
      'foto': foto,
    };
  }
}

