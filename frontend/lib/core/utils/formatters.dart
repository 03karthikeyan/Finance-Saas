import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num? amount, {String symbol = '₹'}) {
    if (amount == null) return '$symbol 0';
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

class DateFormatter {
  static String format(dynamic date, {String pattern = 'dd MMM yyyy'}) {
    if (date == null) return '-';
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else {
        dt = DateTime.parse(date.toString());
      }
      return DateFormat(pattern).format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  static String formatDate(dynamic date) => format(date);
}
