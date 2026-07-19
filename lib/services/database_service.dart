import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import 'local_store.dart';
import 'local_store_firestore.dart';

/// Thin facade over a [LocalStore], scoped to one signed-in business
/// (tenant). A fresh [DatabaseService] is constructed per authenticated
/// session — see `AuthGate` in main.dart.
class DatabaseService {
  final LocalStore _store;

  DatabaseService({required String tenantId})
      : _store = FirestoreStore(tenantId);

  Future<void> initialize() => _store.initialize();

  // ── Customers ──────────────────────────────────────────────────────────
  Future<List<Customer>> getCustomers() => _store.getCustomers();
  Future<Customer?> getCustomer(String id) => _store.getCustomer(id);
  Future<void> saveCustomer(Customer c) => _store.saveCustomer(c);
  Future<void> deleteCustomer(Customer c) => _store.deleteCustomer(c);

  // ── Pets ───────────────────────────────────────────────────────────────
  Future<List<Pet>> getPets(String customerId) => _store.getPets(customerId);
  Future<void> savePet(Pet p) => _store.savePet(p);
  Future<void> deletePet(Pet p) => _store.deletePet(p);
  Future<void> deletePetsForCustomer(String customerId) =>
      _store.deletePetsForCustomer(customerId);

  // ── Bookings ───────────────────────────────────────────────────────────
  Future<List<Booking>> getBookings() => _store.getBookings();
  Future<void> saveBooking(Booking b) => _store.saveBooking(b);
  Future<void> deleteBooking(Booking b) => _store.deleteBooking(b);

  // ── Invoices ───────────────────────────────────────────────────────────
  Future<bool> hasInvoiceForBooking(String bookingId) =>
      _store.hasInvoiceForBooking(bookingId);
  Future<List<Invoice>> getInvoices() => _store.getInvoices();
  Future<Invoice?> getInvoice(String id) => _store.getInvoice(id);
  Future<void> saveInvoice(Invoice inv) => _store.saveInvoice(inv);
  Future<void> deleteInvoice(Invoice inv) => _store.deleteInvoice(inv);
  Future<String> getNextInvoiceNumber() => _store.getNextInvoiceNumber();

  // ── Line Items ─────────────────────────────────────────────────────────
  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) =>
      _store.getLineItems(invoiceId);
  Future<void> saveLineItem(InvoiceLineItem item) =>
      _store.saveLineItem(item);
  Future<void> deleteLineItemsForInvoice(String invoiceId) =>
      _store.deleteLineItemsForInvoice(invoiceId);

  // ── Services ───────────────────────────────────────────────────────────
  Future<List<Service>> getServices() => _store.getServices();
  Future<void> saveService(Service s) => _store.saveService(s);
  Future<void> deleteService(Service s) => _store.deleteService(s);

  Stream<void> get changes => _store.changes;
}
