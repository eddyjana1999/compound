import 'package:compound/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const usd = CurrencySpec(code: 'USD', decimalDigits: 2);
  const jpy = CurrencySpec(code: 'JPY', decimalDigits: 0);
  const kwd = CurrencySpec(code: 'KWD', decimalDigits: 3);

  group('CurrencySpec scale', () {
    test('a two decimal currency has 100 minor units to the major', () {
      expect(usd.minorUnitsPerMajor, 100);
    });

    test('a zero decimal currency has no minor unit', () {
      expect(jpy.minorUnitsPerMajor, 1);
    });

    test('a three decimal currency has 1000 minor units to the major', () {
      expect(kwd.minorUnitsPerMajor, 1000);
    });
  });

  group('conversion in and out', () {
    test('major to minor rounds to the nearest minor unit', () {
      expect(usd.fromMajor(10), 1000);
      expect(usd.fromMajor(10.5), 1050);
      expect(usd.fromMajor(10.555), 1056);
      expect(usd.fromMajor(10.554), 1055);
    });

    test('yen never grows a fractional part', () {
      expect(jpy.fromMajor(1000000), 1000000);
      expect(jpy.fromMajor(1000.4), 1000);
      expect(jpy.fromMajor(1000.5), 1001);
    });

    test('minor to major is the exact inverse for representable amounts', () {
      expect(usd.toMajor(1050), 10.5);
      expect(jpy.toMajor(1000000), 1000000);
      expect(kwd.toMajor(1500), 1.5);
    });
  });

  group('applyRate', () {
    test('rounds to the nearest minor unit', () {
      expect(applyRate(1000, 0.1), 100);
      expect(applyRate(1005, 0.1), 101); // 100.5 rounds up
      expect(applyRate(1004, 0.1), 100); // 100.4 rounds down
    });

    test('a zero rate moves nothing', () {
      expect(applyRate(123456, 0), 0);
    });

    test('a negative rate returns a negative amount', () {
      expect(applyRate(1000, -0.1), -100);
    });

    test('never returns a fraction, however awkward the rate', () {
      final result = applyRate(1234567, 0.0094888);
      expect(result, isA<int>());
      expect(result, 11715);
    });
  });

  group('equality', () {
    test('two specs for the same currency are equal', () {
      expect(usd, const CurrencySpec(code: 'USD', decimalDigits: 2));
      expect(usd.hashCode,
          const CurrencySpec(code: 'USD', decimalDigits: 2).hashCode);
    });

    test('currencies with different scales are not equal', () {
      expect(usd == jpy, isFalse);
    });
  });
}
