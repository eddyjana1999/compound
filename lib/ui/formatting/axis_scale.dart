import 'dart:math' as math;

/// A vertical axis that lands on round numbers.
///
/// The chart used to size its axis as `dataMax * 1.12` and divide that by
/// four, which put the gridlines at 28%, 56%, 84% and 112% of the peak. On a
/// million-shekel projection that reads as ₪280K, ₪560K, ₪840K, ₪1.12M —
/// arbitrary figures that make the reader do arithmetic to place a point.
/// Rounding the *step* instead and letting the ceiling fall where it may is
/// what every financial chart does, and it is why they can be read at a
/// glance.
class AxisScale {
  const AxisScale({required this.max, required this.step});

  /// Top of the axis. Always a whole multiple of [step].
  final double max;

  /// Distance between gridlines. Always 1, 2, 2.5 or 5 times a power of ten.
  final double step;

  /// Number of gridlines drawn, including zero.
  int get lineCount => (max / step).round() + 1;

  /// Every value a label is drawn at, so the caller can measure them.
  List<double> get ticks =>
      [for (var i = 0; i < lineCount; i++) i * step];

  @override
  String toString() => 'AxisScale(max: $max, step: $step)';
}

/// Chooses a step from the 1-2-2.5-5 ladder, then raises the ceiling to the
/// next whole step above [dataMax].
///
/// [targetLines] is a wish, not a guarantee: holding the step round matters
/// more than hitting an exact number of gridlines, so the result may carry
/// one more or one fewer.
AxisScale niceAxis(double dataMax, {int targetLines = 4}) {
  if (!dataMax.isFinite || dataMax <= 0) {
    // Nothing to plot yet. A 0..1 axis keeps the chart drawable instead of
    // dividing by zero somewhere further down.
    return const AxisScale(max: 1, step: 0.25);
  }

  final rawStep = dataMax / targetLines;
  final magnitude =
      math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
  final normalised = rawStep / magnitude;

  final double niceNormalised;
  if (normalised <= 1) {
    niceNormalised = 1;
  } else if (normalised <= 2) {
    niceNormalised = 2;
  } else if (normalised <= 2.5) {
    niceNormalised = 2.5;
  } else if (normalised <= 5) {
    niceNormalised = 5;
  } else {
    niceNormalised = 10;
  }

  final step = niceNormalised * magnitude;
  var max = (dataMax / step).ceil() * step;

  // A peak that lands exactly on the ceiling gets its stroke shaved in half
  // by the clip. One more step costs a little whitespace and keeps the line
  // whole.
  if ((max - dataMax).abs() < step * 1e-9) max += step;

  return AxisScale(max: max, step: step);
}
