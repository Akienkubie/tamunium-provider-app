import 'package:flutter/material.dart';

/// TAMUNIUM brand: gold on dark, matching the Bottom Pot / Proper Maintain
/// palette already used across the ecosystem (#C9A84C gold, near-black base).
class AppTheme {
  static const Color gold = Color(0xFFC9A84C);
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ).copyWith(surface: surfaceDark),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          centerTitle: false,
          elevation: 0,
        ),
      );
}
