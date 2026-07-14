/// Currency helpers for the driver app.
///
/// The backend always sends money as an integer in minor units (pence).
/// These helpers convert to a GBP display string. Never do float maths on
/// pence before formatting - keep integer pence until the final divide.
abstract class Currency {
  /// Format an integer pence value as a GBP string, e.g. 4500 -> "£45.00".
  static String formatPence(int pence, {String symbol = '£'}) {
    final negative = pence < 0;
    final abs = pence.abs();
    final pounds = abs ~/ 100;
    final remainder = abs % 100;
    final formatted =
        '$symbol${_withThousands(pounds)}.${remainder.toString().padLeft(2, '0')}';
    return negative ? '-$formatted' : formatted;
  }

  /// Format pence with no decimal places when whole, e.g. 4500 -> "£45".
  static String formatPenceCompact(int pence, {String symbol = '£'}) {
    if (pence % 100 == 0) {
      return '$symbol${_withThousands(pence ~/ 100)}';
    }
    return formatPence(pence, symbol: symbol);
  }

  static String _withThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
