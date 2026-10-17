import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores centralizada de la aplicación.
abstract class AppColors {
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryAccent = Color(0xFF8B5CF6);
  static const surface = Color(0xFFFBFCFE);
  static const textPrimary = Color(0xFF1E2329);
  static const textSecondary = Color(0xFF2A3039);
  static const errorBackground = Color(0xFFFFF1F1);
}

/// Configuración del tema Material de la aplicación.
abstract class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}
