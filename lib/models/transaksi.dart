class Transaksi {
  final String id;
  final String? customerId; // Relasi ke tabel customer
  final String customerName;
  final String customerPhone;
  final DateTime tanggalMasuk;
  final DateTime? tanggalSelesai;
  final String status; // pending, proses, selesai, dikirim, diterima
  final double totalHarga;
  final String? catatan;
  final bool isDelivery; // Apakah pesanan akan di-delivery

  Transaksi({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.tanggalMasuk,
    this.tanggalSelesai,
    required this.status,
    required this.totalHarga,
    this.catatan,
    this.isDelivery = false,
  });

  // Convert from JSON
  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      id: json['id'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      tanggalMasuk: DateTime.parse(json['tanggal_masuk'] as String),
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.parse(json['tanggal_selesai'] as String)
          : null,
      status: json['status'] as String,
      totalHarga: (json['total_harga'] as num).toDouble(),
      catatan: json['catatan'] as String?,
      isDelivery: (json['is_delivery'] as int? ?? 0) == 1,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'tanggal_masuk': tanggalMasuk.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'status': status,
      'total_harga': totalHarga,
      'catatan': catatan,
      'is_delivery': isDelivery ? 1 : 0,
    };
  }
}

