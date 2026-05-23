import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isSimplifiedMode = false;
  bool _isDarkMode = true;
  bool _isDeveloperMode = false;

  bool get isSimplifiedMode => _isSimplifiedMode;
  bool get isDarkMode => _isDarkMode;
  bool get isDeveloperMode => _isDeveloperMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isSimplifiedMode = !_isSimplifiedMode;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _isDarkMode = mode == ThemeMode.dark;
    notifyListeners();
  }

  void setSimplifiedMode(bool val) {
    _isSimplifiedMode = val;
    notifyListeners();
  }

  void setDeveloperMode(bool val) {
    _isDeveloperMode = val;
    notifyListeners();
  }
}
