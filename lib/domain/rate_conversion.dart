import 'dart:math' as math;

/// How an annual rate quoted by the user is turned into the per-period rate
/// the engine actually compounds with.
///
/// This choice materially changes results over long horizons, so it is an
/// explicit input rather than a buried assumption.
enum RateConversion {
  /// The quoted annual rate is the *effective* annual rate: twelve monthly
  /// periods compound to exactly it. 12% annual => (1.12)^(1/12) - 1 monthly.
  ///
  /// This is the default because it makes "8% a year" mean 8% in a year,
  /// which is what a user typing 8 into a box expects.
  geometric,

  /// The quoted annual rate is a *nominal* rate divided evenly across the
  /// periods. 12% annual => 1% monthly, which compounds to 12.68% a year.
  /// This is the convention most US bank and loan disclosures use.
  nominal,
}

extension RateConversionPeriods on RateConversion {
  /// The per-period rate for [periodsPerYear] compounding periods.
  double perPeriod(double annualRate, int periodsPerYear) {
    assert(periodsPerYear > 0);
    switch (this) {
      case RateConversion.geometric:
        return math.pow(1 + annualRate, 1 / periodsPerYear).toDouble() - 1;
      case RateConversion.nominal:
        return annualRate / periodsPerYear;
    }
  }

  /// The monthly rate for an annual rate.
  double monthly(double annualRate) => perPeriod(annualRate, 12);

  /// The per-period rate for something that *reduces* the balance, such as a
  /// management fee.
  ///
  /// A drag does not convert the same way as a return: twelve monthly
  /// deductions of m compound to 1 - (1 - m)^12, so the geometric monthly
  /// equivalent of an annual fee f is 1 - (1 - f)^(1/12), not
  /// (1 + f)^(1/12) - 1. Getting this wrong overstates the fee.
  double perPeriodDrag(double annualRate, int periodsPerYear) {
    assert(periodsPerYear > 0);
    switch (this) {
      case RateConversion.geometric:
        return 1 - math.pow(1 - annualRate, 1 / periodsPerYear).toDouble();
      case RateConversion.nominal:
        return annualRate / periodsPerYear;
    }
  }

  /// The monthly rate for an annual drag such as a management fee.
  double monthlyDrag(double annualRate) => perPeriodDrag(annualRate, 12);
}
