import 'package:compound/domain/models/calculation_input.dart';
import 'package:compound/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputProblem tells the reader which field to fix', () {
    test('nothing invested means exactly that, not a missing field', () {
      // Everything readable, but no money going in.
      const input = CalculationInput(
        currency: CurrencySpec(code: 'ILS', decimalDigits: 2),
        initialAmount: 0,
        monthlyContribution: 0,
        annualReturn: 700,
        years: 20,
        annualManagementFee: 0,
        capitalGainsTaxRate: 0,
      );
      expect(input.problem, InputProblem.nothingInvested);
    });

    test('a funded, readable input has no problem at all', () {
      const input = CalculationInput(
        currency: CurrencySpec(code: 'ILS', decimalDigits: 2),
        initialAmount: 1000000,
        monthlyContribution: 100000,
        annualReturn: 1000,
        years: 20,
        annualManagementFee: 50,
        capitalGainsTaxRate: 2500,
      );
      expect(input.problem, isNull);
      expect(input.isValid, isTrue);
    });

    test('incomplete is its own problem, ahead of every other', () {
      // The screen reports this when the horizon or the return cannot be read
      // at all. It used to report nothingInvested instead, which points the
      // reader at the amount fields — the ones they had already filled in.
      expect(InputProblem.values, contains(InputProblem.incomplete));
      expect(
        InputProblem.incomplete,
        isNot(InputProblem.nothingInvested),
        reason: 'an unreadable field is not an unfunded one',
      );
    });
  });
}
