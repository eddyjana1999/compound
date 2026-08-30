import 'dart:math' as math;

import '../money.dart';
import '../rate.dart';
import 'calculation_input.dart';

/// The state of the portfolio at the end of one month.
class GrowthPoint {
  const GrowthPoint({
    required this.month,
    required this.balance,
    required this.totalDeposited,
    required this.cumulativeFees,
  });

  /// 0 is the moment before the first month runs.
  final int month;

  /// Balance after that month's return and fee.
  final MinorUnits balance;

  /// Everything paid in up to and including this month.
  final MinorUnits totalDeposited;

  /// Every management fee charged up to and including this month.
  final MinorUnits cumulativeFees;

  /// Growth on top of contributions at this point. Negative in a drawdown.
  MinorUnits get gain => balance - totalDeposited;

  /// Whole years elapsed, for charting on a yearly axis.
  int get year => month ~/ 12;
}

/// The outcome of one projection.
///
/// The figures satisfy exactly one identity, which the tests assert:
///
///   netFinalValue = totalDeposited + interestEarned - totalFeesPaid - capitalGainsTax
///
/// Every number on the results screen is one of these terms, so the breakdown
/// the user reads always adds up to the headline.
class CalculationResult {
  const CalculationResult({
    required this.input,
    required this.series,
    required this.totalDeposited,
    required this.grossFinalValue,
    required this.totalFeesPaid,
    required this.capitalGainsTax,
  });

  final CalculationInput input;

  /// One point per month, from month 0 to month `input.months` inclusive.
  final List<GrowthPoint> series;

  /// Initial amount plus every monthly contribution.
  final MinorUnits totalDeposited;

  /// Balance after fees but before capital gains tax.
  final MinorUnits grossFinalValue;

  /// Every management fee charged over the whole horizon.
  final MinorUnits totalFeesPaid;

  /// Tax on the final profit. Zero when there is no profit.
  final MinorUnits capitalGainsTax;

  CurrencySpec get currency => input.currency;

  /// What the user actually walks away with.
  MinorUnits get netFinalValue => grossFinalValue - capitalGainsTax;

  /// The return the market generated, before any cost was taken out.
  ///
  /// Derived rather than accumulated so it cannot drift from the balance:
  /// the fees left the balance, so adding them back recovers the gross growth.
  MinorUnits get interestEarned =>
      grossFinalValue - totalDeposited + totalFeesPaid;

  /// Fees and tax together — the total cost of holding the investment.
  MinorUnits get totalCosts => totalFeesPaid + capitalGainsTax;

  /// What the same investment would have been worth with no fee and no tax.
  ///
  /// The counterfactual every other calculator shows as though it were the
  /// answer. Kept next to the real figure so the difference is visible rather
  /// than implied.
  MinorUnits get valueBeforeCosts => netFinalValue + totalCosts;

  /// The share of the untaxed, unfeed total the investor actually keeps,
  /// 0.0 to 1.0. One when nothing was charged.
  double get keptShare {
    final before = valueBeforeCosts;
    if (before <= 0) return 1;
    return netFinalValue / before;
  }

  /// The profit left after every cost.
  MinorUnits get netProfit => netFinalValue - totalDeposited;

  /// Points at whole-year boundaries, including month 0. What the chart plots:
  /// a 40 year horizon is 481 monthly points, which is more than a phone
  /// sized chart can resolve.
  List<GrowthPoint> get yearlySeries =>
      series.where((p) => p.month % 12 == 0).toList(growable: false);

  /// True when costs were modelled at all.
  bool get hasCosts => totalCosts > 0;

  /// The net figure restated in today's money.
  ///
  /// Inflation does not change the projection — the balance really will be
  /// [netFinalValue] — it changes what that balance is worth. A million in
  /// thirty years is the only number most people can picture wrongly, and
  /// this is the correction.
  MinorUnits get netFinalValueInTodaysMoney {
    if (!input.hasInflation) return netFinalValue;
    final factor = math.pow(
      1 + basisPointsToRate(input.annualInflation),
      input.years,
    );
    return (netFinalValue / factor).round();
  }

  /// How much of the final figure inflation quietly removes.
  MinorUnits get purchasingPowerLost =>
      netFinalValue - netFinalValueInTodaysMoney;

  /// The last monthly contribution, after any yearly growth. Equal to the
  /// first when growth is off.
  MinorUnits get finalMonthlyContribution {
    if (!input.hasContributionGrowth) return input.monthlyContribution;
    var contribution = input.monthlyContribution;
    for (var year = 1; year < input.years; year++) {
      contribution += applyRate(
        contribution,
        basisPointsToRate(input.annualContributionGrowth),
      );
    }
    return contribution;
  }

  /// At most [maxPoints] points spread evenly across the whole horizon, always
  /// including the first and the last.
  ///
  /// The chart used to plot one point a year and smooth between them with a
  /// spline. On a curve that is genuinely exponential the spline overshoots
  /// and gets corrected, which showed up as visible kinks in what should be
  /// the smoothest line in the app. Sampling the monthly data finely and
  /// joining it with straight segments is both smoother to look at and more
  /// honest about the underlying numbers.
  List<GrowthPoint> sampledSeries(int maxPoints) {
    assert(maxPoints >= 2);
    if (series.length <= maxPoints) return series;

    final step = (series.length - 1) / (maxPoints - 1);
    final sampled = <GrowthPoint>[
      for (var i = 0; i < maxPoints - 1; i++) series[(i * step).round()],
      series.last,
    ];
    return List.unmodifiable(sampled);
  }
}
