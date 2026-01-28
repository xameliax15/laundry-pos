class Customer {
  final String id;
  final String name;
  final String phone;
  final String? alamat;
  final String? kelurahan;
  final String? kecamatan;
  final String? kota;
  final String? kodePos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.alamat,
    this.kelurahan,
    this.kecamatan,
    this.kota,
    this.kodePos,
    this.createdAt,
    this.updatedAt,
  });

  // Get full address
  String get fullAddress {
    final parts = <String>[];
    if (alamat != null && alamat!.isNotEmpty) parts.add(alamat!);
    if (kelurahan != null && kelurahan!.isNotEmpty) parts.add('Kel. $kelurahan');
    if (kecamatan != null && kecamatan!.isNotEmpty) parts.add('Kec. $kecamatan');
    if (kota != null && kota!.isNotEmpty) parts.add(kota!);
    if (kodePos != null && kodePos!.isNotEmpty) parts.add(kodePos!);
    return parts.join(', ');
  }

  // Convert from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      alamat: json['alamat'] as String?,
      kelurahan: json['kelurahan'] as String?,
      kecamatan: json['kecamatan'] as String?,
      kota: json['kota'] as String?,
      kodePos: json['kode_pos'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'alamat': alamat,
      'kelurahan': kelurahan,
      'kecamatan': kecamatan,
      'kota': kota,
      'kode_pos': kodePos,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}




