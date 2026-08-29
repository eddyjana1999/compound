/// Money handling for the domain layer.
///
/// Every monetary value inside `lib/domain/` is an integer number of *minor
/// units*. Major units (dollars, euros, yen) exist only at the display layer.
/// There is no floating point money anywhere in this package.
library;

/// An integer number of minor units.
///
/// This is a documentation alias, not a distinct type: it marks which `int`s
/// carry money so a reader never has to guess at the unit.
typedef MinorUnits = int;

/// How many minor units make up one major unit of a currency, and what the
/// currency is called.
///
/// This is not a constant. USD has 100 cents to the dollar, JPY has no minor
/// unit at all, and KWD has 1000 fils to the dinar. An app that assumes
/// "cents" is an app that cannot be shipped outside the dollar zone, so the
/// scale travels with every calculation rather than being baked into the
/// engine.
class CurrencySpec {
  const CurrencySpec({required this.code, required this.decimalDigits})
      : assert(decimalDigits >= 0 && decimalDigits <= 4);

  /// ISO 4217 code, e.g. `USD`, `JPY`, `ILS`.
  final String code;

  /// Digits after the decimal separator: 2 for USD, 0 for JPY, 3 for KWD.
  final int decimalDigits;

  /// Minor units in one major unit: 100 for USD, 1 for JPY.
  int get minorUnitsPerMajor {
    var scale = 1;
    for (var i = 0; i < decimalDigits; i++) {
      scale *= 10;
    }
    return scale;
  }

  /// Converts an amount coming from the outside world — user input, a
  /// persisted calculation — into minor units.
  MinorUnits fromMajor(num major) => (major * minorUnitsPerMajor).round();

  /// Converts minor units back to major units for display. The only place a
  /// monetary value is allowed to become a double — call this at the display
  /// layer, never inside a calculation.
  double toMajor(MinorUnits minor) => minor / minorUnitsPerMajor;

  @override
  bool operator ==(Object other) =>
      other is CurrencySpec &&
      other.code == code &&
      other.decimalDigits == decimalDigits;

  @override
  int get hashCode => Object.hash(code, decimalDigits);

  @override
  String toString() => 'CurrencySpec($code, $decimalDigits)';
}

/// Applies a decimal rate to a money amount and rounds to the nearest minor
/// unit.
///
/// Rounding happens on every application rather than once at the end, which
/// mirrors how a real account is credited and keeps the running balance an
/// exact integer at all times.
MinorUnits applyRate(MinorUnits amount, double rate) => (amount * rate).round();
