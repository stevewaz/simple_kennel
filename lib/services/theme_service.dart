import 'package:flutter/material.dart';
import 'prefs_service.dart';

class ThemePreset {
  final String name;
  final Color primary;
  final Color dark;
  final Color light;
  final Color lightBg;
  final Color border;
  final Color gridLine;
  final Color tabBg;

  const ThemePreset({
    required this.name,
    required this.primary,
    required this.dark,
    required this.light,
    required this.lightBg,
    required this.border,
    required this.gridLine,
    required this.tabBg,
  });
}

class ThemeService extends ChangeNotifier {
  static const List<ThemePreset> presets = [
    ThemePreset(
      name: 'Purple',
      primary: Color(0xFF7B5EA7),
      dark: Color(0xFF4A3570),
      light: Color(0xFFF5F0FF),
      lightBg: Color(0xFFEEE8FF),
      border: Color(0xFFE8E0F0),
      gridLine: Color(0xFFD8D0E8),
      tabBg: Color(0xFF1E1130),
    ),
    ThemePreset(
      name: 'Teal',
      primary: Color(0xFF00897B),
      dark: Color(0xFF00695C),
      light: Color(0xFFE8F5F3),
      lightBg: Color(0xFFB2DFDB),
      border: Color(0xFFE0F2F1),
      gridLine: Color(0xFFB2DFDB),
      tabBg: Color(0xFF003D36),
    ),
    ThemePreset(
      name: 'Ocean',
      primary: Color(0xFF1976D2),
      dark: Color(0xFF0D47A1),
      light: Color(0xFFEBF3FF),
      lightBg: Color(0xFFBBDEFB),
      border: Color(0xFFDDEEFF),
      gridLine: Color(0xFFBBDEFB),
      tabBg: Color(0xFF0A2463),
    ),
    ThemePreset(
      name: 'Forest',
      primary: Color(0xFF388E3C),
      dark: Color(0xFF1B5E20),
      light: Color(0xFFF0FFF0),
      lightBg: Color(0xFFC8E6C9),
      border: Color(0xFFE8F5E9),
      gridLine: Color(0xFFC8E6C9),
      tabBg: Color(0xFF0A280B),
    ),
    ThemePreset(
      name: 'Sunset',
      primary: Color(0xFFF4511E),
      dark: Color(0xFFBF360C),
      light: Color(0xFFFFF3E0),
      lightBg: Color(0xFFFFCCBC),
      border: Color(0xFFFFEBEE),
      gridLine: Color(0xFFFFCCBC),
      tabBg: Color(0xFF3E1000),
    ),
  ];

  int _index = PrefsService.themeIndex;
  bool _isDark = PrefsService.isDark;

  int get index => _index;
  bool get isDark => _isDark;
  ThemePreset get current => presets[_index.clamp(0, presets.length - 1)];

  Color get primaryColor => current.primary;
  Color get darkColor => current.dark;
  Color get tabBgColor => current.tabBg;

  Color get lightColor => _isDark ? const Color(0xFF111111) : current.light;
  Color get lightBgColor => _isDark ? const Color(0xFF2A2A2A) : current.lightBg;
  Color get borderColor => _isDark ? const Color(0xFF333333) : current.border;
  Color get gridLineColor => _isDark ? const Color(0xFF2A2A2A) : current.gridLine;
  Color get cardBgColor => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get textColor => _isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A2E);
  Color get subtextColor => _isDark ? const Color(0xFF999999) : const Color(0xFF666666);
  Color get formBgColor => _isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8);
  Color get inputBorderColor => _isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
  Color get deleteBgColor => _isDark ? const Color(0xFF3D1515) : const Color(0xFFFFEAEA);
  Color get scaffoldBgColor => _isDark ? const Color(0xFF0D0D0D) : current.light;

  void setIndex(int i) {
    _index = i.clamp(0, presets.length - 1);
    PrefsService.themeIndex = _index;
    notifyListeners();
  }

  void setDark(bool v) {
    _isDark = v;
    PrefsService.isDark = v;
    notifyListeners();
  }

  ThemeData buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: _isDark ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBgColor,
      cardColor: cardBgColor,
      dividerColor: borderColor,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: subtextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: formBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
