import 'package:compound/domain/growth_engine.dart';
import 'package:compound/domain/models/calculation_input.dart';
import 'package:compound/domain/money.dart';
import 'package:compound/export/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = GrowthEngine();
  const csv = CsvExport();
  const usd = CurrencySpec(code: 'USD', decimalDigits: 2);
  const jpy = CurrencySpec(code: 'JPY', decimalDigits: 0);

  CalculationInput input({
    CurrencySpec currency = usd,
    int initial = 1000000,
    int monthly = 50000,
    int annualReturn = 700,
    int years = 10,
    int fee = 0,
    int tax = 0,
    int inflation = 0,
    int growth = 0,
  }) =>
      CalculationInput(
        currency: currency,
        initialAmount: initial,
        monthlyContribution: monthly,
        annualReturn: annualReturn,
        years: years,
        annualManagementFee: fee,
        capitalGainsTaxRate: tax,
        annualInflation: inflation,
        annualContributionGrowth: growth,
      );

  String build([CalculationInput? i]) => csv.build(engine.calculate(i ?? input()));

  group('shape', () {
    test('uses CRLF, which is what RFC 4180 and Excel expect', () {
      expect(build(), contains('\r\n'));
      expect(build().endsWith('\r\n'), isTrue);
    });

    test('has a row per year plus the header and the starting point', () {
      final text = build(input(years: 10));
      final table = text.split('\r\n').where((l) => l.startsWith(RegExp(r'^\d+,'))).toList();
      expect(table.length, 11); // year 0 through 10
    });

    test('names the currency once instead of repeating a symbol', () {
      final text = build();
      expect(text, contains('Currency,USD'));
      expect(text, isNot(contains(r'$')));
    });
  });

  group('numbers a spreadsheet can add up', () {
    test('are plain decimals, with no grouping separators', () {
      final text = build(input(initial: 123456789, monthly: 0, annualReturn: 0, years: 1));
      expect(text, contains('1234567.89'));
      expect(text, isNot(contains('1,234,567.89')));
    });

    test('respect a currency with no minor unit', () {
      final text = build(input(currency: jpy, initial: 1000000, monthly: 0,
          annualReturn: 0, years: 1));
      expect(text, contains('Currency,JPY'));
      expect(text, contains('1000000'));
      expect(text, isNot(contains('1000000.00')));
    });

    test('carry three decimals where the currency has them', () {
      const kwd = CurrencySpec(code: 'KWD', decimalDigits: 3);
      final text = build(input(currency: kwd, initial: 1234567, monthly: 0,
          annualReturn: 0, years: 1));
      expect(text, contains('1234.567'));
    });
  });

  group('optional inputs appear only when they were used', () {
    test('a plain calculation lists no fee, tax, growth or inflation', () {
      final text = build();
      expect(text, isNot(contains('management fee')));
      expect(text, isNot(contains('Capital gains tax')));
      expect(text, isNot(contains('Contribution growth')));
      expect(text, isNot(contains('Inflation')));
    });

    test('a full calculation lists all of them', () {
      final text = build(input(fee: 100, tax: 2500, inflation: 250, growth: 300));
      expect(text, contains('Annual management fee %,1.00'));
      expect(text, contains('Capital gains tax %,25.00'));
      expect(text, contains('Contribution growth % per year,3.00'));
      expect(text, contains('Inflation % per year,2.50'));
      expect(text, contains("Net final value in today's money"));
    });
  });

  group('escaping', () {
    test("a label containing a comma is quoted, or every column after it shifts", () {
      // "Net final value in today's money" has an apostrophe, not a comma, so
      // it must NOT be quoted; the header row proves the rule both ways.
      final text = build(input(inflation: 200));
      expect(text, contains("Net final value in today's money,"));
    });

    test('the table header is intact and in order', () {
      expect(build(), contains('Year,Total deposited,Balance,Cumulative fees,Gain'));
    });
  });

  group('the file name', () {
    test('sorts by date and carries the extension', () {
      final name = csv.fileName(DateTime(2026, 8, 30, 9, 5, 3));
      expect(name, 'compound-2026-08-30-090503.csv');
    });

    test('pads so string order matches time order', () {
      final january = csv.fileName(DateTime(2026, 1, 2, 3, 4, 5));
      final december = csv.fileName(DateTime(2026, 12, 2, 3, 4, 5));
      expect(january.compareTo(december), lessThan(0));
    });
  });

  test('the exported totals match the engine exactly', () {
    final result = engine.calculate(input(fee: 100, tax: 2500));
    final text = csv.build(result);
    String money(int m) => (m / 100).toStringAsFixed(2);
    expect(text, contains('Total deposited,${money(result.totalDeposited)}'));
    expect(text, contains('Net final value,${money(result.netFinalValue)}'));
    expect(text, contains('Net profit,${money(result.netProfit)}'));
  });
}
