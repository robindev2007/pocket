import 'package:flutter/material.dart';

/// Available theme presets tailored for a modern financial/tech app.
enum AppThemePreset {
  slate,
  emerald,
  sapphire,
  rose;

  String get displayName {
    switch (this) {
      case AppThemePreset.slate:
        return 'Slate';
      case AppThemePreset.emerald:
        return 'Emerald';
      case AppThemePreset.sapphire:
        return 'Sapphire';
      case AppThemePreset.rose:
        return 'Rose';
    }
  }

  String get description {
    switch (this) {
      case AppThemePreset.slate:
        return 'Minimalist charcoal & neutral monochrome';
      case AppThemePreset.emerald:
        return 'Wealth, prosperity & money green';
      case AppThemePreset.sapphire:
        return 'Fintech, banking & royal blue';
      case AppThemePreset.rose:
        return 'Modern lifestyle & warm berry';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemePreset.slate:
        return const Color(0xFF0F172A);
      case AppThemePreset.emerald:
        return const Color(0xFF059669);
      case AppThemePreset.sapphire:
        return const Color(0xFF2563EB);
      case AppThemePreset.rose:
        return const Color(0xFFE11D48);
    }
  }

  Color get accentColor {
    switch (this) {
      case AppThemePreset.slate:
        return const Color(0xFF64748B);
      case AppThemePreset.emerald:
        return const Color(0xFF10B981);
      case AppThemePreset.sapphire:
        return const Color(0xFF3B82F6);
      case AppThemePreset.rose:
        return const Color(0xFFF43F5E);
    }
  }
}
