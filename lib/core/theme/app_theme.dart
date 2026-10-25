import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_custom_colors.dart';

/// Comprehensive factory for the application theme.
///
/// Features a unified #3D83F5 brand theme with dedicated Light and Dark modes
/// and [ThemeExtension] design tokens.
class AppTheme {
  AppTheme._();

  /// Primary Brand Color: #3D83F5
  static const Color primaryBlue = Color(0xFF3D83F5);

  /// Build [ThemeData] for [brightness] (light or dark).
  static ThemeData build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    const primary = primaryBlue;
    const onPrimary = Colors.white;

    final scaffoldBg = isDark
        ? const Color(0xFF090E17)
        : Colors.white;
    final surface = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final cardBorder = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final inputFill = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFF1F5F9);
    const inputBorder = Colors.transparent;
    final subtleText = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final surfaceHover = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    final pillBackground = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final pillText = isDark ? Colors.white70 : const Color(0xFF64748B);
    const pillActiveBackground = primaryBlue;
    const pillActiveText = Colors.white;

    final bottomSheetHandle = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFFCBD5E1);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primaryBlue,
      onSecondary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: surface,
      onSurface: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
    );

    final customColors = AppCustomColors(
      heroCardBackground: primaryBlue,
      cardBackground: surface,
      cardBorder: cardBorder,
      inputFill: inputFill,
      inputBorder: inputBorder,
      subtleText: subtleText,
      surfaceHover: surfaceHover,
      pillBackground: pillBackground,
      pillText: pillText,
      pillActiveBackground: pillActiveBackground,
      pillActiveText: pillActiveText,
      bottomSheetHandle: bottomSheetHandle,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: surface,
      dividerColor: cardBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      extensions: [customColors],
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.robotoTextTheme(baseTheme.textTheme),
    );
  }

  /// Convenience getters for light and dark themes
  static ThemeData get lightTheme => build(brightness: Brightness.light);
  static ThemeData get darkTheme => build(brightness: Brightness.dark);

  /// Backward compatible methods
  static ThemeData light([dynamic _]) => lightTheme;
  static ThemeData dark([dynamic _]) => darkTheme;
}
