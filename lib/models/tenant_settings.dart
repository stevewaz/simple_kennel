/// A business's shared, synced settings — one per tenant, stored at
/// `/tenants/{tenantId}/settings/business`. Unlike the per-device
/// preferences in PrefsService (theme, pet photo paths), everything here
/// needs to be the same across all of a business's devices.
class TenantSettings {
  String businessName;
  String businessAddress;
  String businessPhone;
  String businessEmail;
  double defaultTaxRate;
  double nightlyRate;
  int runCount;

  /// Sparse: only runs with a custom name have an entry, keyed by index
  /// as a string (e.g. `{"0": "Suite A"}`) — matches the original
  /// per-key SharedPreferences storage. A missing entry means "Run N+1".
  Map<String, String> runNames;

  TenantSettings({
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.defaultTaxRate = 0,
    this.nightlyRate = 0,
    this.runCount = 15,
    Map<String, String>? runNames,
  }) : runNames = runNames ?? {};

  String get displayName => businessName.isEmpty ? 'Runbook' : businessName;

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'businessAddress': businessAddress,
        'businessPhone': businessPhone,
        'businessEmail': businessEmail,
        'defaultTaxRate': defaultTaxRate,
        'nightlyRate': nightlyRate,
        'runCount': runCount,
        'runNames': runNames,
      };

  factory TenantSettings.fromMap(Map<String, dynamic> m) => TenantSettings(
        businessName: m['businessName'] as String? ?? '',
        businessAddress: m['businessAddress'] as String? ?? '',
        businessPhone: m['businessPhone'] as String? ?? '',
        businessEmail: m['businessEmail'] as String? ?? '',
        defaultTaxRate: (m['defaultTaxRate'] as num?)?.toDouble() ?? 0,
        nightlyRate: (m['nightlyRate'] as num?)?.toDouble() ?? 0,
        runCount: (m['runCount'] as int?)?.clamp(1, 50) ?? 15,
        runNames: (m['runNames'] as Map?)?.cast<String, String>() ?? const {},
      );

  TenantSettings copyWith({
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    double? defaultTaxRate,
    double? nightlyRate,
    int? runCount,
    Map<String, String>? runNames,
  }) =>
      TenantSettings(
        businessName: businessName ?? this.businessName,
        businessAddress: businessAddress ?? this.businessAddress,
        businessPhone: businessPhone ?? this.businessPhone,
        businessEmail: businessEmail ?? this.businessEmail,
        defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
        nightlyRate: nightlyRate ?? this.nightlyRate,
        runCount: runCount ?? this.runCount,
        runNames: runNames ?? this.runNames,
      );
}
