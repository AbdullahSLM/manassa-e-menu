import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryDarkRed = Color(0xFFC62828);
  static const Color secondaryBlue = Color(0xFF1E88E5);
  static const Color secondaryBlueDark = Color(0xFF90CAF9);
  static const Color successGreen = Color(0xFF43A047);
  static const Color successGreenDark = Color(0xFF66BB6A);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color errorRedDark = Color(0xFFEF5350);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: primaryRed,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryRed,
      secondary: secondaryBlue,
      error: errorRed,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Colors.black,
    ),
    useMaterial3: true,
    fontFamily: 'DG Heaven',
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: primaryDarkRed,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryDarkRed,
      secondary: secondaryBlueDark,
      error: errorRedDark,
      surface: Color(0xFF121212),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    useMaterial3: true,
    fontFamily: 'DG Heaven',
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
