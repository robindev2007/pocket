import 'package:flutter/material.dart';

/// Centralized color palette for the application.
class AppColors {
  AppColors._();

  // Neutral / Slate Palette
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Primary Accent (#3D83F5 Brand Theme)
  static const Color primary = Color(0xFF3D83F5);
  static const Color primaryForeground = Colors.white;

  // Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Surface & Background
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);

  // Distinct category colors (each category has its own distinct vibrant hue)
  static const Map<String, Color> _categoryColors = {
    // Expense Categories
    'Food': Color(0xFFEA580C), // Orange
    'Groceries': Color(0xFF16A34A), // Green
    'Transport': Color(0xFF0284C7), // Sky Blue
    'Bills': Color(0xFF4F46E5), // Indigo
    'Rent': Color(0xFF9333EA), // Purple
    'Shopping': Color(0xFFDB2777), // Hot Pink
    'Entertainment': Color(0xFFC026D3), // Fuchsia
    'Health': Color(0xFFDC2626), // Crimson Red
    'Education': Color(0xFFD97706), // Amber
    'Debt Repayment': Color(0xFF0D9488), // Teal
    // Income Categories
    'Salary': Color(0xFF059669), // Emerald Mint
    'Freelance': Color(0xFF2563EB), // Royal Blue
    'Allowance': Color(0xFF0891B2), // Cyan
    'Investment': Color(0xFF7C3AED), // Deep Violet
    'Bonus': Color(0xFFEAB308), // Bright Gold
    'Gift': Color(0xFFE11D48), // Rose Red
    // Fallbacks
    'Other': Color(0xFF64748B), // Slate
    'General': Color(0xFF475569), // Slate Dark
  };

  // High-contrast fallback palette for custom categories
  static const List<Color> _dynamicPalette = [
    Color(0xFFEA580C),
    Color(0xFF16A34A),
    Color(0xFF0284C7),
    Color(0xFFDB2777),
    Color(0xFF9333EA),
    Color(0xFFD97706),
    Color(0xFF0D9488),
    Color(0xFFDC2626),
    Color(0xFF4F46E5),
    Color(0xFF0891B2),
    Color(0xFFC026D3),
    Color(0xFF65A30D),
    Color(0xFFE11D48),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFCA8A04),
  ];

  /// Returns a distinct color for a given category.
  static Color getCategoryColor(String? category, {bool isIncome = false}) {
    if (category == null || category.trim().isEmpty) {
      return isIncome ? const Color(0xFF16A34A) : const Color(0xFF64748B);
    }
    final clean = category.trim();
    final direct = _categoryColors[clean];
    if (direct != null) return direct;

    for (final entry in _categoryColors.entries) {
      if (entry.key.toLowerCase() == clean.toLowerCase()) {
        return entry.value;
      }
    }

    final hash = clean.toLowerCase().codeUnits.fold(0, (acc, c) => (acc * 31 + c) & 0x7FFFFFFF);
    return _dynamicPalette[hash % _dynamicPalette.length];
  }

  /// Returns a distinct color for a transaction based on its category or title.
  static Color getTransactionColor({
    String? tag,
    String? title,
    bool isIncome = false,
  }) {
    final effectiveName = (tag != null && tag.trim().isNotEmpty) ? tag : title;
    return getCategoryColor(effectiveName, isIncome: isIncome);
  }
}

