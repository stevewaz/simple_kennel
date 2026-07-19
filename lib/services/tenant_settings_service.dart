import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tenant_settings.dart';

/// Reactive wrapper over the tenant's synced settings doc
/// (`/tenants/{tenantId}/settings/business`) — replaces the business-profile
/// portion of PrefsService with data that stays consistent across a
/// business's devices. Listens live, so a change made on one device shows
/// up on another without a restart.
class TenantSettingsService extends ChangeNotifier {
  final String tenantId;
  TenantSettings _settings = TenantSettings();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  TenantSettingsService(this.tenantId) {
    _sub = _docRef.snapshots().listen((snap) {
      final data = snap.data();
      if (data != null) {
        _settings = TenantSettings.fromMap(data);
        notifyListeners();
      }
    });
  }

  DocumentReference<Map<String, dynamic>> get _docRef => FirebaseFirestore
      .instance
      .collection('tenants')
      .doc(tenantId)
      .collection('settings')
      .doc('business');

  String get businessName => _settings.businessName;
  String get businessAddress => _settings.businessAddress;
  String get businessPhone => _settings.businessPhone;
  String get businessEmail => _settings.businessEmail;
  String get displayName => _settings.displayName;
  double get defaultTaxRate => _settings.defaultTaxRate;
  double get nightlyRate => _settings.nightlyRate;
  int get runCount => _settings.runCount;

  String getRunName(int index) =>
      _settings.runNames['$index'] ?? 'Run ${index + 1}';

  Future<void> _save(TenantSettings updated) async {
    _settings = updated;
    notifyListeners();
    await _docRef.set(updated.toMap(), SetOptions(merge: true));
  }

  Future<void> updateBusinessInfo({
    required String name,
    required String address,
    required String phone,
    required String email,
  }) =>
      _save(_settings.copyWith(
        businessName: name,
        businessAddress: address,
        businessPhone: phone,
        businessEmail: email,
      ));

  Future<void> setTaxRate(double v) =>
      _save(_settings.copyWith(defaultTaxRate: v < 0 ? 0 : v));

  Future<void> setNightlyRate(double v) =>
      _save(_settings.copyWith(nightlyRate: v < 0 ? 0 : v));

  Future<void> setRunCount(int v) =>
      _save(_settings.copyWith(runCount: v.clamp(1, 50)));

  Future<void> setRunName(int index, String name) {
    final names = Map<String, String>.from(_settings.runNames);
    if (name.trim().isEmpty) {
      names.remove('$index');
    } else {
      names['$index'] = name.trim();
    }
    return _save(_settings.copyWith(runNames: names));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
