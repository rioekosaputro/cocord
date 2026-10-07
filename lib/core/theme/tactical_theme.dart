import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TacticalTheme {
  // Dark Theme Palette Constants
  static const Color bgAppDark = Color(0xFF0B0F17);
  static const Color bgPanelDark = Color(0xFF131926);
  static const Color bgCardDark = Color(0xFF1C2436);
  static const Color bgInputDark = Color(0xFF111622);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Soft Light Theme Palette Constants
  static const Color bgAppLight = Color(0xFFF1F5F9);
  static const Color bgPanelLight = Color(0xFFFFFFFF);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgInputLight = Color(0xFFF8FAFC);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Shared Accents
  static const Color accentPrimary = Color(0xFF3B82F6); // Royal Blue
  static const Color accentCyan = Color(0xFF3B82F6);
  static const Color accentSuccess = Color(0xFF10B981); // Emerald
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentWarning = Color(0xFFF59E0B); // Amber
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentDanger = Color(0xFFEF4444);  // Coral Red
  static const Color accentRed = Color(0xFFEF4444);

  // Const fallbacks for widget const compatibility
  static const Color bgApp = bgAppDark;
  static const Color bgPanel = bgPanelDark;
  static const Color bgCard = bgCardDark;
  static const Color textPrimary = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textMuted = textSecondaryDark;

  /// Dark Tactical Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgAppDark,
      primaryColor: accentPrimary,
      cardColor: bgCardDark,
      dividerColor: Colors.white12,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPanelDark,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentWarning,
        surface: bgPanelDark,
        error: accentDanger,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    );
  }

  /// Soft Modern Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgAppLight,
      primaryColor: accentPrimary,
      cardColor: bgCardLight,
      dividerColor: const Color(0xFFE2E8F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPanelLight,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(color: textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.light(
        primary: accentPrimary,
        secondary: accentWarning,
        surface: bgPanelLight,
        error: accentDanger,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textPrimaryLight, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: textPrimaryLight, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: textPrimaryLight, fontWeight: FontWeight.w600),
        bodyMedium: GoogleFonts.outfit(color: textPrimaryLight),
        bodySmall: GoogleFonts.outfit(color: textSecondaryLight),
      ),
    );
  }

  static ThemeData get themeData => darkTheme;
}
