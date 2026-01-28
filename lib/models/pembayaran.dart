class Pembayaran {
  final String id;
  final String transaksiId;
  final double jumlah;
  final DateTime tanggalBayar;
  final String metodePembayaran; // cash, transfer, qris
  final String status; // pending, lunas, belum_lunas
  final String? buktiPembayaran;

  Pembayaran({
    required this.id,
    required this.transaksiId,
    required this.jumlah,
    required this.tanggalBayar,
    required this.metodePembayaran,
    required this.status,
    this.buktiPembayaran,
  });

  // Convert from JSON
  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'] as String,
      transaksiId: json['transaksi_id'] as String,
      jumlah: (json['jumlah'] as num).toDouble(),
      tanggalBayar: DateTime.parse(json['tanggal_bayar'] as String),
      metodePembayaran: json['metode_pembayaran'] as String,
      status: json['status'] as String,
      buktiPembayaran: json['bukti_pembayaran'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaksi_id': transaksiId,
      'jumlah': jumlah,
      'tanggal_bayar': tanggalBayar.toIso8601String(),
      'metode_pembayaran': metodePembayaran,
      'status': status,
      'bukti_pembayaran': buktiPembayaran,
    };
  }
}




