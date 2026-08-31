import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models/calculation_result.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/axis_scale.dart';
import '../formatting/money_format.dart';
import '../theme/app_theme.dart';

/// Balance against contributions over the whole horizon.
///
/// Two lines rather than one: the gap between them *is* the compounding, and
/// showing only the balance hides the thing the app exists to explain.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.result,
    required this.format,
  });

  final CalculationResult result;
  final MoneyFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final points = result.sampledSeries(_chartPoints);
    final currency = result.currency;

    // X is fractional years, so a sampled point lands where it actually
    // falls rather than being rounded onto a year boundary.
    final balanceSpots = [
      for (final p in points)
        FlSpot(p.month / 12, currency.toMajor(p.balance)),
    ];
    final depositSpots = [
      for (final p in points)
        FlSpot(p.month / 12, currency.toMajor(p.totalDeposited)),
    ];

    // Both lines, not just the balance. When fees or a poor return leave
    // contributions above the balance — exactly the case this app exists to
    // expose — sizing to the balance alone clipped the deposits line off the
    // top and silently removed the comparison.
    final peak = [...balanceSpots, ...depositSpots]
        .map((s) => s.y)
        .fold<double>(0, (a, b) => a > b ? a : b);
    // Round gridlines, not a flat percentage of the peak. See axis_scale.dart
    // for why the old `peak * 1.12 / 4` was unreadable.
    final axis = niceAxis(peak);
    final labels = [
      for (final t in axis.ticks) format.numberCompact(currency.fromMajor(t)),
    ];
    final years = result.input.years;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Legend(color: palette.growth, label: l10n.legendBalance),
            const SizedBox(width: 18),
            _Legend(
              color: palette.deposits,
              label: l10n.legendDeposited,
              dashed: true,
            ),
            const Spacer(),
            // The axis no longer repeats the symbol on every gridline, so it
            // is stated once here instead.
            Text(
              format.currencySymbol,
              style: context.texts.labelMedium?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          // Grows with the reader's text size, or the scaled axis labels
          // collide inside a box that stayed the same height.
          height: 220 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: years.toDouble(),
              minY: 0,
              maxY: axis.max,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: axis.step,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: context.colors.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _labelWidth(context, labels) + 10,
                    interval: axis.step,
                    getTitlesWidget: (value, meta) {
                      if (value < meta.min || value > meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Text(
                          format.numberCompact(currency.fromMajor(value)),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: context.texts.labelMedium?.copyWith(
                            fontSize: 11,
                            color: context.colors.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _yearInterval(years),
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.yearShort(value.round()),
                          style: context.texts.labelMedium?.copyWith(
                            fontSize: 11,
                            color: context.colors.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.colors.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(12),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final isBalance = spot.barIndex == 0;
                      return LineTooltipItem(
                        format.moneyRounded(currency.fromMajor(spot.y)),
                        TextStyle(
                          color: context.colors.onInverseSurface,
                          fontWeight:
                              isBalance ? FontWeight.w700 : FontWeight.w500,
                          fontSize: isBalance ? 15 : 13,
                        ),
                        children: isBalance
                            ? [
                                TextSpan(
                                  text:
                                      '\n${l10n.yearsValue(spot.x.round())}',
                                  style: TextStyle(
                                    color: context.colors.onInverseSurface
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ]
                            : null,
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (barData, indexes) {
                  return indexes.map((_) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: palette.growth.withValues(alpha: 0.4),
                        strokeWidth: 1.5,
                      ),
                      FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 5,
                          color: bar.color ?? palette.growth,
                          strokeWidth: 2.5,
                          strokeColor: context.colors.surface,
                        ),
                      ),
                    );
                  }).toList();
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: balanceSpots,
                  isCurved: false,
                  color: palette.growth,
                  barWidth: 3.2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.growth.withValues(alpha: 0.28),
                        palette.growth.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: depositSpots,
                  isCurved: false,
                  color: palette.deposits,
                  barWidth: 2,
                  dashArray: const [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Enough points that straight segments read as a smooth curve, few enough
  /// that a phone-sized chart is not asked to draw hundreds of them.
  static const int _chartPoints = 140;

  /// Widest gridline label, measured rather than guessed.
  ///
  /// A fixed 52 points fitted `$1.2M` and nothing else: German writes six
  /// digits unabbreviated below a million, Arabic spells out `125 ألف`, and
  /// both were being truncated on the axis.
  static double _labelWidth(BuildContext context, List<String> labels) {
    final style = context.texts.labelMedium?.copyWith(fontSize: 11);
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
    }
    return widest;
  }

  /// Keeps the axis to about five labels whatever the horizon.
  static double _yearInterval(int years) {
    if (years <= 5) return 1;
    if (years <= 12) return 2;
    if (years <= 25) return 5;
    if (years <= 60) return 10;
    return 20;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3.5,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: dashed
              ? Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.7),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}
