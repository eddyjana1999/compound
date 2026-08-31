import 'dart:math' as math;

import 'package:compound/ui/formatting/axis_scale.dart';
import 'package:flutter_test/flutter_test.dart';

/// True when [step] is 1, 2, 2.5 or 5 times some power of ten — the only
/// steps a reader can divide in their head.
bool isRoundStep(double step) {
  final magnitude =
      math.pow(10, (math.log(step) / math.ln10).round()).toDouble();
  for (final candidate in [1.0, 2.0, 2.5, 5.0, 10.0]) {
    for (final scale in [magnitude, magnitude / 10, magnitude * 10]) {
      if ((step - candidate * scale).abs() < step * 1e-9) return true;
    }
  }
  return false;
}

void main() {
  group('niceAxis', () {
    test('the old 1.12x headroom bug is gone', () {
      // A million with the previous code gave 280K / 560K / 840K / 1.12M.
      final axis = niceAxis(1000000);
      expect(axis.step, 250000);
      expect(axis.ticks, [0, 250000, 500000, 750000, 1000000, 1250000]);
    });

    test('the ceiling always clears the data', () {
      for (final peak in [1.0, 7.0, 99.0, 1234.0, 987654.0, 4.2e9]) {
        expect(niceAxis(peak).max, greaterThanOrEqualTo(peak),
            reason: 'peak $peak was clipped');
      }
    });

    test('a peak landing exactly on a gridline gets one more step', () {
      // Without this the top stroke is half eaten by the clip rectangle.
      // 1,000,000 divides evenly by its own chosen step of 250,000, so it is
      // the case that needs the extra room; 500,000 does not, because its
      // step comes out at 200,000 and the ceiling already clears it.
      final axis = niceAxis(1000000);
      expect(axis.max, greaterThan(1000000));
      expect(axis.ticks, contains(1000000));

      final noBumpNeeded = niceAxis(500000);
      expect(noBumpNeeded.max, greaterThan(500000));
    });

    test('every step is one a reader can divide in their head', () {
      for (var peak = 1.0; peak < 1e12; peak *= 1.37) {
        final axis = niceAxis(peak);
        expect(isRoundStep(axis.step), isTrue,
            reason: 'peak $peak produced step ${axis.step}');
      }
    });

    test('the ceiling is always a whole number of steps', () {
      for (var peak = 3.0; peak < 1e9; peak *= 2.11) {
        final axis = niceAxis(peak);
        final steps = axis.max / axis.step;
        expect((steps - steps.round()).abs(), lessThan(1e-9),
            reason: 'peak $peak gave ${axis.max} over ${axis.step}');
      }
    });

    test('the gridline count stays readable across every magnitude', () {
      for (var peak = 1.0; peak < 1e12; peak *= 1.19) {
        final count = niceAxis(peak).lineCount;
        expect(count, inInclusiveRange(3, 7),
            reason: 'peak $peak drew $count gridlines');
      }
    });

    test('small currencies still get sensible steps', () {
      // A ¥ or a first-month balance is tiny; the axis must not collapse.
      expect(niceAxis(8).step, greaterThan(0));
      expect(niceAxis(8).max, greaterThanOrEqualTo(8));
    });

    test('nothing to plot yet is drawable rather than a division by zero', () {
      for (final empty in [0.0, -1.0, double.nan, double.infinity]) {
        final axis = niceAxis(empty);
        expect(axis.max, greaterThan(0));
        expect(axis.step, greaterThan(0));
      }
    });
  });
}
