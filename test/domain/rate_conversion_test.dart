import 'dart:math' as math;

import 'package:compound/domain/rate_conversion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nominal', () {
    test('splits the annual rate evenly across the periods', () {
      expect(RateConversion.nominal.monthly(0.12), closeTo(0.01, 1e-12));
      expect(RateConversion.nominal.perPeriod(0.12, 4), closeTo(0.03, 1e-12));
    });

    test('compounds to more than the quoted rate over a year', () {
      final monthly = RateConversion.nominal.monthly(0.12);
      final annual = math.pow(1 + monthly, 12) - 1;
      expect(annual, closeTo(0.126825, 1e-6));
    });

    test('treats a drag exactly like a return', () {
      expect(
        RateConversion.nominal.monthlyDrag(0.012),
        closeTo(RateConversion.nominal.monthly(0.012), 1e-15),
      );
    });
  });

  group('geometric', () {
    test('twelve monthly periods compound to exactly the annual rate', () {
      final monthly = RateConversion.geometric.monthly(0.12);
      final annual = math.pow(1 + monthly, 12) - 1;
      expect(annual, closeTo(0.12, 1e-12));
    });

    test('is lower than nominal for the same quoted rate', () {
      expect(
        RateConversion.geometric.monthly(0.12),
        lessThan(RateConversion.nominal.monthly(0.12)),
      );
    });

    test('handles a negative annual return', () {
      final monthly = RateConversion.geometric.monthly(-0.10);
      expect(monthly, lessThan(0));
      expect(math.pow(1 + monthly, 12) - 1, closeTo(-0.10, 1e-12));
    });
  });

  group('geometric drag', () {
    test('twelve monthly deductions compound to exactly the annual fee', () {
      final monthly = RateConversion.geometric.monthlyDrag(0.01);
      final annual = 1 - math.pow(1 - monthly, 12);
      expect(annual, closeTo(0.01, 1e-12));
    });

    test('differs from converting a fee as if it were a return', () {
      // The bug this method exists to prevent: using monthly() on a fee
      // overstates it, because a drag compounds downward, not upward.
      final asDrag = RateConversion.geometric.monthlyDrag(0.02);
      final asReturn = RateConversion.geometric.monthly(0.02);
      expect(asDrag, isNot(closeTo(asReturn, 1e-9)));
      expect(asDrag, greaterThan(asReturn));
    });

    test('a zero fee converts to zero', () {
      expect(RateConversion.geometric.monthlyDrag(0), 0);
      expect(RateConversion.nominal.monthlyDrag(0), 0);
    });
  });
}
