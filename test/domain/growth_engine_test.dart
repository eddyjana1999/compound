import 'package:compound/domain/growth_engine.dart';
import 'package:compound/domain/models/calculation_input.dart';
import 'package:compound/domain/money.dart';
import 'package:compound/domain/rate_conversion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = GrowthEngine();
  const usd = CurrencySpec(code: 'USD', decimalDigits: 2);
  const jpy = CurrencySpec(code: 'JPY', decimalDigits: 0);

  CalculationInput input({
    int initial = 0,
    int monthly = 0,
    int annualReturn = 0,
    int years = 1,
    int fee = 0,
    int tax = 0,
    RateConversion conversion = RateConversion.geometric,
    CurrencySpec currency = usd,
  }) {
    return CalculationInput(
      currency: currency,
      initialAmount: initial,
      monthlyContribution: monthly,
      annualReturn: annualReturn,
      years: years,
      annualManagementFee: fee,
      capitalGainsTaxRate: tax,
      rateConversion: conversion,
    );
  }

  group('the series', () {
    test('has one point per month plus the starting point', () {
      final result = engine.calculate(input(initial: 100000, years: 3));
      expect(result.series.length, 37);
      expect(result.series.first.month, 0);
      expect(result.series.last.month, 36);
    });

    test('starts at the initial amount with nothing earned or paid', () {
      final result = engine.calculate(input(initial: 250000, monthly: 10000));
      final start = result.series.first;
      expect(start.balance, 250000);
      expect(start.totalDeposited, 250000);
      expect(start.cumulativeFees, 0);
      expect(start.gain, 0);
    });

    test('deposits never decrease', () {
      final result =
          engine.calculate(input(initial: 100000, monthly: 50000, years: 5));
      for (var i = 1; i < result.series.length; i++) {
        expect(
          result.series[i].totalDeposited,
          greaterThanOrEqualTo(result.series[i - 1].totalDeposited),
        );
      }
    });

    test('is unmodifiable, so a result cannot be edited after the fact', () {
      final result = engine.calculate(input(initial: 100000));
      expect(
        () => result.series.add(result.series.first),
        throwsUnsupportedError,
      );
    });

    test('sampling never exceeds the requested point count', () {
      final result = engine.calculate(input(initial: 100000, years: 40));
      expect(result.series.length, 481);
      final sampled = result.sampledSeries(140);
      expect(sampled.length, 140);
    });

    test('sampling keeps the endpoints, so the chart ends on the answer', () {
      final result = engine.calculate(
          input(initial: 100000, monthly: 5000, annualReturn: 700, years: 30));
      final sampled = result.sampledSeries(140);
      expect(sampled.first.month, 0);
      expect(sampled.last.month, result.series.last.month);
      expect(sampled.last.balance, result.grossFinalValue);
    });

    test('sampling is monotonic in time and never repeats a month', () {
      final result = engine.calculate(input(initial: 100000, years: 40));
      final months = result.sampledSeries(140).map((p) => p.month).toList();
      for (var i = 1; i < months.length; i++) {
        expect(months[i], greaterThan(months[i - 1]));
      }
    });

    test('a short horizon is returned whole rather than padded', () {
      final result = engine.calculate(input(initial: 100000, years: 3));
      expect(result.series.length, 37);
      expect(result.sampledSeries(140), result.series);
    });

    test('yearly series keeps only whole year boundaries', () {
      final result = engine.calculate(input(initial: 100000, years: 10));
      final yearly = result.yearlySeries;
      expect(yearly.length, 11);
      expect(yearly.map((p) => p.month), [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120]);
      expect(yearly.map((p) => p.year), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });
  });

  group('no growth', () {
    test('a zero return leaves a lump sum untouched', () {
      final result = engine.calculate(input(initial: 500000, years: 10));
      expect(result.grossFinalValue, 500000);
      expect(result.interestEarned, 0);
      expect(result.totalDeposited, 500000);
    });

    test('a zero return returns exactly what was paid in', () {
      final result =
          engine.calculate(input(initial: 100000, monthly: 25000, years: 2));
      expect(result.totalDeposited, 100000 + 25000 * 24);
      expect(result.grossFinalValue, result.totalDeposited);
      expect(result.netProfit, 0);
    });
  });

  group('compounding', () {
    test('nominal 12% on a lump sum matches the textbook figure to the cent', () {
      // $10,000 at 1% a month for 12 months == $11,268.25.
      final result = engine.calculate(input(
        initial: 1000000,
        annualReturn: 1200,
        years: 1,
        conversion: RateConversion.nominal,
      ));
      expect(result.grossFinalValue, 1126825);
    });

    test('geometric 12% on a lump sum yields the quoted 12% in a year', () {
      final result = engine.calculate(input(
        initial: 1000000,
        annualReturn: 1200,
        years: 1,
      ));
      expect(result.grossFinalValue, closeTo(1120000, 5));
    });

    test('geometric compounds over multiple years', () {
      // $10,000 at 10% a year for 10 years == $25,937.42.
      final result = engine.calculate(input(
        initial: 1000000,
        annualReturn: 1000,
        years: 10,
      ));
      expect(result.grossFinalValue, closeTo(2593742, 50));
    });

    test('contributions earn a return in the month they are paid', () {
      // One month, one contribution, no starting balance: the contribution
      // itself must grow, which is what start-of-month deposits mean.
      final result = engine.calculate(input(
        monthly: 100000,
        annualReturn: 1200,
        years: 1,
        conversion: RateConversion.nominal,
      ));
      expect(result.series[1].balance, 101000);
      expect(result.grossFinalValue, greaterThan(result.totalDeposited));
    });

    test('a negative return shrinks the balance', () {
      final result = engine.calculate(input(
        initial: 1000000,
        annualReturn: -1000,
        years: 1,
      ));
      expect(result.grossFinalValue, closeTo(900000, 5));
      expect(result.interestEarned, lessThan(0));
      expect(result.netProfit, lessThan(0));
    });
  });

  group('management fee', () {
    test('a fee with no return costs exactly the quoted annual rate', () {
      final result = engine.calculate(input(
        initial: 1000000,
        fee: 100, // 1%
        years: 1,
      ));
      expect(result.grossFinalValue, closeTo(990000, 5));
      expect(result.totalFeesPaid, closeTo(10000, 5));
    });

    test('fees accumulate monthly rather than landing at the end', () {
      final result = engine.calculate(input(
        initial: 1000000,
        fee: 100,
        years: 1,
      ));
      expect(result.series[1].cumulativeFees, greaterThan(0));
      expect(
        result.series[6].cumulativeFees,
        lessThan(result.series[12].cumulativeFees),
      );
    });

    test('a fee reduces the final value against the same run without one', () {
      final withoutFee = engine.calculate(
          input(initial: 1000000, monthly: 50000, annualReturn: 700, years: 20));
      final withFee = engine.calculate(input(
          initial: 1000000,
          monthly: 50000,
          annualReturn: 700,
          years: 20,
          fee: 100));
      expect(withFee.grossFinalValue, lessThan(withoutFee.grossFinalValue));
      expect(withFee.totalDeposited, withoutFee.totalDeposited);
      expect(withFee.totalFeesPaid, greaterThan(0));
      expect(withoutFee.totalFeesPaid, 0);
    });

    test('a fee lowers the taxable gain, because it left the balance', () {
      final withoutFee = engine.calculate(
          input(initial: 1000000, annualReturn: 700, years: 20, tax: 2500));
      final withFee = engine.calculate(input(
          initial: 1000000,
          annualReturn: 700,
          years: 20,
          fee: 100,
          tax: 2500));
      expect(withFee.capitalGainsTax, lessThan(withoutFee.capitalGainsTax));
    });
  });

  group('capital gains tax', () {
    test('is charged on the profit, not on the whole balance', () {
      final result = engine.calculate(input(
        initial: 1000000,
        annualReturn: 1200,
        years: 1,
        tax: 2500,
        conversion: RateConversion.nominal,
      ));
      final profit = 1126825 - 1000000;
      expect(result.capitalGainsTax, (profit * 0.25).round());
      expect(result.netFinalValue, 1126825 - result.capitalGainsTax);
    });

    test('is zero when there is no profit', () {
      final result = engine.calculate(input(
        initial: 1000000,
        annualReturn: -500,
        years: 5,
        tax: 2500,
      ));
      expect(result.netProfit, lessThan(0));
      expect(result.capitalGainsTax, 0);
      expect(result.netFinalValue, result.grossFinalValue);
    });

    test('is zero when the balance exactly equals what was paid in', () {
      final result =
          engine.calculate(input(initial: 1000000, years: 5, tax: 2500));
      expect(result.capitalGainsTax, 0);
    });

    test('a 100% rate takes the entire profit and no more', () {
      final result = engine.calculate(input(
        initial: 1000000,
        annualReturn: 1200,
        years: 1,
        tax: 10000,
      ));
      expect(result.netFinalValue, result.totalDeposited);
    });
  });

  group('the breakdown always adds up', () {
    test('net == deposited + interest - fees - tax, across many inputs', () {
      final cases = <CalculationInput>[
        input(initial: 1000000, monthly: 50000, annualReturn: 700, years: 30),
        input(
            initial: 0,
            monthly: 100000,
            annualReturn: 800,
            years: 15,
            fee: 75,
            tax: 2500),
        input(
            initial: 5000000,
            monthly: 0,
            annualReturn: 400,
            years: 5,
            fee: 150,
            tax: 3300),
        input(initial: 250000, monthly: 1000, annualReturn: -300, years: 8),
        input(
            initial: 1,
            monthly: 1,
            annualReturn: 2000,
            years: 40,
            fee: 25,
            tax: 1500),
        input(
            initial: 1000000,
            monthly: 20000,
            annualReturn: 700,
            years: 20,
            fee: 100,
            tax: 2500,
            conversion: RateConversion.nominal),
      ];

      for (final c in cases) {
        final r = engine.calculate(c);
        expect(
          r.netFinalValue,
          r.totalDeposited +
              r.interestEarned -
              r.totalFeesPaid -
              r.capitalGainsTax,
          reason: 'breakdown must reconcile for $c',
        );
        expect(r.totalCosts, r.totalFeesPaid + r.capitalGainsTax);
        expect(r.netProfit, r.netFinalValue - r.totalDeposited);
      }
    });

    test('the last series point is the gross final value', () {
      final result = engine.calculate(
          input(initial: 300000, monthly: 20000, annualReturn: 600, years: 7));
      expect(result.series.last.balance, result.grossFinalValue);
      expect(result.series.last.totalDeposited, result.totalDeposited);
      expect(result.series.last.cumulativeFees, result.totalFeesPaid);
    });
  });

  group('currencies without a minor unit', () {
    test('yen amounts stay whole all the way through', () {
      final result = engine.calculate(input(
        initial: 1000000,
        monthly: 50000,
        annualReturn: 700,
        years: 10,
        fee: 100,
        tax: 2000,
        currency: jpy,
      ));
      for (final point in result.series) {
        expect(point.balance, isA<int>());
      }
      expect(result.currency, jpy);
      expect(result.netFinalValue, isA<int>());
    });
  });

  group('rejecting inputs it cannot answer', () {
    test('an invalid input throws rather than returning a wrong number', () {
      expect(
        () => engine.calculate(input(initial: -1, years: 5)),
        throwsArgumentError,
      );
    });

    test('nothing invested is not a calculation', () {
      expect(input(initial: 0, monthly: 0).problem, InputProblem.nothingInvested);
    });

    test('a horizon shorter than a year is rejected', () {
      expect(input(initial: 1000, years: 0).problem, InputProblem.horizonTooShort);
    });

    test('a horizon beyond a lifetime is rejected', () {
      expect(input(initial: 1000, years: 101).problem, InputProblem.horizonTooLong);
    });

    test('a total loss return is rejected, it would break compounding', () {
      expect(input(initial: 1000, annualReturn: -10000).problem,
          InputProblem.returnAtOrBelowTotalLoss);
    });

    test('a fee of 100% or more is rejected', () {
      expect(input(initial: 1000, fee: 10000).problem, InputProblem.feeOutOfRange);
      expect(input(initial: 1000, fee: -1).problem, InputProblem.feeOutOfRange);
    });

    test('a tax rate above 100% is rejected', () {
      expect(
          input(initial: 1000, tax: 10001).problem, InputProblem.taxOutOfRange);
    });

    test('a realistic input is valid', () {
      expect(
        input(initial: 1000000, monthly: 50000, annualReturn: 700, years: 30)
            .isValid,
        isTrue,
      );
    });
  });

  group('input value semantics', () {
    test('two identical inputs are equal', () {
      expect(input(initial: 100, annualReturn: 700),
          input(initial: 100, annualReturn: 700));
    });

    test('copyWith changes only what it is given', () {
      final original =
          input(initial: 100000, monthly: 5000, annualReturn: 700, years: 20);
      final changed = original.copyWith(years: 25);
      expect(changed.years, 25);
      expect(changed.initialAmount, original.initialAmount);
      expect(changed.annualReturn, original.annualReturn);
    });

    test('months is years times twelve', () {
      expect(input(initial: 1, years: 30).months, 360);
    });

    test('advanced fields report whether they were filled in', () {
      expect(input(initial: 1).hasFee, isFalse);
      expect(input(initial: 1, fee: 50).hasFee, isTrue);
      expect(input(initial: 1, tax: 2500).hasTax, isTrue);
    });
  });
}
