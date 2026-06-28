import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'PrefsService.init() must be called first');
    return _prefs!;
  }

  // Branding
  static String get businessName => _p.getString('BrandName') ?? '';
  static set businessName(String v) => _p.setString('BrandName', v);

  static String get businessAddress => _p.getString('BrandAddress') ?? '';
  static set businessAddress(String v) => _p.setString('BrandAddress', v);

  static String get businessPhone => _p.getString('BrandPhone') ?? '';
  static set businessPhone(String v) => _p.setString('BrandPhone', v);

  static String get businessEmail => _p.getString('BrandEmail') ?? '';
  static set businessEmail(String v) => _p.setString('BrandEmail', v);

  static String get displayName =>
      businessName.isEmpty ? 'PawBook' : businessName;

  // Theme
  static int get themeIndex => _p.getInt('ThemeIndex') ?? 0;
  static set themeIndex(int v) => _p.setInt('ThemeIndex', v.clamp(0, 4));

  static bool get isDark => _p.getBool('IsDarkMode') ?? false;
  static set isDark(bool v) => _p.setBool('IsDarkMode', v);

  static double get defaultTaxRate => _p.getDouble('DefaultTaxRate') ?? 0.0;
  static set defaultTaxRate(double v) => _p.setDouble('DefaultTaxRate', v < 0 ? 0 : v);

  static double get nightlyRate => _p.getDouble('NightlyRate') ?? 0.0;
  static set nightlyRate(double v) => _p.setDouble('NightlyRate', v < 0 ? 0 : v);

  // Network role
  static String get networkRole => _p.getString('NetworkRole') ?? 'client';
  static set networkRole(String v) => _p.setString('NetworkRole', v);

  // Runs
  static int get runCount => (_p.getInt('RunCount') ?? 15).clamp(1, 50);
  static set runCount(int v) => _p.setInt('RunCount', v.clamp(1, 50));

  static String getRunName(int index) =>
      _p.getString('RunName_$index') ?? 'Run ${index + 1}';

  static void setRunName(int index, String name) {
    if (name.trim().isEmpty) {
      _p.remove('RunName_$index');
    } else {
      _p.setString('RunName_$index', name.trim());
    }
  }

  // Pet photos (local file paths, stored per petId)
  static List<String> getPetPhotos(String petId) {
    final raw = _p.getString('pet_photos_$petId');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  static void setPetPhotos(String petId, List<String> paths) =>
      _p.setString('pet_photos_$petId', jsonEncode(paths));

  static void removePetPhotos(String petId) => _p.remove('pet_photos_$petId');
}
