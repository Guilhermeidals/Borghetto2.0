import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// THEME LOCK: light — Borghetto Mercado e Bistrô
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens

class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Borghetto brand palette
  // Manual base: verde escuro, marrom claro/café e bege areia.
  // ---------------------------------------------------------------------------

  static const Color forest = Color(0xFF062F2D);
  static const Color forestDeep = Color(0xFF021F1E);
  static const Color forestSoft = Color(0xFF164642);
  static const Color forestMist = Color(0xFFE7F0EC);

  static const Color coffee = Color(0xFF8A6044);
  static const Color coffeeDark = Color(0xFF4F3425);
  static const Color coffeeSoft = Color(0xFFB58A68);

  static const Color sand = Color(0xFFE7D3BD);
  static const Color sandLight = Color(0xFFF7EFE5);
  static const Color sandMuted = Color(0xFFD8C0A8);

  static const Color cream = Color(0xFFFFFAF3);
  static const Color caramel = Color(0xFFC8955A);
  static const Color olive = Color(0xFF6F7E55);

  // ---------------------------------------------------------------------------
  // Compatibility aliases — usados nos arquivos atuais.
  // Não remover sem revisar todas as telas.
  // ---------------------------------------------------------------------------

  // Brand colors
  static const Color primary = forest;
  static const Color primaryDark = forestDeep;
  static const Color primaryLight = forestSoft;

  static const Color accent = caramel;
  static const Color accentLight = Color(0xFFF0D4B4);
  static const Color accentContainer = Color(0xFFEAD7C4);

  // Semantic colors
  static const Color success = Color(0xFF4E8B68);
  static const Color warning = caramel;
  static const Color error = Color(0xFFB85C4A);
  static const Color danger = error;
  static const Color warningLight = Color(0xFFFFF3E0);

  // Light surfaces
  static const Color surfaceLight = cream;
  static const Color backgroundLight = sandLight;
  static const Color surfaceVariantLight = Color(0xFFF1E5D7);
  static const Color outlineLight = Color(0xFFE0CFBC);
  static const Color mutedText = Color(0xFF7A6F66);
  static const Color darkText = Color(0xFF1F2523);
  static const Color lightText = Color(0xFFF8EFE5);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF0B3835);
  static const Color backgroundDark = forestDeep;
  static const Color surfaceVariantDark = Color(0xFF123F3B);
  static const Color outlineDark = Color(0xFF315F58);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  static const LinearGradient morningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      sandLight,
      cream,
      Color(0xFFF1E0CE),
    ],
  );

  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      forestDeep,
      forest,
      forestSoft,
    ],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      forest,
      coffeeDark,
      coffee,
    ],
  );

  static const LinearGradient coffeeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      coffeeDark,
      coffee,
      caramel,
    ],
  );

  // ---------------------------------------------------------------------------
  // Radius
  // ---------------------------------------------------------------------------

  static BorderRadius get radiusSmall => BorderRadius.circular(12);
  static BorderRadius get radiusMedium => BorderRadius.circular(18);
  static BorderRadius get radiusLarge => BorderRadius.circular(26);
  static BorderRadius get radiusExtraLarge => BorderRadius.circular(32);
  static BorderRadius get radiusPill => BorderRadius.circular(999);

  // ---------------------------------------------------------------------------
  // Shadows
  // ---------------------------------------------------------------------------

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: forest.withAlpha(18),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: forest.withAlpha(20),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: forest.withAlpha(38),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ];

  // ---------------------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: accentContainer,
          onPrimaryContainer: forestDeep,
          secondary: accent,
          onSecondary: forestDeep,
          secondaryContainer: accentLight,
          onSecondaryContainer: forestDeep,
          surface: surfaceLight,
          onSurface: darkText,
          surfaceContainerHighest: surfaceVariantLight,
          onSurfaceVariant: mutedText,
          error: error,
          onError: Colors.white,
          outline: outlineLight,
          outlineVariant: Color(0xFFEEE2D5),
        ),
        scaffoldBackgroundColor: backgroundLight,
        textTheme: GoogleFonts.outfitTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 57,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: darkText,
            ),
            displayMedium: TextStyle(
              fontSize: 45,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: darkText,
            ),
            displaySmall: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: darkText,
            ),
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
            headlineSmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
            titleSmall: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: darkText,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: mutedText,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: mutedText,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: darkText,
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: darkText,
            ),
            labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: mutedText,
            ),
          ),
        ),
        appBarTheme: AppBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
          iconTheme: const IconThemeData(color: darkText),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: outlineLight, width: 1),
          ),
          color: surfaceLight,
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: outlineLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: outlineLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIconColor: coffee,
          suffixIconColor: coffee,
          labelStyle: const TextStyle(
            color: mutedText,
            fontFamily: 'Outfit',
          ),
          hintStyle: const TextStyle(
            color: mutedText,
            fontFamily: 'Outfit',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primary.withAlpha(120),
            disabledForegroundColor: Colors.white.withAlpha(180),
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primary.withAlpha(120),
            disabledForegroundColor: Colors.white.withAlpha(180),
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: outlineLight),
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceVariantLight,
          selectedColor: primary,
          secondarySelectedColor: accent,
          disabledColor: outlineLight,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          secondaryLabelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(
          color: outlineLight,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surfaceLight,
          selectedItemColor: primary,
          unselectedItemColor: mutedText,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: primary,
          contentTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Dark theme — mantido completo, mas o app segue travado em light por padrão.
  // ---------------------------------------------------------------------------

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          onPrimary: forestDeep,
          primaryContainer: forestSoft,
          onPrimaryContainer: sandLight,
          secondary: caramel,
          onSecondary: forestDeep,
          secondaryContainer: coffee,
          onSecondaryContainer: sandLight,
          surface: surfaceDark,
          onSurface: Color(0xFFEFE8DF),
          surfaceContainerHighest: surfaceVariantDark,
          onSurfaceVariant: Color(0xFFCDBBA7),
          error: Color(0xFFCF6679),
          onError: Colors.white,
          outline: outlineDark,
          outlineVariant: Color(0xFF254C47),
        ),
        scaffoldBackgroundColor: backgroundDark,
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: AppBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: lightText,
          ),
          iconTheme: const IconThemeData(color: lightText),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: outlineDark, width: 1),
          ),
          color: surfaceDark,
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: outlineDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: outlineDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFCF6679)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIconColor: accent,
          suffixIconColor: accent,
          labelStyle: const TextStyle(
            color: Color(0xFFCDBBA7),
            fontFamily: 'Outfit',
          ),
          hintStyle: const TextStyle(
            color: Color(0xFFCDBBA7),
            fontFamily: 'Outfit',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: forestDeep,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: forestDeep,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceVariantDark,
          selectedColor: accent,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(
          color: outlineDark,
          thickness: 1,
          space: 0,
        ),
      );
}
