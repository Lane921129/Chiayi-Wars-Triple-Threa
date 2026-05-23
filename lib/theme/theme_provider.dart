import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isSimplifiedMode = false;
  bool _isDarkMode = true;

  bool get isSimplifiedMode => _isSimplifiedMode;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isSimplifiedMode = !_isSimplifiedMode;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
