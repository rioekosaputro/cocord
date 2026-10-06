import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B0F17);
  static const panel = Color(0xFF131926);
  static const card = Color(0xFF1C2436);
  static const blue = Color(0xFF3B82F6);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);
  static const dim = Color(0xFF64748B);
}

const String kMono = 'monospace';

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.blue,
          secondary: AppColors.amber,
          surface: AppColors.panel,
          error: AppColors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.panel,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.panel,
          indicatorColor: AppColors.blue.withValues(alpha: 0.25),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );
}

/// Small uppercase monospace section label.
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const SectionLabel(this.text, {super.key, this.color = AppColors.amber});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: kMono,
            fontSize: 10,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      );
}

/// Rounded dark card container used across pages.
class Panel extends StatelessWidget {
  final Widget child;
  final Color? border;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.border,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: (border ?? AppColors.blue).withValues(alpha: 0.3)),
        ),
        child: child,
      );
}
