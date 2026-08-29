import 'package:compound/domain/money.dart';
import 'package:compound/ui/formatting/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const usd = CurrencySpec(code: 'USD', decimalDigits: 2);
  const jpy = CurrencySpec(code: 'JPY', decimalDigits: 0);

  group('currency for locale', () {
    test('picks the currency the locale actually spends in', () {
      expect(MoneyFormat.currencyForLocale('en_US').code, 'USD');
      expect(MoneyFormat.currencyForLocale('de_DE').code, 'EUR');
      expect(MoneyFormat.currencyForLocale('ja_JP').code, 'JPY');
      expect(MoneyFormat.currencyForLocale('he_IL').code, 'ILS');
    });

    test('knows yen has no minor unit', () {
      expect(MoneyFormat.currencyForLocale('ja_JP').decimalDigits, 0);
      expect(MoneyFormat.currencyForLocale('en_US').decimalDigits, 2);
    });

    test('an unknown locale falls back rather than throwing', () {
      expect(() => MoneyFormat.currencyForLocale('zz_ZZ'), returnsNormally);
    });
  });

  group('formatting', () {
    test('shows the full figure with grouping', () {
      final f = MoneyFormat('en_US', usd);
      expect(f.money(123456), r'$1,234.56');
    });

    test('drops the minor unit when asked', () {
      final f = MoneyFormat('en_US', usd);
      expect(f.moneyRounded(123456), r'$1,235');
    });

    test('never shows a decimal point for yen', () {
      final f = MoneyFormat('ja_JP', jpy);
      expect(f.money(1234567), isNot(contains('.')));
    });

    test('percentages drop trailing zeros on whole numbers', () {
      final f = MoneyFormat('en_US', usd);
      expect(f.percent(700), '7%');
      expect(f.percent(725), '7.25%');
    });
  });

  group('parsing what people actually type', () {
    final f = MoneyFormat('en_US', usd);

    test('a plain integer', () {
      expect(f.parseAmount('1000'), 100000);
    });

    test('English grouping and decimals', () {
      expect(f.parseAmount('1,234.56'), 123456);
    });

    test('European grouping and decimals', () {
      expect(f.parseAmount('1.234,56'), 123456);
    });

    test('Swiss apostrophe grouping', () {
      expect(f.parseAmount("1'234.56"), 123456);
    });

    test('a lone separator with three digits is grouping, not a fraction', () {
      expect(f.parseAmount('1.234'), 123400);
      expect(f.parseAmount('1,234'), 123400);
    });

    test('a lone separator with one or two digits is a fraction', () {
      expect(f.parseAmount('1.5'), 150);
      expect(f.parseAmount('1,5'), 150);
      expect(f.parseAmount('10.25'), 1025);
    });

    test('currency symbols and spaces are ignored', () {
      expect(f.parseAmount(r'  $ 1,000.00 '), 100000);
      expect(f.parseAmount('1 000'), 100000);
    });

    test('Arabic-Indic digits are understood', () {
      expect(f.parseAmount('١٢٣٤'), 123400);
    });

    test('empty and nonsense return null, not zero', () {
      expect(f.parseAmount(''), isNull);
      expect(f.parseAmount('   '), isNull);
      expect(f.parseAmount('abc'), isNull);
      expect(f.parseAmount('-'), isNull);
    });

    test('zero parses as zero, distinct from empty', () {
      expect(f.parseAmount('0'), 0);
    });

    test('negatives are preserved', () {
      expect(f.parsePercent('-3.5'), -350);
    });

    test('percentages become basis points', () {
      expect(f.parsePercent('7'), 700);
      expect(f.parsePercent('7.25'), 725);
      expect(f.parsePercent('0.5'), 50);
    });

    test('a yen amount never gains a fractional part', () {
      final yen = MoneyFormat('ja_JP', jpy);
      expect(yen.parseAmount('1,000,000'), 1000000);
    });
  });

  test('format then parse returns the original amount', () {
    final f = MoneyFormat('en_US', usd);
    for (final amount in [0, 1, 999, 123456, 98765432]) {
      expect(f.parseAmount(f.plainAmount(amount)), amount);
    }
  });
}
