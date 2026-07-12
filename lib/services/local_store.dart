import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';

/// Local persistence backend. Implemented by an Isar-backed store on
/// native platforms and a JSON/SharedPreferences store on web.
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
}
