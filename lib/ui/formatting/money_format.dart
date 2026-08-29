import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../domain/money.dart';
import '../../domain/rate.dart';

/// Turns domain integers into text a person reads, in their own locale.
///
/// This is the only layer allowed to know about symbols, separators and
/// digit shapes. The engine never sees any of it.
class MoneyFormat {
  MoneyFormat(this.localeName, this.currency);

  /// Builds a formatter whose currency is the one the locale actually uses,
  /// so a French phone shows euros and a Japanese phone shows yen without
  /// anyone picking anything.
  factory MoneyFormat.forLocale(String localeName) =>
      MoneyFormat(localeName, currencyForLocale(localeName));

  final String localeName;
  final CurrencySpec currency;

  /// The currency a locale spends in, including how many decimal places it
  /// keeps. Falls back to the dollar for a locale intl does not know.
  static CurrencySpec currencyForLocale(String localeName) {
    try {
      final format = NumberFormat.simpleCurrency(locale: localeName);
      return CurrencySpec(
        code: format.currencyName ?? 'USD',
        decimalDigits: format.decimalDigits ?? 2,
      );
    } on Object {
      return const CurrencySpec(code: 'USD', decimalDigits: 2);
    }
  }

  /// `$1,234.56` — the full figure, for headline numbers and breakdown rows.
  String money(MinorUnits minor) {
    final format = NumberFormat.simpleCurrency(
      locale: localeName,
      name: currency.code,
      decimalDigits: currency.decimalDigits,
    );
    return format.format(currency.toMajor(minor));
  }

  /// `$1,234` — the same figure without the minor unit, for places where the
  /// cents are noise rather than information.
  String moneyRounded(MinorUnits minor) {
    final format = NumberFormat.simpleCurrency(
      locale: localeName,
      name: currency.code,
      decimalDigits: 0,
    );
    return format.format(currency.toMajor(minor));
  }

  /// `$1.2M` — for chart axes, where there is room for four characters.
  String moneyCompact(MinorUnits minor) {
    final format = NumberFormat.compactSimpleCurrency(
      locale: localeName,
      name: currency.code,
    );
    return format.format(currency.toMajor(minor));
  }

  /// `1,234.56` — no symbol, for text fields the user types back into.
  String plainAmount(MinorUnits minor) {
    final format = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: currency.decimalDigits,
    );
    return format.format(currency.toMajor(minor));
  }

  /// `7.25%`
  String percent(BasisPoints bps) {
    final format = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: bps % 100 == 0 ? 0 : 2,
    );
    return '${format.format(basisPointsToPercent(bps))}%';
  }

  /// Reads a number the user typed, tolerating their locale's separators and
  /// anything they pasted in around it.
  ///
  /// Returns null for text that is not a number at all, so a caller can tell
  /// "empty" from "zero".
  MinorUnits? parseAmount(String text) {
    final value = _parseNumber(text);
    if (value == null) return null;
    return currency.fromMajor(value);
  }

  /// Reads a percentage the user typed and returns basis points.
  BasisPoints? parsePercent(String text) {
    final value = _parseNumber(text);
    if (value == null) return null;
    return percentToBasisPoints(value);
  }

  /// Reads a number a person typed, in whatever shape they typed it.
  ///
  /// Grouping and decimal marks are not decided by the locale here, because
  /// people type what their keyboard offers rather than what their locale
  /// prescribes. The rule instead: the *last* separator is a decimal point
  /// when one or two digits follow it, and grouping otherwise. That reads
  /// "1,234.56", "1.234,56", "1.234" and "1,5" all correctly.
  num? _parseNumber(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Keep digits, separators and a leading sign. Arabic-Indic and Persian
    // digits map back to ASCII so an Arabic keyboard is understood.
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      final code = char.codeUnitAt(0);
      if (code >= 0x0660 && code <= 0x0669) {
        buffer.write(code - 0x0660);
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.write(code - 0x06F0);
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        buffer.write(char);
      } else if (char == '.' || char == ',' || char == '\u066B' ||
          char == '\u066C' || char == "'" || char == '\u00A0') {
        buffer.write(char == '\u066B' ? ',' : (char == '\u066C' ? ',' : char));
      } else if (char == '-' && buffer.isEmpty) {
        buffer.write('-');
      }
    }

    var cleaned = buffer.toString();
    final negative = cleaned.startsWith('-');
    if (negative) cleaned = cleaned.substring(1);
    if (cleaned.isEmpty) return null;

    final lastSeparator = math.max(
      cleaned.lastIndexOf('.'),
      math.max(cleaned.lastIndexOf(','), cleaned.lastIndexOf("'")),
    );

    String normalised;
    if (lastSeparator == -1) {
      normalised = cleaned;
    } else {
      final fraction = cleaned.substring(lastSeparator + 1);
      final isDecimal = fraction.isNotEmpty &&
          fraction.length <= 2 &&
          !fraction.contains(RegExp(r'[.,\u0027]'));
      final whole = cleaned
          .substring(0, lastSeparator)
          .replaceAll(RegExp(r"[.,\u0027]"), '');
      normalised = isDecimal
          ? '$whole.$fraction'
          : '$whole${fraction.replaceAll(RegExp(r"[.,\u0027]"), '')}';
    }

    if (normalised.isEmpty || normalised == '.') return null;
    final value = num.tryParse(normalised);
    if (value == null) return null;
    return negative ? -value : value;
  }
}
