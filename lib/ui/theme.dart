import 'package:flutter/material.dart';

abstract final class InkColors {
  static const navy = Color(0xFF11132E);
  static const purple = Color(0xFF5B3FF5);
  static const lavender = Color(0xFFECE8FF);
  static const orange = Color(0xFFFFB541);
  static const paper = Color(0xFFF6F4EE);
  static const muted = Color(0xFF656680);
  static const line = Color(0xFFE6E1D7);
  static const green = Color(0xFF26735B);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: InkColors.purple,
    primary: InkColors.purple,
    secondary: InkColors.orange,
    surface: const Color(0xFFFFFEFA),
    onSurface: InkColors.navy,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: InkColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: InkColors.paper,
      foregroundColor: InkColors.navy,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.12,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -.4,
      ),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: InkColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: InkColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: InkColors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: InkColors.lavender,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    dividerColor: InkColors.line,
  );
}
