
import 'package:decimal/decimal.dart';


class NanoAmounts {

  // number util:
  static const int maxDecimalDigits = 6; // Max digits after decimal
  static BigInt rawPerNano = BigInt.parse('1000000000000000000000000000000');
  static BigInt rawPerNyano = BigInt.parse('1000000000000000000000000');
  static BigInt rawPerBanano = BigInt.parse('100000000000000000000000000000');

  /// Convert raw to ban and return as BigDecimal
  ///
  /// @param raw 100000000000000000000000000000
  /// @return Decimal value 1.000000000000000000000000000000
  ///
  static Decimal getRawAsDecimal(String? raw, BigInt? rawPerCur) {
    rawPerCur ??= rawPerNano;
    final Decimal amount = Decimal.parse(raw.toString());
    final Decimal result =
        (amount / Decimal.parse(rawPerCur.toString())).toDecimal();
    return result;
  }

  static String truncateDecimal(Decimal input,
      {int digits = maxDecimalDigits}) {
    Decimal bigger = input.shift(digits);
    bigger = bigger.floor(); // chop off the decimal: 1.059 -> 1.05
    bigger = bigger.shift(-digits);
    return bigger.toString();
  }

  /// Return raw as a NANO amount.
  ///
  /// @param raw 100000000000000000000000000000
  /// @returns 1
  ///
  static String getRawAsUsableString(String? raw, BigInt rawPerCur) {
    final String res = truncateDecimal(getRawAsDecimal(raw, rawPerCur),
        digits: maxDecimalDigits + 9);

    if (raw == null ||
        raw == '0' ||
        raw == '00000000000000000000000000000000') {
      return '0';
    }

    if (!res.contains('.')) {
      return res;
    }

    final String numAmount = res.split('.')[0];
    String decAmount = res.split('.')[1];

    // truncate:
    if (decAmount.length > maxDecimalDigits) {
      decAmount = decAmount.substring(0, maxDecimalDigits);
      // remove trailing zeros:
      decAmount =
          decAmount.replaceAllMapped(RegExp(r'0+$'), (Match match) => '');
      if (decAmount.isEmpty) {
        return numAmount;
      }
    }

    return '$numAmount.$decAmount';
  }

  static String getRawAccuracy(String? raw, BigInt rawPerCur) {
    final String rawString = getRawAsUsableString(raw, rawPerCur);
    final String rawDecimalString = getRawAsDecimal(raw, rawPerCur).toString();

    if (raw == null || raw.isEmpty || raw == '0') {
      return '';
    }

    if (rawString != rawDecimalString) {
      return '~';
    }
    return '';
  }

  /// Return readable string amount as raw string
  /// @param amount 1.01
  /// @returns  101000000000000000000000000000
  ///
  static String getAmountAsRaw(String amount, BigInt? rawPerCur) {
    rawPerCur ??= rawPerNano;
    final Decimal asDecimal = Decimal.parse(amount);
    final Decimal rawDecimal = Decimal.parse(rawPerCur.toString());
    return (asDecimal * rawDecimal).toString();
  }
}
