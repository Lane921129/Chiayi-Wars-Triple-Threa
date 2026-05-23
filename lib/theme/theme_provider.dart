import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isSimplifiedMode = false;
  bool _isDarkMode = true;

  bool get isSimplifiedMode => _isSimplifiedMode;
  bool get isDarkMode => _isDarkMode;
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
}
