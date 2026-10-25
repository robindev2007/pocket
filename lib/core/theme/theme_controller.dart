import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller managing the application brightness mode (ThemeMode: System, Light, Dark)
/// with unified #3D83F5 brand theme.
class ThemeController extends GetxController {
  static ThemeController get to => Get.find<ThemeController>();

  static const String _keyMode = 'mm_theme_mode';

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;

  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeName = prefs.getString(_keyMode);
      if (savedModeName != null) {
        for (final m in ThemeMode.values) {
          if (m.name == savedModeName) {
            _themeMode.value = m;
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    if (_themeMode.value == newMode) return;
    _themeMode.value = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyMode, newMode.name);
    } catch (_) {}
  }

  void toggleThemeMode(BuildContext context) {
    final currentIsDark = isDark(context);
    setThemeMode(currentIsDark ? ThemeMode.light : ThemeMode.dark);
  }

  bool isDark(BuildContext context) {
    if (_themeMode.value == ThemeMode.dark) return true;
    if (_themeMode.value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}
