import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final seed = const Color(0xFF005F73);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: _textTheme,
      cardTheme: _cardTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final seed = const Color(0xFF0A9396);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: _textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      cardTheme: _cardTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );

  static const CardThemeData _cardTheme = CardThemeData(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
    ),
  );
}
