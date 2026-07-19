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

  // Theme
  static int get themeIndex => _p.getInt('ThemeIndex') ?? 0;
  static set themeIndex(int v) => _p.setInt('ThemeIndex', v.clamp(0, 4));

  static bool get isDark => _p.getBool('IsDarkMode') ?? false;
  static set isDark(bool v) => _p.setBool('IsDarkMode', v);

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
