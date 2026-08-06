import 'package:intl/intl.dart';

/// In-house formatting service for numbers, currency, dates, percentages, and receipt text.
class FormatService {
  FormatService._();

  /// Formats amount into currency string with symbol, precision, and thousands separators
  static String formatCurrency(
    num amount, {
    String symbol = '\$',
    int decimals = 2,
    bool symbolPreceded = true,
  }) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimals,
    );
    final formattedNum = formatter.format(amount).trim();
    if (symbolPreceded) {
      return '$symbol $formattedNum';
    } else {
      return '$formattedNum $symbol';
    }
  }

  /// Compact number representation (e.g., 1.5K, 2.3M)
  static String formatCompact(num number) {
    if (number.abs() < 1000) {
      return number.toStringAsFixed(number is int || number % 1 == 0 ? 0 : 1);
    }
    if (number.abs() < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  /// Percentage formatting (e.g., "15.0%", "+12.5%")
  static String formatPercent(num value, {bool includeSign = false, int decimals = 1}) {
    final prefix = (includeSign && value > 0) ? '+' : '';
    return '$prefix${value.toStringAsFixed(decimals)}%';
  }

  /// Date & time formatting
  static String formatDate(DateTime? date, {String format = 'dd MMM yyyy'}) {
    if (date == null) return '-';
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime? date, {String format = 'dd MMM yyyy, hh:mm a'}) {
    if (date == null) return '-';
    return DateFormat(format).format(date);
  }

  static String formatTime(DateTime? date, {String format = 'hh:mm a'}) {
    if (date == null) return '-';
    return DateFormat(format).format(date);
  }

  /// Relative human readable timestamp
  static String timeAgo(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Formats receipt two-column row with dotted or space padding
  static String receiptRow(String left, String right, {int totalWidth = 32, String filler = ' '}) {
    final remaining = totalWidth - left.length - right.length;
    if (remaining <= 0) {
      return '$left $right';
    }
    return '$left${filler * remaining}$right';
  }
}
