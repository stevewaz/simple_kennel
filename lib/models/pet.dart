import 'dart:math';

String _pbId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  return List.generate(15, (_) => chars[rng.nextInt(chars.length)]).join();
}

class Pet {
  String id;
  String customerId;
  String name;
  String species;
  String breed;
  int age;
  String notes;
  DateTime createdAt;

  Pet({
    String? id,
    required this.customerId,
    this.name = '',
    this.species = 'Dog',
    this.breed = '',
    this.age = 0,
    this.notes = '',
    DateTime? createdAt,
  })  : id = id ?? _pbId(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  String get display =>
      breed.isEmpty ? '$name ($species)' : '$name ($breed)';

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'name': name,
        'species': species,
        'breed': breed,
        'age': age,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Pet.fromMap(Map<String, dynamic> m) => Pet(
        id: m['id'] as String,
        customerId: m['customerId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        species: m['species'] as String? ?? 'Dog',
        breed: m['breed'] as String? ?? '',
        age: m['age'] as int? ?? 0,
        notes: m['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
