import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0E3A53);
  static const Color accent = Color(0xFFF9A03F);
  static const Color background = Color(0xFFF7F3EF);
  static const Color backgroundAlt = Color(0xFFDCE7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF5F6B76);

  static final LinearGradient pageGradient = LinearGradient(
    colors: [background, backgroundAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    final colorScheme = baseScheme.copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: const Color(0xFF1B1B1B),
      tertiary: const Color(0xFF6BC4B8),
      onTertiary: const Color(0xFF0B1C1C),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: surface,
      onSurface: const Color(0xFF16222A),
    );

    final baseText = GoogleFonts.workSansTextTheme();
    final displayText = GoogleFonts.dmSerifDisplayTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: baseText.copyWith(
        displayLarge: displayText.displayLarge,
        displayMedium: displayText.displayMedium,
        displaySmall: displayText.displaySmall,
        headlineLarge: displayText.headlineLarge,
        headlineMedium: displayText.headlineMedium,
        headlineSmall: displayText.headlineSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: displayText.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF16222A)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: baseText.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
