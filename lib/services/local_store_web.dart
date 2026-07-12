import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import 'local_store.dart';

/// Web-only local store: each collection is a JSON array kept in
/// SharedPreferences (backed by localStorage on web). Good enough for
/// local testing on web — not a production sync target.
class WebJsonStore implements LocalStore {
  late final SharedPreferences _prefs;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) =>
      _prefs.setString(key, jsonEncode(list));

  Future<void> _upsert(
      String key, String id, Map<String, dynamic> map) async {
    final list = _readList(key);
    final index = list.indexWhere((m) => m['id'] == id);
    if (index >= 0) {
      list[index] = map;
    } else {
      list.add(map);
    }
    await _writeList(key, list);
  }

  Future<void> _remove(String key, String id) async {
    final list = _readList(key)..removeWhere((m) => m['id'] == id);
    await _writeList(key, list);
  }

  // ── Customers ──────────────────────────────────────────────────────────
  static const _customersKey = 'local_customers';

  @override
  Future<List<Customer>> getCustomers() async {
    final list = _readList(_customersKey).map(Customer.fromMap).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<Customer?> getCustomer(String id) async {
    final list = _readList(_customersKey);
    final map = list.where((m) => m['id'] == id).firstOrNull;
    return map == null ? null : Customer.fromMap(map);
  }

  @override
  Future<void> saveCustomer(Customer c) =>
      _upsert(_customersKey, c.id, c.toMap());

  @override
  Future<void> deleteCustomer(Customer c) async {
    await _remove(_customersKey, c.id);
    await deletePetsForCustomer(c.id);
  }

  // ── Pets ───────────────────────────────────────────────────────────────
  static const _petsKey = 'local_pets';

  @override
  Future<List<Pet>> getPets(String customerId) async => _readList(_petsKey)
      .map(Pet.fromMap)
      .where((p) => p.customerId == customerId)
      .toList();

  @override
  Future<void> savePet(Pet p) => _upsert(_petsKey, p.id, p.toMap());

  @override
  Future<void> deletePet(Pet p) => _remove(_petsKey, p.id);

  @override
  Future<void> deletePetsForCustomer(String customerId) async {
    final list = _readList(_petsKey)
      ..removeWhere((m) => m['customerId'] == customerId);
    await _writeList(_petsKey, list);
  }

  // ── Bookings ───────────────────────────────────────────────────────────
  static const _bookingsKey = 'local_bookings';

  @override
  Future<List<Booking>> getBookings() async =>
      _readList(_bookingsKey).map(Booking.fromMap).toList();

  @override
  Future<void> saveBooking(Booking b) =>
      _upsert(_bookingsKey, b.id, b.toMap());

  @override
  Future<void> deleteBooking(Booking b) => _remove(_bookingsKey, b.id);

  // ── Invoices ───────────────────────────────────────────────────────────
  static const _invoicesKey = 'local_invoices';

  @override
  Future<bool> hasInvoiceForBooking(String bookingId) async {
    if (bookingId.isEmpty) return false;
    return _readList(_invoicesKey).any((m) => m['bookingId'] == bookingId);
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    final list = _readList(_invoicesKey).map(Invoice.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Invoice?> getInvoice(String id) async {
    final map = _readList(_invoicesKey).where((m) => m['id'] == id).firstOrNull;
    return map == null ? null : Invoice.fromMap(map);
  }

  @override
  Future<void> saveInvoice(Invoice inv) =>
      _upsert(_invoicesKey, inv.id, inv.toMap());

  @override
  Future<void> deleteInvoice(Invoice inv) async {
    await _remove(_invoicesKey, inv.id);
    await deleteLineItemsForInvoice(inv.id);
  }

  @override
  Future<String> getNextInvoiceNumber() async {
    final count = _readList(_invoicesKey).length;
    return 'INV-${(count + 1).toString().padLeft(4, '0')}';
  }

  // ── Line Items ─────────────────────────────────────────────────────────
  static const _lineItemsKey = 'local_invoice_line_items';

  @override
  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) async =>
      _readList(_lineItemsKey)
          .map(InvoiceLineItem.fromMap)
          .where((i) => i.invoiceId == invoiceId)
          .toList();

  @override
  Future<void> saveLineItem(InvoiceLineItem item) =>
      _upsert(_lineItemsKey, item.id, item.toMap());

  @override
  Future<void> deleteLineItemsForInvoice(String invoiceId) async {
    final list = _readList(_lineItemsKey)
      ..removeWhere((m) => m['invoiceId'] == invoiceId);
    await _writeList(_lineItemsKey, list);
  }

  // ── Services ───────────────────────────────────────────────────────────
  static const _servicesKey = 'local_services';

  @override
  Future<List<Service>> getServices() async {
    final list = _readList(_servicesKey).map(Service.fromMap).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<void> saveService(Service s) =>
      _upsert(_servicesKey, s.id, s.toMap());

  @override
  Future<void> deleteService(Service s) => _remove(_servicesKey, s.id);
}

LocalStore createLocalStore() => WebJsonStore();
