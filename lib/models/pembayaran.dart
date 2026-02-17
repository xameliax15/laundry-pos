/// Model untuk data pembayaran transaksi laundry
class Pembayaran {
  final String id;
  final String transaksiId;
  final double jumlah;
  final DateTime tanggalBayar;
  final String metodePembayaran; // cash, transfer, qris
  final String status; // pending, lunas, belum_lunas, expired
  final String? buktiPembayaran;
  
  // QRIS Payment Gateway fields
  final String? qrisId;           // ID dari payment gateway
  final String? qrisString;       // QR code string untuk di-render
  final String? qrisUrl;          // URL gambar QR dari payment gateway
  final DateTime? qrisExpiredAt;  // Waktu expired QR code
  final String? paymentGateway;   // 'midtrans', 'xendit'
  final Map<String, dynamic>? gatewayResponse; // Response lengkap dari gateway

  Pembayaran({
    required this.id,
    required this.transaksiId,
    required this.jumlah,
    required this.tanggalBayar,
    required this.metodePembayaran,
    required this.status,
    this.buktiPembayaran,
    this.qrisId,
    this.qrisString,
    this.qrisUrl,
    this.qrisExpiredAt,
    this.paymentGateway,
    this.gatewayResponse,
  });

  /// Check if this is a QRIS payment
  bool get isQrisPayment => metodePembayaran == 'qris' && qrisId != null;
  
  /// Check if QRIS is expired
  bool get isQrisExpired {
    if (qrisExpiredAt == null) return false;
    return DateTime.now().isAfter(qrisExpiredAt!);
  }
  
  /// Get remaining time until QRIS expires
  Duration? get qrisRemainingTime {
    if (qrisExpiredAt == null) return null;
    final remaining = qrisExpiredAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

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
      qrisId: json['qris_id'] as String?,
      qrisString: json['qris_string'] as String?,
      qrisUrl: json['qris_url'] as String?,
      qrisExpiredAt: json['qris_expired_at'] != null
          ? DateTime.parse(json['qris_expired_at'] as String)
          : null,
      paymentGateway: json['payment_gateway'] as String?,
      gatewayResponse: json['gateway_response'] as Map<String, dynamic>?,
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
      'qris_id': qrisId,
      'qris_string': qrisString,
      'qris_url': qrisUrl,
      'qris_expired_at': qrisExpiredAt?.toIso8601String(),
      'payment_gateway': paymentGateway,
      'gateway_response': gatewayResponse,
    };
  }

  /// Create a copy with updated fields
  Pembayaran copyWith({
    String? id,
    String? transaksiId,
    double? jumlah,
    DateTime? tanggalBayar,
    String? metodePembayaran,
    String? status,
    String? buktiPembayaran,
    String? qrisId,
    String? qrisString,
    String? qrisUrl,
    DateTime? qrisExpiredAt,
    String? paymentGateway,
    Map<String, dynamic>? gatewayResponse,
  }) {
    return Pembayaran(
      id: id ?? this.id,
      transaksiId: transaksiId ?? this.transaksiId,
      jumlah: jumlah ?? this.jumlah,
      tanggalBayar: tanggalBayar ?? this.tanggalBayar,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      status: status ?? this.status,
      buktiPembayaran: buktiPembayaran ?? this.buktiPembayaran,
      qrisId: qrisId ?? this.qrisId,
      qrisString: qrisString ?? this.qrisString,
      qrisUrl: qrisUrl ?? this.qrisUrl,
      qrisExpiredAt: qrisExpiredAt ?? this.qrisExpiredAt,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
    );
  }
}
