import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pocketbase_drift/pocketbase_drift.dart' hide Service;
import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';

class DatabaseService {
  final PocketBase _client;
  DatabaseService(this._client);

  Future<void> initialize() async {
    if (_client is $PocketBase) {
      try {
        await _client.collections.getFullList();
      } catch (_) {
        // Offline on first launch — schemas will be fetched when back online.
      }
    }
  }

  Future<void> _upsert(
      String col, String id, Map<String, dynamic> body) async {
    try {
      await _client.collection(col).update(id, body: body);
    } catch (_) {
      await _client.collection(col).create(body: {'id': id, ...body});
    }
  }

  // ── Customers ──────────────────────────────────────────────────────────────

  Customer _toCustomer(RecordModel r) => Customer(
        id: r.id,
        name: r.getStringValue('name'),
        email: r.getStringValue('email'),
        phoneNumber: r.getStringValue('phone_number'),
        address: r.getStringValue('address'),
        createdAt: DateTime.tryParse(r.get<String>('created')) ?? DateTime.now(),
      );

  Future<List<Customer>> getCustomers() async {
    final records = await _client.collection('customers').getFullList(
        sort: '+name');
    return records.map(_toCustomer).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    try {
      return _toCustomer(
          await _client.collection('customers').getOne(id));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCustomer(Customer c) => _upsert('customers', c.id, {
        'name': c.name,
        'email': c.email,
        'phone_number': c.phoneNumber,
        'address': c.address,
      });

  Future<void> deleteCustomer(Customer c) async {
    await _client.collection('customers').delete(c.id);
    await deletePetsForCustomer(c.id);
  }

  // ── Pets ───────────────────────────────────────────────────────────────────

  Pet _toPet(RecordModel r) => Pet(
        id: r.id,
        customerId: r.getStringValue('customer_id'),
        name: r.getStringValue('name'),
        species: r.getStringValue('species'),
        breed: r.getStringValue('breed'),
        age: r.getIntValue('age'),
        notes: r.getStringValue('notes'),
        createdAt: DateTime.tryParse(r.get<String>('created')) ?? DateTime.now(),
      );

  Future<List<Pet>> getPets(String customerId) async {
    final records = await _client.collection('pets').getFullList(
        filter: 'customer_id = "$customerId"');
    return records.map(_toPet).toList();
  }

  Future<void> savePet(Pet p) => _upsert('pets', p.id, {
        'customer_id': p.customerId,
        'name': p.name,
        'species': p.species,
        'breed': p.breed,
        'age': p.age,
        'notes': p.notes,
      });

  Future<void> deletePet(Pet p) =>
      _client.collection('pets').delete(p.id);

  /// Uploads [localPaths] as new files on the `paperwork` field of a pet record.
  /// Only call with paths that haven't been uploaded yet — files are appended.
  Future<void> uploadPetFiles(String petId, List<String> localPaths) async {
    final files = <http.MultipartFile>[];
    for (final path in localPaths) {
      final f = File(path);
      if (!await f.exists()) continue;
      final bytes = await f.readAsBytes();
      final filename = path.split('/').last;
      files.add(http.MultipartFile.fromBytes('paperwork', bytes,
          filename: filename));
    }
    if (files.isEmpty) return;
    await _client.collection('pets').update(petId, files: files);
  }

  Future<void> deletePetsForCustomer(String customerId) async {
    final pets = await getPets(customerId);
    for (final p in pets) {
      await _client.collection('pets').delete(p.id);
    }
  }

  // ── Bookings ───────────────────────────────────────────────────────────────

  Booking _toBooking(RecordModel r) => Booking(
        id: r.id,
        customerId: r.getStringValue('customer_id'),
        customerName: r.getStringValue('customer_name'),
        day: r.getIntValue('day'),
        month: r.getIntValue('month'),
        year: r.getIntValue('year'),
        endDay: r.getIntValue('end_day'),
        runIndex: r.getIntValue('kennel_index'),
        runName: r.getStringValue('kennel_name'),
        notes: r.getStringValue('notes'),
        status: r.getStringValue('status').isEmpty
            ? 'Scheduled'
            : r.getStringValue('status'),
        checkInTime: r.getStringValue('check_in_time').isEmpty
            ? 'AM'
            : r.getStringValue('check_in_time'),
      );

  Future<List<Booking>> getBookings() async {
    final records = await _client.collection('bookings')
        .getFullList();
    return records.map(_toBooking).toList();
  }

  Future<void> saveBooking(Booking b) => _upsert('bookings', b.id, {
        'customer_id': b.customerId,
        'customer_name': b.customerName,
        'day': b.day,
        'month': b.month,
        'year': b.year,
        'end_day': b.endDay,
        'kennel_index': b.runIndex,
        'kennel_name': b.runName,
        'notes': b.notes,
        'status': b.status,
        'check_in_time': b.checkInTime,
      });

  Future<void> deleteBooking(Booking b) =>
      _client.collection('bookings').delete(b.id);

  // ── Invoices ───────────────────────────────────────────────────────────────

  Invoice _toInvoice(RecordModel r) => Invoice(
        id: r.id,
        customerId: r.getStringValue('customer_id'),
        customerName: r.getStringValue('customer_name'),
        invoiceNumber: r.getStringValue('invoice_number'),
        bookingId: r.getStringValue('booking_id'),
        issueDate: DateTime.tryParse(r.getStringValue('issue_date')) ??
            DateTime.now(),
        dueDate: DateTime.tryParse(r.getStringValue('due_date')) ??
            DateTime.now().add(const Duration(days: 30)),
        status: r.getStringValue('status').isEmpty
            ? 'Draft'
            : r.getStringValue('status'),
        notes: r.getStringValue('notes'),
        subTotal: r.getDoubleValue('sub_total'),
        taxRate: r.getDoubleValue('tax_rate'),
        taxAmount: r.getDoubleValue('tax_amount'),
        totalAmount: r.getDoubleValue('total_amount'),
        createdAt: DateTime.tryParse(r.get<String>('created')) ?? DateTime.now(),
      );

  Future<bool> hasInvoiceForBooking(String bookingId) async {
    if (bookingId.isEmpty) return false;
    try {
      final result = await _client.collection('invoices').getList(
        filter: 'booking_id = "$bookingId"',
        perPage: 1,
      );
      return result.totalItems > 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<Invoice>> getInvoices() async {
    try {
      final records = await _client.collection('invoices')
          .getFullList(sort: '-created');
      return records.map(_toInvoice).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Invoice?> getInvoice(String id) async {
    try {
      return _toInvoice(
          await _client.collection('invoices').getOne(id));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveInvoice(Invoice inv) => _upsert('invoices', inv.id, {
        'customer_id': inv.customerId,
        'customer_name': inv.customerName,
        'invoice_number': inv.invoiceNumber,
        'booking_id': inv.bookingId,
        'issue_date': inv.issueDate.toIso8601String(),
        'due_date': inv.dueDate.toIso8601String(),
        'status': inv.status,
        'notes': inv.notes,
        'sub_total': inv.subTotal,
        'tax_rate': inv.taxRate,
        'tax_amount': inv.taxAmount,
        'total_amount': inv.totalAmount,
      });

  Future<void> deleteInvoice(Invoice inv) async {
    await _client.collection('invoices').delete(inv.id);
    await deleteLineItemsForInvoice(inv.id);
  }

  Future<String> getNextInvoiceNumber() async {
    try {
      final result = await _client.collection('invoices')
          .getList(perPage: 1);
      final count = result.totalItems;
      return 'INV-${(count + 1).toString().padLeft(4, '0')}';
    } catch (_) {
      return 'INV-0001';
    }
  }

  // ── Line Items ─────────────────────────────────────────────────────────────

  InvoiceLineItem _toLineItem(RecordModel r) => InvoiceLineItem(
        id: r.id,
        invoiceId: r.getStringValue('invoice_id'),
        description: r.getStringValue('description'),
        quantity: r.getDoubleValue('quantity'),
        unitPrice: r.getDoubleValue('unit_price'),
      );

  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) async {
    final records = await _client.collection('invoice_line_items').getFullList(
        filter: 'invoice_id = "$invoiceId"');
    return records.map(_toLineItem).toList();
  }

  Future<void> saveLineItem(InvoiceLineItem item) =>
      _upsert('invoice_line_items', item.id, {
        'invoice_id': item.invoiceId,
        'description': item.description,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      });

  Future<void> deleteLineItemsForInvoice(String invoiceId) async {
    final items = await getLineItems(invoiceId);
    for (final item in items) {
      await _client.collection('invoice_line_items').delete(item.id);
    }
  }

  // ── Services ───────────────────────────────────────────────────────────────

  Service _toService(RecordModel r) => Service(
        id: r.id,
        name: r.getStringValue('name'),
        description: r.getStringValue('description'),
        defaultPrice: r.getDoubleValue('default_price'),
        unit: r.getStringValue('unit').isEmpty
            ? 'flat fee'
            : r.getStringValue('unit'),
        isActive: r.getBoolValue('is_active'),
      );

  Future<List<Service>> getServices() async {
    final records = await _client.collection('services')
        .getFullList(sort: '+name');
    return records.map(_toService).toList();
  }

  Future<void> saveService(Service s) => _upsert('services', s.id, {
        'name': s.name,
        'description': s.description,
        'default_price': s.defaultPrice,
        'unit': s.unit,
        'is_active': s.isActive,
      });

  Future<void> deleteService(Service s) =>
      _client.collection('services').delete(s.id);
}
