import 'package:intl/intl.dart';

/// Display formatting helpers.
class Formatters {
  const Formatters._();

  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final NumberFormat _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());
  static String date(DateTime value) => _date.format(value.toLocal());
  static String currency(num rupees) => _currency.format(rupees);

  /// Masks an Aadhaar number, showing only the last 4 digits.
  /// `123456789012` -> `XXXX XXXX 9012`.
  static String maskAadhaar(String aadhaar) {
    final digits = aadhaar.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 4) return 'XXXX XXXX XXXX';
    final last4 = digits.substring(digits.length - 4);
    return 'XXXX XXXX $last4';
  }

  /// Masks a PAN, showing only the first 2 and last 1 characters.
  static String maskPan(String pan) {
    final p = pan.trim().toUpperCase();
    if (p.length != 10) return p;
    return '${p.substring(0, 2)}XXXXX${p.substring(9)}';
  }

  /// Formats a percentage with a single decimal place.
  static String percent(double value) => '${value.toStringAsFixed(1)}%';
}
