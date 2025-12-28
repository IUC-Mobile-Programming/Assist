import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSecondary = Color(0xFF2D2D2D);
  static const Color lightBackground = Color(0xFFF5F5F5);

  static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: Color(0xFF03A9F4),
      background: lightBackground,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardColor: Colors.white,
    dialogBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: successColor,
      foregroundColor: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: Color(0xFF03A9F4),
      background: darkBackground,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkSecondary,
    dialogBackgroundColor: darkSecondary,
    appBarTheme: AppBarTheme(
      color: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: successColor,
      foregroundColor: Colors.white,
    ),
  );
}