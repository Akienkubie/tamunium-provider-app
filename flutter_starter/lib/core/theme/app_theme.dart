import 'package:flutter/material.dart';

/// TAMUNIUM brand foundation: deep navy, warm gold, and cream.
class AppTheme {
  static const Color navy = Color(0xFF071A2D);
  static const Color navySurface = Color(0xFF102A43);
  static const Color gold = Color(0xFFE0A84B);
  static const Color cream = Color(0xFFF7F1E7);
  static const Color ink = Color(0xFF17202A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: const ColorScheme.light(
          primary: navy,
          onPrimary: Colors.white,
          secondary: gold,
          onSecondary: navy,
          surface: cream,
          onSurface: ink,
          error: Color(0xFFB3261E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFB9B1A5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: gold, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navy,
            side: const BorderSide(color: navy),
            minimumSize: const Size.fromHeight(50),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          onPrimary: navy,
          secondary: gold,
          onSecondary: navy,
          surface: navySurface,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
      );
}
