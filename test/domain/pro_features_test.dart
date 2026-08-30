import 'package:compound/domain/growth_engine.dart';
import 'package:compound/domain/models/calculation_input.dart';
import 'package:compound/domain/money.dart';
import 'package:compound/domain/rate_conversion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = GrowthEngine();
  const usd = CurrencySpec(code: 'USD', decimalDigits: 2);

  CalculationInput input({
    int initial = 0,
    int monthly = 0,
    int annualReturn = 0,
    int years = 1,
    int inflation = 0,
    int growth = 0,
    int tax = 0,
  }) =>
      CalculationInput(
        currency: usd,
        initialAmount: initial,
        monthlyContribution: monthly,
        annualReturn: annualReturn,
        years: years,
        annualInflation: inflation,
        annualContributionGrowth: growth,
        capitalGainsTaxRate: tax,
        rateConversion: RateConversion.geometric,
      );

  group('a contribution that grows every year', () {
    test('is unchanged when growth is off', () {
      final flat = engine.calculate(input(monthly: 100000, years: 10));
      expect(flat.totalDeposited, 100000 * 120);
      expect(flat.finalMonthlyContribution, 100000);
    });

    test('steps up once a year, not every month', () {
      // 10% a year on 1,000: the first twelve deposits are all 1,000, the
      // thirteenth is 1,100. If this ever grows monthly the second point
      // stops being equal to the first.
      final r = engine.calculate(input(monthly: 100000, years: 3, growth: 1000));
      final month1 = r.series[1].totalDeposited;
      final month12 = r.series[12].totalDeposited;
      final month13 = r.series[13].totalDeposited;
      expect(month12 - r.series[11].totalDeposited, 100000);
      expect(month13 - month12, 110000);
      expect(month1, 100000);
    });

    test('compounds year on year', () {
      // 1,000 growing 10% a year for 3 years: 1,000 / 1,100 / 1,210.
      final r = engine.calculate(input(monthly: 100000, years: 3, growth: 1000));
      expect(r.totalDeposited, 100000 * 12 + 110000 * 12 + 121000 * 12);
      expect(r.finalMonthlyContribution, 121000);
    });

    test('deposits more than a flat contribution over the same horizon', () {
      final flat = engine.calculate(
          input(monthly: 50000, annualReturn: 700, years: 20));
      final rising = engine.calculate(
          input(monthly: 50000, annualReturn: 700, years: 20, growth: 300));
      expect(rising.totalDeposited, greaterThan(flat.totalDeposited));
      expect(rising.grossFinalValue, greaterThan(flat.grossFinalValue));
    });

    test('zero growth is exactly the same as no growth', () {
      final a = engine.calculate(input(monthly: 50000, annualReturn: 700, years: 15));
      final b = engine.calculate(
          input(monthly: 50000, annualReturn: 700, years: 15, growth: 0));
      expect(a.totalDeposited, b.totalDeposited);
      expect(a.grossFinalValue, b.grossFinalValue);
    });

    test('a one year horizon never applies the increase', () {
      final r = engine.calculate(input(monthly: 100000, years: 1, growth: 5000));
      expect(r.totalDeposited, 100000 * 12);
      expect(r.finalMonthlyContribution, 100000);
    });

    test('the breakdown still reconciles', () {
      final r = engine.calculate(input(
          initial: 500000,
          monthly: 50000,
          annualReturn: 800,
          years: 25,
          growth: 400,
          tax: 2500));
      expect(
        r.netFinalValue,
        r.totalDeposited + r.interestEarned - r.totalFeesPaid - r.capitalGainsTax,
      );
    });
  });

  group('inflation', () {
    test('leaves the projection alone — it only restates it', () {
      final without = engine.calculate(
          input(initial: 1000000, annualReturn: 700, years: 20));
      final with_ = engine.calculate(input(
          initial: 1000000, annualReturn: 700, years: 20, inflation: 300));
      expect(with_.grossFinalValue, without.grossFinalValue);
      expect(with_.netFinalValue, without.netFinalValue);
    });

    test('is a no-op when it is not set', () {
      final r = engine.calculate(
          input(initial: 1000000, annualReturn: 700, years: 20));
      expect(r.netFinalValueInTodaysMoney, r.netFinalValue);
      expect(r.purchasingPowerLost, 0);
    });

    test('discounts the final figure by the textbook amount', () {
      // No growth, so the balance stays 100,000. At 3% for 10 years that is
      // worth 100,000 / 1.03^10 = 74,409.39 in today's money.
      final r = engine.calculate(input(initial: 10000000, years: 10, inflation: 300));
      expect(r.netFinalValue, 10000000);
      expect(r.netFinalValueInTodaysMoney, closeTo(7440939, 2));
    });

    test('the loss is the difference between the two figures', () {
      final r = engine.calculate(input(
          initial: 1000000, monthly: 50000, annualReturn: 700, years: 30, inflation: 250));
      expect(r.purchasingPowerLost,
          r.netFinalValue - r.netFinalValueInTodaysMoney);
      expect(r.purchasingPowerLost, greaterThan(0));
    });

    test('a higher rate leaves less', () {
      final low = engine.calculate(
          input(initial: 10000000, years: 20, inflation: 200));
      final high = engine.calculate(
          input(initial: 10000000, years: 20, inflation: 500));
      expect(high.netFinalValueInTodaysMoney,
          lessThan(low.netFinalValueInTodaysMoney));
    });

    test('applies after tax, not before', () {
      final r = engine.calculate(input(
          initial: 1000000, annualReturn: 1000, years: 10, tax: 2500, inflation: 300));
      expect(r.netFinalValueInTodaysMoney, lessThan(r.netFinalValue));
      expect(r.netFinalValue, r.grossFinalValue - r.capitalGainsTax);
    });
  });

  group('what the costs took', () {
    test('with no costs, nothing was taken and everything is kept', () {
      final r = engine.calculate(
          input(initial: 1000000, annualReturn: 700, years: 20));
      expect(r.totalCosts, 0);
      expect(r.valueBeforeCosts, r.netFinalValue);
      expect(r.keptShare, 1.0);
    });

    test('the two figures differ by exactly the fees plus the tax', () {
      final r = engine.calculate(input(
          initial: 2500000, monthly: 150000, annualReturn: 800, years: 30,
          tax: 2500));
      expect(r.valueBeforeCosts - r.netFinalValue, r.totalCosts);
    });

    test('the kept share is between nothing and everything', () {
      final r = engine.calculate(input(
          initial: 1000000, monthly: 50000, annualReturn: 800, years: 30,
          tax: 2500));
      expect(r.keptShare, greaterThan(0));
      expect(r.keptShare, lessThan(1));
    });

    test('a bigger tax leaves a smaller share', () {
      final light = engine.calculate(
          input(initial: 1000000, annualReturn: 800, years: 20, tax: 1000));
      final heavy = engine.calculate(
          input(initial: 1000000, annualReturn: 800, years: 20, tax: 4000));
      expect(heavy.keptShare, lessThan(light.keptShare));
    });

    test('a loss cannot produce a nonsense share', () {
      final r = engine.calculate(
          input(initial: 1000000, annualReturn: -800, years: 10, tax: 2500));
      expect(r.keptShare, 1.0);
    });
  });

  group('rejecting values it cannot model', () {
    test('inflation at or above total devaluation', () {
      expect(input(initial: 1000, inflation: 10000).problem,
          InputProblem.inflationOutOfRange);
      expect(input(initial: 1000, inflation: -1).problem,
          InputProblem.inflationOutOfRange);
    });

    test('contribution growth beyond doubling every year', () {
      expect(input(initial: 1000, growth: 10001).problem,
          InputProblem.contributionGrowthOutOfRange);
      expect(input(initial: 1000, growth: -1).problem,
          InputProblem.contributionGrowthOutOfRange);
    });

    test('realistic pro inputs are valid', () {
      expect(
        input(initial: 1000000, monthly: 50000, annualReturn: 700, years: 30,
              inflation: 250, growth: 300).isValid,
        isTrue,
      );
    });
  });
}
