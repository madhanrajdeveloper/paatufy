import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0E11);
  static const Color surface = Color(0xFF12161C);
  static const Color surfaceElevated = Color(0xFF181D24);
  static const Color primary = Color(0xFF1ED760);
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A8B3);
  static const Color divider = Color(0xFF252A32);

  static ThemeData get darkTheme {
    final baseDark = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: surface,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: surface,
      ),
    );

    return baseDark.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(baseDark.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      primaryTextTheme: GoogleFonts.poppinsTextTheme(baseDark.primaryTextTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceElevated,
      ),
    );
  }
}