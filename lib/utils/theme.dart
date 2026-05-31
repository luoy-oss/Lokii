import 'package:flutter/material.dart';

class AppTheme {
  // Apple-style accent colors
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color destructiveRed = Color(0xFFFF3B30);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);

  // Light palette
  static const Color _lightBg = Color(0xFFF2F2F7);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightSeparator = Color(0xFFC6C6C8);
  static const Color _lightText1 = Color(0xFF1C1C1E);
  static const Color _lightText2 = Color(0xFF8E8E93);
  static const Color _lightText3 = Color(0xFFAEAEB2);
  static const Color _lightFill = Color(0xFFE5E5EA);

  // Dark palette
  static const Color _darkBg = Color(0xFF000000);
  static const Color _darkCard = Color(0xFF1C1C1E);
  static const Color _darkCard2 = Color(0xFF2C2C2E);
  static const Color _darkSeparator = Color(0xFF38383A);
  static const Color _darkText1 = Color(0xFFFFFFFF);
  static const Color _darkText2 = Color(0xFF98989D);
  static const Color _darkText3 = Color(0xFF636366);
  static const Color _darkFill = Color(0xFF1C1C1E);

  // ── Light Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        surface: _lightCard,
        error: destructiveRed,
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: _lightBg,
        foregroundColor: _lightText1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _lightText1,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: _lightText3),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xF7F9F9F9),
        indicatorColor: primaryBlue,
        elevation: 0,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: const DividerThemeData(
        color: _lightSeparator,
        thickness: 0.5,
        space: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _lightText1, letterSpacing: 0.4),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _lightText1, letterSpacing: 0.4),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _lightText1, letterSpacing: -0.4),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _lightText1, letterSpacing: -0.4),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: _lightText1, letterSpacing: -0.4),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: _lightText1, letterSpacing: -0.2),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _lightText2, letterSpacing: -0.1),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryBlue, letterSpacing: -0.2),
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        surface: _darkCard,
        error: destructiveRed,
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: _darkBg,
        foregroundColor: _darkText1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _darkText1,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: _darkText3),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xF71C1C1E),
        indicatorColor: primaryBlue,
        elevation: 0,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: const DividerThemeData(
        color: _darkSeparator,
        thickness: 0.5,
        space: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _darkText1, letterSpacing: 0.4),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _darkText1, letterSpacing: 0.4),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _darkText1, letterSpacing: -0.4),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _darkText1, letterSpacing: -0.4),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: _darkText1, letterSpacing: -0.4),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: _darkText1, letterSpacing: -0.2),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _darkText2, letterSpacing: -0.1),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryBlue, letterSpacing: -0.2),
      ),
    );
  }

  // ── Context-aware helpers ────────────────────────────────────────────
  static Brightness brightnessOf(BuildContext context) =>
      Theme.of(context).brightness;

  static bool isDark(BuildContext context) =>
      brightnessOf(context) == Brightness.dark;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? _darkCard : _lightCard;

  static Color card2Color(BuildContext context) =>
      isDark(context) ? _darkCard2 : _lightFill;

  static Color text1(BuildContext context) =>
      isDark(context) ? _darkText1 : _lightText1;

  static Color text2(BuildContext context) =>
      isDark(context) ? _darkText2 : _lightText2;

  static Color text3(BuildContext context) =>
      isDark(context) ? _darkText3 : _lightText3;

  static Color separator(BuildContext context) =>
      isDark(context) ? _darkSeparator : _lightSeparator;

  static Color bg(BuildContext context) =>
      isDark(context) ? _darkBg : _lightBg;
}
