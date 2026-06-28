import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await DatabaseHelper.instance.getSetting('theme_mode');
    if (mode != null) {
      if (mode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (mode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    String val = 'system';
    if (mode == ThemeMode.light) {
      val = 'light';
    } else if (mode == ThemeMode.dark) {
      val = 'dark';
    }
    await DatabaseHelper.instance.saveSetting('theme_mode', val);
  }
}
