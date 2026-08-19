import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Design System & Color Palette for Paatufy.
/// All ambient gradients, glows, surfaces, and typography tokens are defined here.
class AppTheme {
  // ── 1. Core Brand Colors ──
  static const Color background = Color(0xFF0B0B12);     // Pitch midnight canvas
  static const Color surface = Color(0xFF151522);        // Card tiles & Quick picks
  static const Color surfaceElevated = Color(0xFF181829);// Modals, dialogs & sheets
  static const Color primary = Color(0xFF8B5CF6);        // Primary Electric Purple
  static const Color primaryDark = Color(0xFFA855F7);    // Progress / Active Indicator
  static const Color primaryPurple = Color(0xFFC084FC);  // Accent Neon Lavender
  static const Color primaryGlow = Color(0x338B5CF6);    // Faint purple glow

  // ── 2. Atmospheric Ambient Light Colors ──
  static const Color ambientCore = Color(0x738B5CF6);    // 45% core violet glow
  static const Color ambientMid = Color(0x386B21A8);     // 22% mid transition
  static const Color ambientOuter = Color(0x123B0764);   // 7% outer haze
  static const Color ambientBlob = Color(0x2E8B5CF6);    // Blob solid base glow
  static const Color ambientBlobShadow = Color(0x337C3AED);// Blob blur shadow

  // ── 3. Typography Shades ──
  static const Color textPrimary = Color(0xFFFFFFFF);    // Headings, active song titles
  static const Color textSecondary = Color(0xFFA1A1AA);  // Artist names, secondary subtitles
  static const Color textMuted = Color(0xFF71717A);      // Inactive icons, timestamps
  static const Color divider = Color(0xFF2A2638);        // Subtle borders

  // ── 4. Global Symmetrical Ambient Gradients ──

  /// Top-Right Corner Ambient Radial Glow
  static const RadialGradient topRightCornerGlow = RadialGradient(
    center: Alignment(1.1, -1.0),
    radius: 1.35,
    colors: [
      ambientCore,
      ambientMid,
      ambientOuter,
      Colors.transparent,
    ],
    stops: [0.0, 0.40, 0.75, 1.0],
  );

  /// Top-Left Corner Ambient Radial Glow (Mirrored)
  static const RadialGradient topLeftCornerGlow = RadialGradient(
    center: Alignment(-1.1, -1.0),
    radius: 1.35,
    colors: [
      ambientCore,
      ambientMid,
      ambientOuter,
      Colors.transparent,
    ],
    stops: [0.0, 0.40, 0.75, 1.0],
  );

  /// Top-to-Bottom darkness blend to melt header into canvas background
  static const LinearGradient topVerticalFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x660B0B12),
      background,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Brand Button & Icon Gradient
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryPurple],
  );

  // ── 5. Master ThemeData ──
  static ThemeData get darkTheme {
    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: surface,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryPurple,
        surface: surface,
        surfaceContainerHighest: surfaceElevated,
        onPrimary: Colors.white,
        onSurface: textPrimary,
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
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryPurple,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceElevated,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}