import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth + the tenant/staff data model.
/// The original signed-up account's own uid IS the tenant id; staff added
/// later via email invite get their own login but share that same tenant's
/// data (looked up via `/userTenants/{uid}` — see [resolveTenantId]).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  /// Resolves which tenant [uid] belongs to. Falls back to `uid` itself for
  /// accounts created before staff invites existed (an owner's tenantId
  /// has always been their own uid).
  Future<String> resolveTenantId(String uid) async {
    final doc = await _db.collection('userTenants').doc(uid).get();
    return (doc.data()?['tenantId'] as String?) ?? uid;
  }

  /// If [email] has a pending staff invite, returns the inviting business's
  /// name (for the sign-up screen to show "You're joining X"). Null means
  /// signing up with this email creates a brand-new business instead.
  Future<String?> checkInvite(String email) async {
    final invite =
        await _db.collection('invites').doc(_normalize(email)).get();
    final tenantId = invite.data()?['tenantId'] as String?;
    if (tenantId == null) return null;
    final settings = await _db
        .collection('tenants')
        .doc(tenantId)
        .collection('settings')
        .doc('business')
        .get();
    return (settings.data()?['businessName'] as String?) ?? 'this business';
  }

  /// Creates a login and either joins the business that invited this email,
  /// or creates a brand-new one (seeding its tenant settings doc — that
  /// first write is what "creates" the tenant, no separate step).
  Future<void> signUp(
      String email, String password, String businessName) async {
    final normalized = _normalize(email);
    final invite = await _db.collection('invites').doc(normalized).get();
    final inviteTenantId = invite.data()?['tenantId'] as String?;

    final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final uid = credential.user!.uid;

    if (inviteTenantId != null) {
      await _db
          .collection('tenants')
          .doc(inviteTenantId)
          .collection('members')
          .doc(uid)
          .set({
        'email': normalized,
        'addedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await _db.collection('invites').doc(normalized).delete();
      await _db
          .collection('userTenants')
          .doc(uid)
          .set({'tenantId': inviteTenantId});
    } else {
      await _db
          .collection('tenants')
          .doc(uid)
          .collection('settings')
          .doc('business')
          .set({
        'businessName': businessName.trim(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });
      await _db.collection('userTenants').doc(uid).set({'tenantId': uid});
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Staff management ──────────────────────────────────────────────────

  Future<void> inviteStaff(String tenantId, String email) =>
      _db.collection('invites').doc(_normalize(email)).set({
        'tenantId': tenantId,
        'invitedAt': DateTime.now().toUtc().toIso8601String(),
      });

  Stream<List<Map<String, dynamic>>> staffMembers(String tenantId) =>
      _db
          .collection('tenants')
          .doc(tenantId)
          .collection('members')
          .snapshots()
          .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());

  Future<void> removeStaffMember(String tenantId, String uid) => _db
      .collection('tenants')
      .doc(tenantId)
      .collection('members')
      .doc(uid)
      .delete();

  String _normalize(String email) => email.trim().toLowerCase();
}
