import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import '../utils/fast_hash.dart';
import 'isar_entities.dart';
import 'local_store.dart';

class IsarStore implements LocalStore {
  late final Isar _isar;

  @override
  Future<void> initialize() async {
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        CustomerEntitySchema,
        PetEntitySchema,
        BookingEntitySchema,
        InvoiceEntitySchema,
        InvoiceLineItemEntitySchema,
        ServiceEntitySchema,
      ],
      directory: dir.path,
    );
  }

  // ── Customers ──────────────────────────────────────────────────────────

  @override
  Future<List<Customer>> getCustomers() async => (await _isar.customerEntitys
          .where()
          .sortByName()
          .findAll())
      .map((e) => e.toModel())
      .toList();

  @override
  Future<Customer?> getCustomer(String id) async =>
      (await _isar.customerEntitys.get(fastHash(id)))?.toModel();

  @override
  Future<void> saveCustomer(Customer c) =>
      _isar.writeTxn(() => _isar.customerEntitys.put(CustomerEntity.from(c)));

  @override
  Future<void> deleteCustomer(Customer c) async {
    await _isar.writeTxn(() => _isar.customerEntitys.delete(fastHash(c.id)));
    await deletePetsForCustomer(c.id);
  }

  // ── Pets ───────────────────────────────────────────────────────────────

  @override
  Future<List<Pet>> getPets(String customerId) async => (await _isar
          .petEntitys
          .filter()
          .customerIdEqualTo(customerId)
          .findAll())
      .map((e) => e.toModel())
      .toList();

  @override
  Future<void> savePet(Pet p) =>
      _isar.writeTxn(() => _isar.petEntitys.put(PetEntity.from(p)));

  @override
  Future<void> deletePet(Pet p) =>
      _isar.writeTxn(() => _isar.petEntitys.delete(fastHash(p.id)));

  @override
  Future<void> deletePetsForCustomer(String customerId) async {
    final pets = await getPets(customerId);
    await _isar.writeTxn(() async {
      for (final p in pets) {
        await _isar.petEntitys.delete(fastHash(p.id));
      }
    });
  }

  // ── Bookings ───────────────────────────────────────────────────────────

  @override
  Future<List<Booking>> getBookings() async =>
      (await _isar.bookingEntitys.where().findAll())
          .map((e) => e.toModel())
          .toList();

  @override
  Future<void> saveBooking(Booking b) =>
      _isar.writeTxn(() => _isar.bookingEntitys.put(BookingEntity.from(b)));

  @override
  Future<void> deleteBooking(Booking b) =>
      _isar.writeTxn(() => _isar.bookingEntitys.delete(fastHash(b.id)));

  // ── Invoices ───────────────────────────────────────────────────────────

  @override
  Future<bool> hasInvoiceForBooking(String bookingId) async {
    if (bookingId.isEmpty) return false;
    final count = await _isar.invoiceEntitys
        .filter()
        .bookingIdEqualTo(bookingId)
        .count();
    return count > 0;
  }

  @override
  Future<List<Invoice>> getInvoices() async => (await _isar.invoiceEntitys
          .where()
          .sortByCreatedAtDesc()
          .findAll())
      .map((e) => e.toModel())
      .toList();

  @override
  Future<Invoice?> getInvoice(String id) async =>
      (await _isar.invoiceEntitys.get(fastHash(id)))?.toModel();

  @override
  Future<void> saveInvoice(Invoice inv) => _isar
      .writeTxn(() => _isar.invoiceEntitys.put(InvoiceEntity.from(inv)));

  @override
  Future<void> deleteInvoice(Invoice inv) async {
    await _isar.writeTxn(() => _isar.invoiceEntitys.delete(fastHash(inv.id)));
    await deleteLineItemsForInvoice(inv.id);
  }

  @override
  Future<String> getNextInvoiceNumber() async {
    final count = await _isar.invoiceEntitys.count();
    return 'INV-${(count + 1).toString().padLeft(4, '0')}';
  }

  // ── Line Items ─────────────────────────────────────────────────────────

  @override
  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) async =>
      (await _isar.invoiceLineItemEntitys
              .filter()
              .invoiceIdEqualTo(invoiceId)
              .findAll())
          .map((e) => e.toModel())
          .toList();

  @override
  Future<void> saveLineItem(InvoiceLineItem item) => _isar.writeTxn(() =>
      _isar.invoiceLineItemEntitys.put(InvoiceLineItemEntity.from(item)));

  @override
  Future<void> deleteLineItemsForInvoice(String invoiceId) async {
    final items = await getLineItems(invoiceId);
    await _isar.writeTxn(() async {
      for (final item in items) {
        await _isar.invoiceLineItemEntitys.delete(fastHash(item.id));
      }
    });
  }

  // ── Services ───────────────────────────────────────────────────────────

  @override
  Future<List<Service>> getServices() async => (await _isar.serviceEntitys
          .where()
          .sortByName()
          .findAll())
      .map((e) => e.toModel())
      .toList();

  @override
  Future<void> saveService(Service s) =>
      _isar.writeTxn(() => _isar.serviceEntitys.put(ServiceEntity.from(s)));

  @override
  Future<void> deleteService(Service s) =>
      _isar.writeTxn(() => _isar.serviceEntitys.delete(fastHash(s.id)));
}

LocalStore createLocalStore() => IsarStore();
