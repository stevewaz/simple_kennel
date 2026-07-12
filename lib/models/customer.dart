import 'dart:math';

class Customer {
  String id;
  String name;
  String email;
  String phoneNumber;
  String address;
  DateTime createdAt;

  Customer({
    String id = '',
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.address = '',
    required this.createdAt,
  }) : id = id.isEmpty ? _uuid() : id;

  static String _uuid() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    return List.generate(15, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String get initials {
    if (name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        phoneNumber: m['phoneNumber'] as String? ?? '',
        address: m['address'] as String? ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Customer copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
  }) =>
      Customer(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        address: address ?? this.address,
        createdAt: createdAt,
      );
}
