// Native-only Isar collection schemas. Kept separate from the shared
// models in lib/models/ because Isar's generated schema code embeds
// 64-bit fingerprint constants that dart2js cannot represent — putting
// @collection directly on the shared models breaks the web build even
// though IsarStore itself is never imported there. These entities exist
// solely to be converted to/from the plain models inside local_store_isar.dart.
import 'package:isar/isar.dart';
import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import '../utils/fast_hash.dart';

part 'isar_entities.g.dart';

@collection
class CustomerEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  String id;
  String name;
  String email;
  String phoneNumber;
  String address;
  DateTime createdAt;

  CustomerEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.createdAt,
  });

  factory CustomerEntity.from(Customer c) => CustomerEntity(
        id: c.id,
        name: c.name,
        email: c.email,
        phoneNumber: c.phoneNumber,
        address: c.address,
        createdAt: c.createdAt,
      );

  Customer toModel() => Customer(
        id: id,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        createdAt: createdAt,
      );
}

@collection
class PetEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  String id;
  @Index()
  String customerId;
  String name;
  String species;
  String breed;
  int age;
  String notes;
  DateTime createdAt;

  PetEntity({
    required this.id,
    required this.customerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.notes,
    required this.createdAt,
  });

  factory PetEntity.from(Pet p) => PetEntity(
        id: p.id,
        customerId: p.customerId,
        name: p.name,
        species: p.species,
        breed: p.breed,
        age: p.age,
        notes: p.notes,
        createdAt: p.createdAt,
      );

  Pet toModel() => Pet(
        id: id,
        customerId: customerId,
        name: name,
        species: species,
        breed: breed,
        age: age,
        notes: notes,
        createdAt: createdAt,
      );
}

@collection
class BookingEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
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
  String status;
  String checkInTime;

  BookingEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.day,
    required this.month,
    required this.year,
    required this.endDay,
    required this.runIndex,
    required this.runName,
    required this.notes,
    required this.status,
    required this.checkInTime,
  });

  factory BookingEntity.from(Booking b) => BookingEntity(
        id: b.id,
        customerId: b.customerId,
        customerName: b.customerName,
        day: b.day,
        month: b.month,
        year: b.year,
        endDay: b.endDay,
        runIndex: b.runIndex,
        runName: b.runName,
        notes: b.notes,
        status: b.status,
        checkInTime: b.checkInTime,
      );

  Booking toModel() => Booking(
        id: id,
        customerId: customerId,
        customerName: customerName,
        day: day,
        month: month,
        year: year,
        endDay: endDay,
        runIndex: runIndex,
        runName: runName,
        notes: notes,
        status: status,
        checkInTime: checkInTime,
      );
}

@collection
class InvoiceEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  String id;
  String customerId;
  String customerName;
  String invoiceNumber;
  @Index()
  String bookingId;
  DateTime issueDate;
  DateTime dueDate;
  String status;
  String notes;
  double subTotal;
  double taxRate;
  double taxAmount;
  double totalAmount;
  DateTime createdAt;

  InvoiceEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.invoiceNumber,
    required this.bookingId,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this.subTotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.createdAt,
  });

  factory InvoiceEntity.from(Invoice inv) => InvoiceEntity(
        id: inv.id,
        customerId: inv.customerId,
        customerName: inv.customerName,
        invoiceNumber: inv.invoiceNumber,
        bookingId: inv.bookingId,
        issueDate: inv.issueDate,
        dueDate: inv.dueDate,
        status: inv.status,
        notes: inv.notes,
        subTotal: inv.subTotal,
        taxRate: inv.taxRate,
        taxAmount: inv.taxAmount,
        totalAmount: inv.totalAmount,
        createdAt: inv.createdAt,
      );

  Invoice toModel() => Invoice(
        id: id,
        customerId: customerId,
        customerName: customerName,
        invoiceNumber: invoiceNumber,
        bookingId: bookingId,
        issueDate: issueDate,
        dueDate: dueDate,
        status: status,
        notes: notes,
        subTotal: subTotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        createdAt: createdAt,
      );
}

@collection
class InvoiceLineItemEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  String id;
  @Index()
  String invoiceId;
  String description;
  double quantity;
  double unitPrice;

  InvoiceLineItemEntity({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  factory InvoiceLineItemEntity.from(InvoiceLineItem i) => InvoiceLineItemEntity(
        id: i.id,
        invoiceId: i.invoiceId,
        description: i.description,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
      );

  InvoiceLineItem toModel() => InvoiceLineItem(
        id: id,
        invoiceId: invoiceId,
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
      );
}

@collection
class ServiceEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  String id;
  String name;
  String description;
  double defaultPrice;
  String unit;
  bool isActive;

  ServiceEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPrice,
    required this.unit,
    required this.isActive,
  });

  factory ServiceEntity.from(Service s) => ServiceEntity(
        id: s.id,
        name: s.name,
        description: s.description,
        defaultPrice: s.defaultPrice,
        unit: s.unit,
        isActive: s.isActive,
      );

  Service toModel() => Service(
        id: id,
        name: name,
        description: description,
        defaultPrice: defaultPrice,
        unit: unit,
        isActive: isActive,
      );
}
