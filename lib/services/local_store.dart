import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';

/// Persistence backend. Implemented by [FirestoreStore], scoped to one
/// signed-in business (tenant) across all platforms.
abstract class LocalStore {
  Future<void> initialize();

  // ── Customers ──────────────────────────────────────────────────────────
  Future<List<Customer>> getCustomers();
  Future<Customer?> getCustomer(String id);
  Future<void> saveCustomer(Customer c);
  Future<void> deleteCustomer(Customer c);

  // ── Pets ───────────────────────────────────────────────────────────────
  Future<List<Pet>> getPets(String customerId);
  Future<void> savePet(Pet p);
  Future<void> deletePet(Pet p);
  Future<void> deletePetsForCustomer(String customerId);

  // ── Bookings ───────────────────────────────────────────────────────────
  Future<List<Booking>> getBookings();
  Future<void> saveBooking(Booking b);
  Future<void> deleteBooking(Booking b);

  // ── Invoices ───────────────────────────────────────────────────────────
  Future<bool> hasInvoiceForBooking(String bookingId);
  Future<List<Invoice>> getInvoices();
  Future<Invoice?> getInvoice(String id);
  Future<void> saveInvoice(Invoice inv);
  Future<void> deleteInvoice(Invoice inv);
  Future<String> getNextInvoiceNumber();

  // ── Line Items ─────────────────────────────────────────────────────────
  Future<List<InvoiceLineItem>> getLineItems(String invoiceId);
  Future<void> saveLineItem(InvoiceLineItem item);
  Future<void> deleteLineItemsForInvoice(String invoiceId);

  // ── Services ───────────────────────────────────────────────────────────
  Future<List<Service>> getServices();
  Future<void> saveService(Service s);
  Future<void> deleteService(Service s);

  /// Fires whenever this store's data changes for a reason the caller
  /// didn't directly cause via one of the methods above — e.g. another
  /// device's edit arriving through a remote listener. No-op for stores
  /// that are purely local/single-device.
  Stream<void> get changes;
}
