class OrderKurir {
  final String id;
  final String transaksiId;
  final String kurirId; // ID user dengan role kurir
  final String? alamatPengiriman;
  final bool isCOD;
  final String status; // assigned, on_delivery, delivered, completed
  final DateTime? tanggalAssign;
  final DateTime? tanggalSelesai;
  final String? catatan;

  OrderKurir({
    required this.id,
    required this.transaksiId,
    required this.kurirId,
    this.alamatPengiriman,
    this.isCOD = false,
    required this.status,
    this.tanggalAssign,
    this.tanggalSelesai,
    this.catatan,
  });

  // Convert from JSON
  factory OrderKurir.fromJson(Map<String, dynamic> json) {
    return OrderKurir(
      id: json['id'] as String,
      transaksiId: json['transaksi_id'] as String,
      kurirId: json['kurir_id'] as String,
      alamatPengiriman: json['alamat_pengiriman'] as String?,
      isCOD: json['is_cod'] == 1 || json['is_cod'] == true,
      status: json['status'] as String,
      tanggalAssign: json['tanggal_assign'] != null
          ? DateTime.parse(json['tanggal_assign'] as String)
          : null,
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.parse(json['tanggal_selesai'] as String)
          : null,
      catatan: json['catatan'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaksi_id': transaksiId,
      'kurir_id': kurirId,
      'alamat_pengiriman': alamatPengiriman,
      'is_cod': isCOD ? 1 : 0,
      'status': status,
      'tanggal_assign': tanggalAssign?.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'catatan': catatan,
    };
  }
}




