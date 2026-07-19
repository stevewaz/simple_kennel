import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/pet.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import 'local_store.dart';

/// Firestore-backed store, scoped to one business (tenant) under
/// `/tenants/{tenantId}/...`. Isolation is structural — every read/write
/// goes through [_tenantRef], so there's no way to reach another tenant's
/// data even by mistake. Security rules enforce the same boundary
/// server-side (`firestore.rules`).
class FirestoreStore implements LocalStore {
  final String tenantId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreStore(this.tenantId);

  DocumentReference<Map<String, dynamic>> get _tenantRef =>
      _db.collection('tenants').doc(tenantId);

  @override
  Future<void> initialize() async {}

  // ── Customers ──────────────────────────────────────────────────────────

  @override
  Future<List<Customer>> getCustomers() async {
    final snap =
        await _tenantRef.collection('customers').orderBy('name').get();
    return snap.docs.map((d) => Customer.fromMap(d.data())).toList();
  }

  @override
  Future<Customer?> getCustomer(String id) async {
    final doc = await _tenantRef.collection('customers').doc(id).get();
    final data = doc.data();
    return data == null ? null : Customer.fromMap(data);
  }

  @override
  Future<void> saveCustomer(Customer c) =>
      _tenantRef.collection('customers').doc(c.id).set(c.toMap());

  @override
  Future<void> deleteCustomer(Customer c) async {
    final batch = _db.batch();
    batch.delete(_tenantRef.collection('customers').doc(c.id));
    final pets = await _tenantRef
        .collection('customers')
        .doc(c.id)
        .collection('pets')
        .get();
    for (final d in pets.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // ── Pets ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _petsRef(String customerId) =>
      _tenantRef.collection('customers').doc(customerId).collection('pets');

  @override
  Future<List<Pet>> getPets(String customerId) async {
    final snap = await _petsRef(customerId).get();
    return snap.docs.map((d) => Pet.fromMap(d.data())).toList();
  }

  @override
  Future<void> savePet(Pet p) =>
      _petsRef(p.customerId).doc(p.id).set(p.toMap());

  @override
  Future<void> deletePet(Pet p) => _petsRef(p.customerId).doc(p.id).delete();

  @override
  Future<void> deletePetsForCustomer(String customerId) async {
    final snap = await _petsRef(customerId).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // ── Bookings ───────────────────────────────────────────────────────────

  @override
  Future<List<Booking>> getBookings() async {
    final snap = await _tenantRef.collection('bookings').get();
    return snap.docs.map((d) => Booking.fromMap(d.data())).toList();
  }

  @override
  Future<void> saveBooking(Booking b) =>
      _tenantRef.collection('bookings').doc(b.id).set(b.toMap());

  @override
  Future<void> deleteBooking(Booking b) =>
      _tenantRef.collection('bookings').doc(b.id).delete();

  // ── Invoices ───────────────────────────────────────────────────────────

  @override
  Future<bool> hasInvoiceForBooking(String bookingId) async {
    if (bookingId.isEmpty) return false;
    final snap = await _tenantRef
        .collection('invoices')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    final snap = await _tenantRef
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Invoice.fromMap(d.data())).toList();
  }

  @override
  Future<Invoice?> getInvoice(String id) async {
    final doc = await _tenantRef.collection('invoices').doc(id).get();
    final data = doc.data();
    return data == null ? null : Invoice.fromMap(data);
  }

  @override
  Future<void> saveInvoice(Invoice inv) =>
      _tenantRef.collection('invoices').doc(inv.id).set(inv.toMap());

  @override
  Future<void> deleteInvoice(Invoice inv) async {
    final batch = _db.batch();
    batch.delete(_tenantRef.collection('invoices').doc(inv.id));
    final items = await _tenantRef
        .collection('invoices')
        .doc(inv.id)
        .collection('lineItems')
        .get();
    for (final d in items.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Future<String> getNextInvoiceNumber() async {
    final counterRef = _tenantRef.collection('counters').doc('invoiceNumber');
    final next = await _db.runTransaction<int>((txn) async {
      final snap = await txn.get(counterRef);
      final current = (snap.data()?['value'] as int?) ?? 0;
      final updated = current + 1;
      txn.set(counterRef, {'value': updated}, SetOptions(merge: true));
      return updated;
    });
    return 'INV-${next.toString().padLeft(4, '0')}';
  }

  // ── Line Items ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _lineItemsRef(
          String invoiceId) =>
      _tenantRef.collection('invoices').doc(invoiceId).collection('lineItems');

  @override
  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) async {
    final snap = await _lineItemsRef(invoiceId).get();
    return snap.docs.map((d) => InvoiceLineItem.fromMap(d.data())).toList();
  }

  @override
  Future<void> saveLineItem(InvoiceLineItem item) =>
      _lineItemsRef(item.invoiceId).doc(item.id).set(item.toMap());

  @override
  Future<void> deleteLineItemsForInvoice(String invoiceId) async {
    final snap = await _lineItemsRef(invoiceId).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // ── Services ───────────────────────────────────────────────────────────

  @override
  Future<List<Service>> getServices() async {
    final snap =
        await _tenantRef.collection('services').orderBy('name').get();
    return snap.docs.map((d) => Service.fromMap(d.data())).toList();
  }

  @override
  Future<void> saveService(Service s) =>
      _tenantRef.collection('services').doc(s.id).set(s.toMap());

  @override
  Future<void> deleteService(Service s) =>
      _tenantRef.collection('services').doc(s.id).delete();

  // ── Live change notifications ─────────────────────────────────────────

  /// Fans in snapshot listeners on every collection [AppProvider] keeps an
  /// in-memory list for, so a remote edit from another device triggers a
  /// [AppProvider.reload]. Excludes the local writer's own echo of a change
  /// it just made (`excludePendingWrites`) — those are already reflected
  /// via the normal save/delete call path.
  @override
  Stream<void> get changes => StreamGroup.merge([
        _tenantRef.collection('customers').snapshots(
            includeMetadataChanges: true).where((s) => !s.metadata.hasPendingWrites),
        _tenantRef.collection('bookings').snapshots(
            includeMetadataChanges: true).where((s) => !s.metadata.hasPendingWrites),
        _tenantRef.collection('invoices').snapshots(
            includeMetadataChanges: true).where((s) => !s.metadata.hasPendingWrites),
        _tenantRef.collection('services').snapshots(
            includeMetadataChanges: true).where((s) => !s.metadata.hasPendingWrites),
      ]).map((_) {});
}
