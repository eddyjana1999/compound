import 'package:intl/intl.dart';

import '../../domain/money.dart';

/// The currencies the picker offers.
///
/// The decimal places are never written down here. `intl` already knows that
/// the yen has none and the Kuwaiti dinar has three, and a hand-maintained
/// table would be one more thing to get wrong — so the scale is asked for at
/// runtime and travels with the calculation.
class Currencies {
  Currencies._();

  /// ISO 4217 codes, alphabetical. Wide enough to cover the app's eight
  /// languages several times over without becoming a list nobody can scroll.
  static const List<String> codes = [
    'AED', 'ARS', 'AUD', 'BDT', 'BHD', 'BRL', 'CAD', 'CHF', 'CLP', 'CNY',
    'COP', 'CZK', 'DKK', 'EGP', 'EUR', 'GBP', 'HKD', 'HUF', 'IDR', 'ILS',
    'INR', 'ISK', 'JOD', 'JPY', 'KRW', 'KWD', 'MAD', 'MXN', 'MYR', 'NGN',
    'NOK', 'NZD', 'OMR', 'PHP', 'PKR', 'PLN', 'QAR', 'RON', 'RUB', 'SAR',
    'SEK', 'SGD', 'THB', 'TRY', 'TWD', 'UAH', 'USD', 'VND', 'ZAR',
  ];

  static final Map<String, CurrencySpec> _cache = {};

  /// The spec for [code], with whatever scale `intl` reports for it.
  ///
  /// An unknown code falls back to two decimal places rather than throwing:
  /// a currency stored by a newer build must not stop an older one opening.
  static CurrencySpec specFor(String code) {
    return _cache.putIfAbsent(code, () {
      try {
        final format = NumberFormat.simpleCurrency(name: code);
        return CurrencySpec(
          code: code,
          decimalDigits: format.decimalDigits ?? 2,
        );
      } on Object {
        return CurrencySpec(code: code, decimalDigits: 2);
      }
    });
  }

  /// The short symbol shown beside the code in the picker — `$`, `€`, `₪`.
  /// Falls back to the code itself where a locale has no symbol for it.
  static String symbolFor(String code, String localeName) {
    try {
      return NumberFormat.simpleCurrency(locale: localeName, name: code)
          .currencySymbol;
    } on Object {
      return code;
    }
  }

  /// The picker's order: the currency this device already spends in first,
  /// then everything else alphabetically. Most people never scroll.
  static List<String> orderedFor(String deviceCurrencyCode) {
    final rest = codes.where((c) => c != deviceCurrencyCode).toList();
    return codes.contains(deviceCurrencyCode)
        ? [deviceCurrencyCode, ...rest]
        : codes;
  }

  static bool isSupported(String code) => codes.contains(code);
}
