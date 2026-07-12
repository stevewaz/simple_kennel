import 'dart:math';

String _pbId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  return List.generate(15, (_) => chars[rng.nextInt(chars.length)]).join();
}

class Booking {
  String id;
  String customerId;
  String customerName;
  int day;
  int month;
  int year;
  int endDay;
  int runIndex;
  String runName;
  String notes;
  String status; // Scheduled | CheckedIn
  String checkInTime; // AM | PM

  Booking({
    String id = '',
    this.customerId = '',
    this.customerName = '',
    required this.day,
    required this.month,
    required this.year,
    required this.endDay,
    required this.runIndex,
    this.runName = '',
    this.notes = '',
    this.status = 'Scheduled',
    this.checkInTime = 'AM',
  }) : id = id.isEmpty ? _pbId() : id;

  DateTime get checkInDate => DateTime(year, month, day);
  DateTime get checkOutDate => DateTime(year, month, endDay);

  static String generateKey(int year, int month, int day, int run) =>
      '$year-$month-$day-$run';

  String getKey() => generateKey(year, month, day, runIndex);

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'customerName': customerName,
        'day': day,
        'month': month,
        'year': year,
        'endDay': endDay,
        'KennelIndex': runIndex,
        'KennelName': runName,
        'notes': notes,
        'status': status,
        'check_in_time': checkInTime,
      };

  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
        id: m['id'] as String,
        customerId: m['customer_id'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        day: m['day'] as int? ?? 1,
        month: m['month'] as int? ?? 1,
        year: m['year'] as int? ?? DateTime.now().year,
        endDay: m['endDay'] as int? ?? 1,
        runIndex: m['KennelIndex'] as int? ?? 0,
        runName: m['KennelName'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
        status: m['status'] as String? ?? 'Scheduled',
        checkInTime: m['check_in_time'] as String? ?? 'AM',
      );

  Booking copyWith({String? status, String? notes, String? checkInTime}) =>
      Booking(
        id: id,
        customerId: customerId,
        customerName: customerName,
        day: day,
        month: month,
        year: year,
        endDay: endDay,
        runIndex: runIndex,
        runName: runName,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        checkInTime: checkInTime ?? this.checkInTime,
      );
}
