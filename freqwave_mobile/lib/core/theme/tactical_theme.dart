import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TacticalTheme {
  static const Color bgApp = Color(0xFF0B0F17);
  static const Color bgPrimary = Color(0xFF0B0F17);
  static const Color bgSecondary = Color(0xFF131926);
  static const Color bgSurface = Color(0xFF131926);
  static const Color bgPanel = Color(0xFF131926);
  static const Color bgCard = Color(0xFF1C2436);
  static const Color bgInput = Color(0xFF111622);
  static const Color bgHover = Color(0xFF263147);

  static const Color accentPrimary = Color(0xFF3B82F6); // Clean Indigo / Royal Blue
  static const Color accentCyan = Color(0xFF3B82F6);
  static const Color accentSuccess = Color(0xFF10B981); // Emerald
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentWarning = Color(0xFFF59E0B); // Warm Amber
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentDanger = Color(0xFFEF4444);  // Coral Red
  static const Color accentRed = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDim = Color(0xFF64748B);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgApp,
      primaryColor: accentPrimary,
      cardColor: bgCard,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentWarning,
        surface: bgSurface,
        error: accentDanger,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.outfit(
          fontSize: 12,
          color: textSecondary,
        ),
      ),
    );
  }
}
