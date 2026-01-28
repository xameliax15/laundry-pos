class User {
  final String id;
  final String username;
  final String email;
  final String role; // owner, kasir, kurir
  final String? phone;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.phone,
  });

  // Convert from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }
}




