import 'package:flutter/material.dart';

// ─── 陣營色彩系統 ───────────────────────────────────────────────
class FactionColors {
  // 紅軍（美食派）
  static const redPrimary = Color(0xFFD32F2F);
  static const redLight = Color(0xFFFF6659);
  static const redDark = Color(0xFF9A0007);
  static const redGlow = Color(0xFFFF1744);

  // 綠軍（古蹟派）
  static const greenPrimary = Color(0xFF2E7D32);
  static const greenLight = Color(0xFF60AD5E);
  static const greenDark = Color(0xFF005005);
  static const greenGlow = Color(0xFF00E676);

  // 藍軍（咖啡派）
  static const bluePrimary = Color(0xFF1565C0);
  static const blueLight = Color(0xFF5E92F3);
  static const blueDark = Color(0xFF003C8F);
  static const blueGlow = Color(0xFF2979FF);

  // 通用色彩
  static const gold = Color(0xFFFFD700);
  static const goldLight = Color(0xFFFFEA80);
  static const darkBg = Color(0xFF0D0D1A);
  static const cardBg = Color(0xFF1A1A2E);
  static const cardBorder = Color(0xFF2A2A4A);
  static const textPrimary = Color(0xFFEEEEEE);
  static const textSecondary = Color(0xFFAAAAAA);
  static const divider = Color(0xFF2A2A4A);

  static Color forFaction(String faction) {
    switch (faction) {
      case 'red':
        return redPrimary;
      case 'green':
        return greenPrimary;
      case 'blue':
        return bluePrimary;
      default:
        return Colors.grey;
    }
  }

  static Color glowForFaction(String faction) {
    switch (faction) {
      case 'red':
        return redGlow;
      case 'green':
        return greenGlow;
      case 'blue':
        return blueGlow;
      default:
        return Colors.grey;
    }
  }

  static String nameForFaction(String faction) {
    switch (faction) {
      case 'red':
        return '美食紅軍';
      case 'green':
        return '古蹟綠軍';
      case 'blue':
        return '咖啡藍軍';
      default:
        return '未加入陣營';
    }
  }

  static String emojiForFaction(String faction) {
    switch (faction) {
      case 'red':
        return '🍜';
      case 'green':
        return '🏯';
      case 'blue':
        return '☕';
      default:
        return '⚔️';
    }
  }

  static List<Color> gradientForFaction(String faction) {
    switch (faction) {
      case 'red':
        return [redDark, redPrimary];
      case 'green':
        return [greenDark, greenPrimary];
      case 'blue':
        return [blueDark, bluePrimary];
      default:
        return [const Color(0xFF2A2A4A), const Color(0xFF1A1A2E)];
    }
  }
}

// ─── 全域主題設定 ──────────────────────────────────────────────
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FactionColors.darkBg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: FactionColors.gold,
          secondary: FactionColors.blueLight,
          surface: FactionColors.cardBg,
          error: FactionColors.redPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: FactionColors.cardBg,
          foregroundColor: FactionColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: FactionColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: FactionColors.cardBg,
          selectedItemColor: FactionColors.gold,
          unselectedItemColor: FactionColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 20,
        ),
        cardTheme: CardThemeData(
          color: FactionColors.cardBg,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: FactionColors.cardBorder, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: FactionColors.gold,
            foregroundColor: FactionColors.darkBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FactionColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FactionColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FactionColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FactionColors.gold, width: 2),
          ),
          labelStyle: const TextStyle(color: FactionColors.textSecondary),
          hintStyle: const TextStyle(color: FactionColors.textSecondary),
          prefixIconColor: FactionColors.gold,
        ),
        dividerColor: FactionColors.divider,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: FactionColors.textPrimary, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: FactionColors.textPrimary, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: FactionColors.textPrimary),
          bodyMedium: TextStyle(color: FactionColors.textSecondary),
          titleLarge: TextStyle(color: FactionColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      );

  // 明亮版遊戲風 (Gamified Light)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: FactionColors.gold,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: FactionColors.gold,
        secondary: FactionColors.redPrimary,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: FactionColors.textPrimary),
        titleTextStyle: TextStyle(
          color: FactionColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: FactionColors.textPrimary),
        bodyMedium: TextStyle(color: FactionColors.textSecondary),
      ),
    );
  }
}
