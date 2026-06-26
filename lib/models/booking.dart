import 'dart:math';

String _pbId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  return List.generate(15, (_) => chars[rng.nextInt(chars.length)]).join();
}

class Booking {
  String id;
  String customerName;
  int day;
  int month;
  int year;
  int endDay;
  int runIndex;
  String runName;
  String notes;
  String status; // Scheduled | CheckedIn

  Booking({
    String? id,
    this.customerName = '',
    required this.day,
    required this.month,
    required this.year,
    required this.endDay,
    required this.runIndex,
    this.runName = '',
    this.notes = '',
    this.status = 'Scheduled',
  }) : id = id ?? _pbId();

  DateTime get checkInDate => DateTime(year, month, day);
  DateTime get checkOutDate => DateTime(year, month, endDay);

  static String generateKey(int year, int month, int day, int run) =>
      '$year-$month-$day-$run';

  String getKey() => generateKey(year, month, day, runIndex);

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'day': day,
        'month': month,
        'year': year,
        'endDay': endDay,
        'KennelIndex': runIndex,
        'KennelName': runName,
        'notes': notes,
        'status': status,
      };

  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
        id: m['id'] as String,
        customerName: m['customerName'] as String? ?? '',
        day: m['day'] as int? ?? 1,
        month: m['month'] as int? ?? 1,
        year: m['year'] as int? ?? DateTime.now().year,
        endDay: m['endDay'] as int? ?? 1,
        runIndex: m['KennelIndex'] as int? ?? 0,
        runName: m['KennelName'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
        status: m['status'] as String? ?? 'Scheduled',
      );

  Booking copyWith({String? status, String? notes}) => Booking(
        id: id,
        customerName: customerName,
        day: day,
        month: month,
        year: year,
        endDay: endDay,
        runIndex: runIndex,
        runName: runName,
        notes: notes ?? this.notes,
        status: status ?? this.status,
      );
}
