import 'package:flutter/material.dart';

import '../../domain/models/calculation_result.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../theme/app_theme.dart';
import 'growth_chart.dart';

/// The card that gets rendered to an image and shared.
///
/// A picture rather than a PDF, and not for looks: the PDF package ships
/// Latin fonts only, so a Hebrew or Japanese document would be a page of
/// empty boxes. This is drawn by Flutter with the app's own fonts, so every
/// language and both text directions come out right — and messaging apps
/// show an image inside the conversation instead of as a file to tap.
///
/// Fixed width so the output is the same on every device. Rendered at three
/// times this, which lands around 1200 pixels across.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.result,
    required this.format,
  });

  final CalculationResult result;
  final MoneyFormat format;

  static const double width = 400;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final input = result.input;

    Widget row(String label, String value, Color dot, {bool muted = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: context.texts.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: context.colors.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  value,
                  maxLines: 1,
                  style: context.texts.titleMedium?.copyWith(
                    fontSize: 15,
                    color: muted
                        ? context.colors.onSurface.withValues(alpha: 0.55)
                        : context.colors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: context.colors.surface,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.appTitle.toUpperCase(),
                style: context.texts.labelMedium?.copyWith(
                  color: palette.growth,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: palette.heroGradient,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.youWouldHave(l10n.yearsValue(input.years)),
                      style: context.texts.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        format.moneyRounded(result.netFinalValue),
                        maxLines: 1,
                        style: context.texts.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              row(l10n.startingAmount,
                  format.moneyRounded(input.initialAmount), palette.deposits),
              row(l10n.monthlyContribution,
                  format.moneyRounded(input.monthlyContribution),
                  palette.deposits),
              row(l10n.annualReturn, format.percent(input.annualReturn),
                  palette.growth),
              if (input.hasFee)
                row(l10n.managementFee, format.percent(input.annualManagementFee),
                    palette.fees),
              if (input.hasTax)
                row(l10n.capitalGainsTax,
                    format.percent(input.capitalGainsTaxRate), palette.tax),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),

              row(l10n.totalDeposited, format.money(result.totalDeposited),
                  palette.deposits),
              row(l10n.interestEarned, format.money(result.interestEarned),
                  palette.growth),
              if (result.totalFeesPaid > 0)
                row(l10n.feesPaid, '−${format.money(result.totalFeesPaid)}',
                    palette.fees, muted: true),
              if (result.capitalGainsTax > 0)
                row(l10n.taxPaid, '−${format.money(result.capitalGainsTax)}',
                    palette.tax, muted: true),

              const SizedBox(height: 16),
              Text(l10n.growthOverTime,
                  style: context.texts.titleMedium?.copyWith(fontSize: 15)),
              const SizedBox(height: 12),
              // No fixed height: the chart sizes itself, and pinning it to
              // something smaller than it wants overflows rather than scales.
              GrowthChart(result: result, format: format),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.disclaimer,
                      style: context.texts.bodyMedium?.copyWith(
                        fontSize: 10,
                        height: 1.3,
                        color: context.colors.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.sharedFrom,
                    style: context.texts.labelMedium?.copyWith(
                      fontSize: 10,
                      color: palette.growth,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
