import 'models/calculation_input.dart';
import 'models/calculation_result.dart';
import 'money.dart';
import 'rate.dart';
import 'rate_conversion.dart';

/// Projects a portfolio forward month by month and reports what is left after
/// management fees and capital gains tax.
///
/// Order of operations inside each month, which is the part that changes the
/// answer and so is stated rather than implied:
///
///   1. the monthly contribution is added at the start of the month, so it
///      earns that month's return;
///   2. the return is applied to the post-contribution balance;
///   3. the management fee is applied to the post-return balance.
///
/// The fee is charged every month against the running balance, never as a
/// single deduction at the end. Because it comes out of the balance it also
/// reduces the taxable gain — which mirrors a fund whose unit price already
/// carries the fee.
///
/// Capital gains tax is applied once, to the profit at the end of the
/// horizon. That models a buy-and-hold investor who sells on the last day,
/// which is the only assumption that can be made without knowing a
/// jurisdiction's rules on rebalancing, allowances and carry-forward losses.
class GrowthEngine {
  const GrowthEngine();

  CalculationResult calculate(CalculationInput input) {
    final problem = input.problem;
    if (problem != null) {
      throw ArgumentError('Cannot calculate an invalid input: ${problem.name}');
    }

    final monthlyReturn = input.rateConversion
        .monthly(basisPointsToRate(input.annualReturn));
    final monthlyFee = input.rateConversion
        .monthlyDrag(basisPointsToRate(input.annualManagementFee));

    MinorUnits balance = input.initialAmount;
    MinorUnits totalDeposited = input.initialAmount;
    MinorUnits cumulativeFees = 0;

    // Grows once a year rather than every month, because that is how a raise
    // actually arrives. Carried as a running integer and compounded on the
    // year boundary, so it rounds the same way the balance does.
    MinorUnits contribution = input.monthlyContribution;
    final contributionGrowth =
        basisPointsToRate(input.annualContributionGrowth);

    final series = <GrowthPoint>[
      GrowthPoint(
        month: 0,
        balance: balance,
        totalDeposited: totalDeposited,
        cumulativeFees: 0,
      ),
    ];

    for (var month = 1; month <= input.months; month++) {
      // At the start of each year after the first, the deposit steps up.
      if (contributionGrowth > 0 && month > 1 && (month - 1) % 12 == 0) {
        contribution += applyRate(contribution, contributionGrowth);
      }

      balance += contribution;
      totalDeposited += contribution;

      balance += applyRate(balance, monthlyReturn);

      final fee = applyRate(balance, monthlyFee);
      balance -= fee;
      cumulativeFees += fee;

      series.add(
        GrowthPoint(
          month: month,
          balance: balance,
          totalDeposited: totalDeposited,
          cumulativeFees: cumulativeFees,
        ),
      );
    }

    // Only a profit is taxable. A loss produces no refund here — modelling
    // loss offsets would need a jurisdiction's rules, which this app does
    // not claim to know.
    final gain = balance - totalDeposited;
    final tax = gain > 0
        ? applyRate(gain, basisPointsToRate(input.capitalGainsTaxRate))
        : 0;

    return CalculationResult(
      input: input,
      series: List.unmodifiable(series),
      totalDeposited: totalDeposited,
      grossFinalValue: balance,
      totalFeesPaid: cumulativeFees,
      capitalGainsTax: tax,
    );
  }
}
