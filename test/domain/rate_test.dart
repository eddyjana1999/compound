import 'package:compound/domain/rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('percent to basis points', () {
    test('whole percents', () {
      expect(percentToBasisPoints(7), 700);
      expect(percentToBasisPoints(100), 10000);
      expect(percentToBasisPoints(0), 0);
    });

    test('fractional percents survive to two decimal places', () {
      expect(percentToBasisPoints(7.25), 725);
      expect(percentToBasisPoints(0.5), 50);
      expect(percentToBasisPoints(0.07), 7);
    });

    test('a third decimal place rounds, it does not silently truncate', () {
      expect(percentToBasisPoints(7.256), 726);
      expect(percentToBasisPoints(7.254), 725);
    });

    test('negative percents are preserved for market declines', () {
      expect(percentToBasisPoints(-3.5), -350);
    });
  });

  group('basis points out', () {
    test('to the percentage a user reads', () {
      expect(basisPointsToPercent(700), 7);
      expect(basisPointsToPercent(725), 7.25);
    });

    test('to the decimal rate the engine compounds with', () {
      expect(basisPointsToRate(700), 0.07);
      expect(basisPointsToRate(10000), 1.0);
      expect(basisPointsToRate(0), 0.0);
    });
  });

  test('round trip through basis points is lossless at two decimals', () {
    for (final percent in [0, 0.5, 3.75, 7, 12.34, 100]) {
      expect(basisPointsToPercent(percentToBasisPoints(percent)), percent);
    }
  });
}
