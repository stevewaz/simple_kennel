import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService db;

  AppProvider(this.db);

  List<Customer> customers = [];
  List<Booking> bookings = [];
  List<Invoice> invoices = [];
  List<Service> services = [];

  bool _loaded = false;

  Future<void> loadAll() async {
    if (_loaded) return;
    await db.initialize();
    await Future.wait([
      _loadCustomers(),
      _loadBookings(),
      _loadInvoices(),
      _loadServices(),
    ]);
    _loaded = true;
    notifyListeners();
  }

  void reset() {
    customers = [];
    bookings = [];
    invoices = [];
    services = [];
    _loaded = false;
    notifyListeners();
  }

  Future<void> reload() async {
    await Future.wait([
      _loadCustomers(),
      _loadBookings(),
      _loadInvoices(),
      _loadServices(),
    ]);
    notifyListeners();
  }

  Future<void> _loadCustomers() async => customers = await db.getCustomers();
  Future<void> _loadBookings() async => bookings = await db.getBookings();
  Future<void> _loadInvoices() async => invoices = await db.getInvoices();
  Future<void> _loadServices() async => services = await db.getServices();

  // ── Customers ──────────────────────────────────────────────────────────────

  Future<void> saveCustomer(Customer c) async {
    await db.saveCustomer(c);
    await _loadCustomers();
    notifyListeners();
  }

  Future<void> deleteCustomer(Customer c) async {
    await db.deleteCustomer(c);
    await _loadCustomers();
    notifyListeners();
  }

  Future<List<Pet>> getPets(String customerId) => db.getPets(customerId);

  Future<void> savePet(Pet p) async {
    await db.savePet(p);
    final allPaths = PrefsService.getPetPhotos(p.id);
    if (allPaths.isEmpty) return;
    final uploaded = PrefsService.getUploadedPetPhotos(p.id);
    final newPaths = allPaths.where((path) => !uploaded.contains(path)).toList();
    if (newPaths.isEmpty) return;
    try {
      await db.uploadPetFiles(p.id, newPaths);
      PrefsService.markPetPhotosUploaded(p.id, allPaths);
    } catch (_) {
      // Offline — will sync next time the pet is saved
    }
  }

  Future<void> deletePet(Pet p) async => db.deletePet(p);

  // ── Bookings ───────────────────────────────────────────────────────────────

  Future<void> saveBooking(Booking b) async {
    await db.saveBooking(b);
    await _loadBookings();
    notifyListeners();
  }

  Future<void> deleteBooking(Booking b) async {
    await db.deleteBooking(b);
    await _loadBookings();
    notifyListeners();
  }

  // ── Invoices ───────────────────────────────────────────────────────────────

  Future<void> saveInvoice(Invoice inv, List<InvoiceLineItem> items) async {
    await db.saveInvoice(inv);
    await db.deleteLineItemsForInvoice(inv.id);
    for (final item in items) {
      await db.saveLineItem(item);
    }
    await _loadInvoices();
    notifyListeners();
  }

  Future<void> deleteInvoice(Invoice inv) async {
    await db.deleteInvoice(inv);
    await _loadInvoices();
    notifyListeners();
  }

  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) =>
      db.getLineItems(invoiceId);

  Future<String> getNextInvoiceNumber() => db.getNextInvoiceNumber();

  Future<bool> hasInvoiceForBooking(String bookingId) =>
      db.hasInvoiceForBooking(bookingId);

  Future<void> checkInWithDraftInvoice(Booking booking) async {
    await saveBooking(booking.copyWith(status: 'CheckedIn'));
    final alreadyHas = await db.hasInvoiceForBooking(booking.id);
    if (alreadyHas) return;
    final invoiceNumber = await db.getNextInvoiceNumber();
    final customer =
        customers.where((c) => c.id == booking.customerId).firstOrNull;
    final nights =
        (booking.checkOutDate.difference(booking.checkInDate).inDays).clamp(1, 999);
    final nightlyRate = PrefsService.nightlyRate;
    final inv = Invoice(
      customerId: booking.customerId,
      customerName: customer?.name ?? booking.customerName,
      invoiceNumber: invoiceNumber,
      bookingId: booking.id,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: 'Draft',
    );
    final lineItems = nightlyRate > 0
        ? [
            InvoiceLineItem(
              invoiceId: inv.id,
              description: 'Boarding ($nights night${nights == 1 ? '' : 's'})',
              quantity: nights.toDouble(),
              unitPrice: nightlyRate,
            )
          ]
        : <InvoiceLineItem>[];
    await saveInvoice(inv, lineItems);
  }

  // ── Services ───────────────────────────────────────────────────────────────

  Future<void> saveService(Service s) async {
    await db.saveService(s);
    await _loadServices();
    notifyListeners();
  }

  Future<void> deleteService(Service s) async {
    await db.deleteService(s);
    await _loadServices();
    notifyListeners();
  }

  // ── Dashboard helpers ──────────────────────────────────────────────────────

  int get occupiedRuns {
    final today = DateTime.now();
    return bookings
        .where((b) =>
            b.month == today.month &&
            b.year == today.year &&
            b.day <= today.day &&
            today.day <= b.endDay)
        .length;
  }

  int get todayCheckIns {
    final today = DateTime.now();
    return bookings
        .where((b) =>
            b.day == today.day &&
            b.month == today.month &&
            b.year == today.year)
        .length;
  }

  int get todayAmCheckIns {
    final today = DateTime.now();
    return bookings
        .where((b) =>
            b.day == today.day &&
            b.month == today.month &&
            b.year == today.year &&
            b.checkInTime == 'AM')
        .length;
  }

  int get todayPmCheckIns {
    final today = DateTime.now();
    return bookings
        .where((b) =>
            b.day == today.day &&
            b.month == today.month &&
            b.year == today.year &&
            b.checkInTime == 'PM')
        .length;
  }

  int get todayCheckOuts {
    final today = DateTime.now();
    return bookings
        .where((b) =>
            b.endDay == today.day &&
            b.month == today.month &&
            b.year == today.year)
        .length;
  }
}
