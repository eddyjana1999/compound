import 'package:compound/ui/formatting/currencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the catalogue', () {
    test('is alphabetical and free of duplicates', () {
      final sorted = [...Currencies.codes]..sort();
      expect(Currencies.codes, sorted);
      expect(Currencies.codes.toSet().length, Currencies.codes.length);
    });

    test('covers the currencies of the languages the app ships', () {
      // One per supported locale: en, es/fr/de, zh, ja, ar, he.
      for (final code in ['USD', 'EUR', 'CNY', 'JPY', 'AED', 'ILS']) {
        expect(Currencies.isSupported(code), isTrue, reason: code);
      }
    });

    test('every code is a three letter ISO 4217 code', () {
      for (final code in Currencies.codes) {
        expect(code, matches(RegExp(r'^[A-Z]{3}$')), reason: code);
      }
    });
  });

  group('scale comes from intl, not from a hand written table', () {
    test('two decimal currencies', () {
      expect(Currencies.specFor('USD').decimalDigits, 2);
      expect(Currencies.specFor('EUR').decimalDigits, 2);
      expect(Currencies.specFor('ILS').decimalDigits, 2);
    });

    test('currencies with no minor unit', () {
      expect(Currencies.specFor('JPY').decimalDigits, 0);
      expect(Currencies.specFor('KRW').decimalDigits, 0);
      expect(Currencies.specFor('ISK').decimalDigits, 0);
    });

    test('currencies with three decimal places', () {
      expect(Currencies.specFor('KWD').decimalDigits, 3);
      expect(Currencies.specFor('BHD').decimalDigits, 3);
      expect(Currencies.specFor('JOD').decimalDigits, 3);
    });

    test('the spec carries the code it was asked for', () {
      expect(Currencies.specFor('GBP').code, 'GBP');
    });

    test('an unknown code falls back instead of throwing', () {
      final spec = Currencies.specFor('ZZZ');
      expect(spec.code, 'ZZZ');
      expect(spec.decimalDigits, 2);
    });

    test('repeated lookups return the identical instance', () {
      expect(identical(Currencies.specFor('USD'), Currencies.specFor('USD')),
          isTrue);
    });
  });

  group('symbols', () {
    test('are the ones a reader expects', () {
      expect(Currencies.symbolFor('USD', 'en_US'), r'$');
      expect(Currencies.symbolFor('EUR', 'de_DE'), '€');
      expect(Currencies.symbolFor('ILS', 'he'), '₪');
    });

    test('an unknown code degrades to the code itself', () {
      expect(Currencies.symbolFor('ZZZ', 'en_US'), 'ZZZ');
    });
  });

  group('ordering', () {
    test('puts the device currency first', () {
      final ordered = Currencies.orderedFor('ILS');
      expect(ordered.first, 'ILS');
      expect(ordered.length, Currencies.codes.length);
      expect(ordered.toSet().length, ordered.length);
    });

    test('leaves the list alone for a currency it does not carry', () {
      expect(Currencies.orderedFor('XYZ'), Currencies.codes);
    });
  });
}
