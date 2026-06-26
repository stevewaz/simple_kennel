import 'dart:math';

String _pbId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  return List.generate(15, (_) => chars[rng.nextInt(chars.length)]).join();
}

class Service {
  String id;
  String name;
  String description;
  double defaultPrice;
  String unit;
  bool isActive;

  Service({
    String? id,
    this.name = '',
    this.description = '',
    this.defaultPrice = 0,
    this.unit = 'flat fee',
    this.isActive = true,
  }) : id = id ?? _pbId();

  String get priceDisplay => '\$${defaultPrice.toStringAsFixed(2)} / $unit';
  String get catalogDisplay => '$name  (\$${defaultPrice.toStringAsFixed(2)} / $unit)';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'defaultPrice': defaultPrice,
        'unit': unit,
        'isActive': isActive ? 1 : 0,
      };

  factory Service.fromMap(Map<String, dynamic> m) => Service(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        defaultPrice: (m['defaultPrice'] as num?)?.toDouble() ?? 0,
        unit: m['unit'] as String? ?? 'flat fee',
        isActive: (m['isActive'] as int? ?? 1) == 1,
      );
}
