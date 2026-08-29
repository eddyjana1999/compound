import '../money.dart';
import '../rate.dart';
import '../rate_conversion.dart';

/// Everything the engine needs to project a portfolio forward.
///
/// All money is minor units, all rates are basis points. Nothing here is a
/// percentage-shaped double, so an input built from user text and an input
/// rebuilt from storage are comparable with `==`.
class CalculationInput {
  const CalculationInput({
    required this.currency,
    required this.initialAmount,
    required this.monthlyContribution,
    required this.annualReturn,
    required this.years,
    this.annualManagementFee = 0,
    this.capitalGainsTaxRate = 0,
    this.rateConversion = RateConversion.geometric,
  });

  final CurrencySpec currency;

  /// Starting amount, in minor units.
  final MinorUnits initialAmount;

  /// Added at the start of every month, in minor units.
  final MinorUnits monthlyContribution;

  /// Expected annual return. 700 == 7%. May be negative.
  final BasisPoints annualReturn;

  /// Time horizon in whole years.
  final int years;

  /// Optional annual management fee, charged monthly against the balance.
  final BasisPoints annualManagementFee;

  /// Optional capital gains tax rate, applied once to the final profit.
  final BasisPoints capitalGainsTaxRate;

  final RateConversion rateConversion;

  int get months => years * 12;

  bool get hasFee => annualManagementFee > 0;

  bool get hasTax => capitalGainsTaxRate > 0;

  /// Why this input cannot be calculated, or null if it can.
  ///
  /// Returns a stable key rather than a sentence: the message the user reads
  /// is chosen by the localisation layer, which the domain knows nothing
  /// about.
  InputProblem? get problem {
    if (initialAmount < 0) return InputProblem.negativeInitialAmount;
    if (monthlyContribution < 0) return InputProblem.negativeContribution;
    if (years < 1) return InputProblem.horizonTooShort;
    if (years > 100) return InputProblem.horizonTooLong;
    if (annualReturn <= -basisPointsPerUnit) {
      return InputProblem.returnAtOrBelowTotalLoss;
    }
    if (annualManagementFee < 0 ||
        annualManagementFee >= basisPointsPerUnit) {
      return InputProblem.feeOutOfRange;
    }
    if (capitalGainsTaxRate < 0 ||
        capitalGainsTaxRate > basisPointsPerUnit) {
      return InputProblem.taxOutOfRange;
    }
    if (initialAmount == 0 && monthlyContribution == 0) {
      return InputProblem.nothingInvested;
    }
    return null;
  }

  bool get isValid => problem == null;

  CalculationInput copyWith({
    CurrencySpec? currency,
    MinorUnits? initialAmount,
    MinorUnits? monthlyContribution,
    BasisPoints? annualReturn,
    int? years,
    BasisPoints? annualManagementFee,
    BasisPoints? capitalGainsTaxRate,
    RateConversion? rateConversion,
  }) {
    return CalculationInput(
      currency: currency ?? this.currency,
      initialAmount: initialAmount ?? this.initialAmount,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      annualReturn: annualReturn ?? this.annualReturn,
      years: years ?? this.years,
      annualManagementFee: annualManagementFee ?? this.annualManagementFee,
      capitalGainsTaxRate: capitalGainsTaxRate ?? this.capitalGainsTaxRate,
      rateConversion: rateConversion ?? this.rateConversion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CalculationInput &&
      other.currency == currency &&
      other.initialAmount == initialAmount &&
      other.monthlyContribution == monthlyContribution &&
      other.annualReturn == annualReturn &&
      other.years == years &&
      other.annualManagementFee == annualManagementFee &&
      other.capitalGainsTaxRate == capitalGainsTaxRate &&
      other.rateConversion == rateConversion;

  @override
  int get hashCode => Object.hash(
        currency,
        initialAmount,
        monthlyContribution,
        annualReturn,
        years,
        annualManagementFee,
        capitalGainsTaxRate,
        rateConversion,
      );
}

/// The reasons an input is not calculable.
enum InputProblem {
  negativeInitialAmount,
  negativeContribution,
  horizonTooShort,
  horizonTooLong,
  returnAtOrBelowTotalLoss,
  feeOutOfRange,
  taxOutOfRange,
  nothingInvested,
}
