import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat("#,##0.##", "en_US");

  /// Formats amount into BDT format: e.g. ৳5,000 or ৳12,450.50
  static String format(double amount, {bool includeSymbol = true}) {
    final formattedNumber = _formatter.format(amount);
    if (!includeSymbol) return formattedNumber;
    return '${AppConstants.currencySymbol}$formattedNumber';
  }

  /// Formats signed amount (e.g., +৳500 or -৳200)
  static String formatSigned(double amount) {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix${format(amount.abs())}';
  }

  /// Formats date for display: e.g. "25 Oct 2026"
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  /// Formats short date: e.g. "25 Oct"
  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }
}

