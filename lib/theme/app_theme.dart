import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// THEME LOCK: light — source: domain signal (consumer retail app)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFF4CAF7D);
  static const Color accentLight = Color(0xFFE8F5EE);
  static const Color accentContainer = Color(0xFFD0EFE0);

  // Semantic colors
  static const Color success = Color(0xFF4CAF7D);
  static const Color warning = Color(0xFFE8A020);
  static const Color error = Color(0xFFD94040);
  static const Color warningLight = Color(0xFFFFF3E0);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8F8F6);
  static const Color surfaceVariantLight = Color(0xFFF2F2F0);
  static const Color outlineLight = Color(0xFFE0E0DC);
  static const Color mutedText = Color(0xFF8A8A8A);
  static const Color darkText = Color(0xFF1A1A1A);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF121212);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: accentContainer,
      onPrimaryContainer: Color(0xFF0D3D22),
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: accentLight,
      onSecondaryContainer: Color(0xFF0D3D22),
      surface: surfaceLight,
      onSurface: darkText,
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: mutedText,
      error: error,
      onError: Colors.white,
      outline: outlineLight,
      outlineVariant: Color(0xFFEEEEEB),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
      iconTheme: IconThemeData(color: darkText),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outlineLight, width: 1),
      ),
      color: surfaceLight,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      border: UnderlineInputBorder(borderSide: BorderSide(color: outlineLight)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: outlineLight),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: error)),
      filled: false,
      contentPadding: EdgeInsets.symmetric(vertical: 12),
      labelStyle: TextStyle(color: mutedText, fontFamily: 'Outfit'),
      hintStyle: TextStyle(color: mutedText, fontFamily: 'Outfit'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primary,
      labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(color: outlineLight, thickness: 1, space: 0),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1A3D2B),
      onPrimaryContainer: Color(0xFFD0EFE0),
      secondary: accent,
      onSecondary: Colors.white,
      surface: surfaceDark,
      onSurface: Color(0xFFE6E6E6),
      surfaceContainerHighest: Color(0xFF2A2A2A),
      onSurfaceVariant: Color(0xFF9A9A9A),
      error: Color(0xFFCF6679),
      onError: Colors.white,
      outline: Color(0xFF3A3A3A),
      outlineVariant: Color(0xFF2A2A2A),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.outfitTextTheme(),
  );
}
