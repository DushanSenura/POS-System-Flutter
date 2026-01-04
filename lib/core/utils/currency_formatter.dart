import 'package:intl/intl.dart';

/// Utility class for currency formatting
class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'LKR ',
    decimalDigits: 2,
  );

  /// Format a number as currency
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format a number as currency with custom symbol
  static String formatWithSymbol(double amount, String symbol) {
    final customFormat = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return customFormat.format(amount);
  }

  /// Format as compact currency (e.g., $1.2K)
  static String formatCompact(double amount) {
    final compactFormat = NumberFormat.compactCurrency(
      symbol: 'LKR ',
      decimalDigits: 1,
    );
    return compactFormat.format(amount);
  }
}
