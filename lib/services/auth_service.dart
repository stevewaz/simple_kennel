import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth. Each business shares one login —
/// the signed-in user's own uid is the tenant id everywhere else in the app.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  /// Creates the business's login and seeds its tenant settings doc —
  /// this first write is what "creates" the tenant; there's no separate step.
  Future<void> signUp(
      String email, String password, String businessName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final uid = credential.user!.uid;
    await FirebaseFirestore.instance
        .collection('tenants')
        .doc(uid)
        .collection('settings')
        .doc('business')
        .set({
      'businessName': businessName.trim(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
