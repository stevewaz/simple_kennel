import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import '../services/database_service.dart';
import '../services/tenant_settings_service.dart';
import '../utils/run_sheet_pdf.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService db;
  final TenantSettingsService tenantSettings;

  AppProvider(this.db, this.tenantSettings);

  List<Customer> customers = [];
  List<Booking> bookings = [];
  List<Invoice> invoices = [];
  List<Service> services = [];

  bool _loaded = false;
  StreamSubscription<void>? _changesSub;

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
    // Picks up edits made on another device without a manual refresh.
    _changesSub ??= db.changes.listen((_) => reload());
  }

  void reset() {
    customers = [];
    bookings = [];
    invoices = [];
    services = [];
    _loaded = false;
    _changesSub?.cancel();
    _changesSub = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    super.dispose();
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
    await ensureInvoiceForBooking(booking);
  }

  /// Looks up the invoice already linked to [bookingId], if any, from the
  /// in-memory list (kept fresh by [_loadInvoices]).
  Invoice? getInvoiceForBooking(String bookingId) =>
      invoices.where((i) => i.bookingId == bookingId).firstOrNull;

  /// Returns the existing draft invoice for [booking] or creates one
  /// (same boarding line item logic as check-in) if none exists yet —
  /// covers bookings checked in without going through [checkInWithDraftInvoice].
  Future<Invoice> ensureInvoiceForBooking(Booking booking) async {
    final existing = getInvoiceForBooking(booking.id);
    if (existing != null) return existing;

    final invoiceNumber = await db.getNextInvoiceNumber();
    final customer =
        customers.where((c) => c.id == booking.customerId).firstOrNull;
    final nights =
        (booking.checkOutDate.difference(booking.checkInDate).inDays).clamp(1, 999);
    final nightlyRate = tenantSettings.nightlyRate;
    final lineItems = nightlyRate > 0
        ? [
            InvoiceLineItem(
              invoiceId: '',
              description: 'Boarding ($nights night${nights == 1 ? '' : 's'})',
              quantity: nights.toDouble(),
              unitPrice: nightlyRate,
            )
          ]
        : <InvoiceLineItem>[];
    final subTotal = lineItems.fold(0.0, (sum, i) => sum + i.lineTotal);
    final taxRate = tenantSettings.defaultTaxRate;
    final taxAmount = subTotal * taxRate;
    final inv = Invoice(
      customerId: booking.customerId,
      customerName: customer?.name ?? booking.customerName,
      invoiceNumber: invoiceNumber,
      bookingId: booking.id,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: 'Draft',
      subTotal: subTotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      totalAmount: subTotal + taxAmount,
      createdAt: DateTime.now().toUtc(),
    );
    for (final item in lineItems) {
      item.invoiceId = inv.id;
    }
    await saveInvoice(inv, lineItems);
    return inv;
  }

  /// Checks a booking out, optionally collecting payment on its invoice
  /// in the same step. Pass [paymentMethod] to mark the invoice Paid;
  /// omit it to just check out without recording payment.
  Future<void> checkOutWithPayment(Booking booking,
      {String? paymentMethod}) async {
    final inv = await ensureInvoiceForBooking(booking);
    if (paymentMethod != null) {
      final items = await getLineItems(inv.id);
      await saveInvoice(
        inv.copyWith(
          status: 'Paid',
          paymentMethod: paymentMethod,
          paidAt: DateTime.now(),
        ),
        items,
      );
    }
    await saveBooking(booking.copyWith(status: 'Scheduled'));
  }

  /// Paid invoices with [Invoice.paidAt] within [start, end] (inclusive),
  /// sorted oldest first — the basis for the payments report/CSV export.
  List<Invoice> paidInvoicesBetween(DateTime start, DateTime end) {
    final list = invoices.where((i) {
      final paidAt = i.paidAt;
      if (i.status != 'Paid' || paidAt == null) return false;
      return !paidAt.isBefore(start) && !paidAt.isAfter(end);
    }).toList();
    list.sort((a, b) => a.paidAt!.compareTo(b.paidAt!));
    return list;
  }

  /// True if [customerId] has no other booking besides [excludingBookingId] —
  /// used to flag a run sheet "NEW CLIENT?" at check-in.
  bool isNewClient(String customerId, String excludingBookingId) => bookings
      .where((b) => b.customerId == customerId && b.id != excludingBookingId)
      .isEmpty;

  /// Gathers the customer + pets for [booking] and sends a printable
  /// "Boarding Data Sheet" (run card) to the platform print dialog.
  Future<void> printRunSheetForBooking(Booking booking) async {
    final customer =
        customers.where((c) => c.id == booking.customerId).firstOrNull;
    final pets = await getPets(booking.customerId);
    await printRunSheet(
      booking,
      customer,
      pets,
      isNewClient: isNewClient(booking.customerId, booking.id),
      businessName: tenantSettings.displayName,
    );
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
