import 'package:flutter/material.dart';

import '../../domain/models/calculation_result.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Where the money came from and where it went.
///
/// Every row is a term in the identity the engine guarantees, so the column
/// always reconciles to the headline above it.
class BreakdownCard extends StatelessWidget {
  const BreakdownCard({
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

    return AppCard(
      child: Column(
        children: [
          _ProportionBar(result: result),
          const SizedBox(height: 22),
          _Row(
            color: palette.deposits,
            label: l10n.totalDeposited,
            value: format.money(result.totalDeposited),
          ),
          _Row(
            color: palette.growth,
            label: l10n.interestEarned,
            value: format.money(result.interestEarned),
          ),
          if (result.totalFeesPaid > 0)
            _Row(
              color: palette.fees,
              label: l10n.feesPaid,
              value: '−${format.money(result.totalFeesPaid)}',
              muted: true,
            ),
          if (result.capitalGainsTax > 0)
            _Row(
              color: palette.tax,
              label: l10n.taxPaid,
              value: '−${format.money(result.capitalGainsTax)}',
              muted: true,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _Row(
            label: l10n.netProfit,
            value: format.money(result.netProfit),
            emphasised: true,
          ),
        ],
      ),
    );
  }
}

/// A single stacked bar: contributions, growth, and what costs took away.
class _ProportionBar extends StatelessWidget {
  const _ProportionBar({required this.result});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final deposited = result.totalDeposited.abs();
    final growth = result.interestEarned.clamp(0, 1 << 62);
    final fees = result.totalFeesPaid.abs();
    final tax = result.capitalGainsTax.abs();
    final total = deposited + growth + fees + tax;

    if (total == 0) return const SizedBox.shrink();

    final segments = <(int, Color)>[
      (deposited, palette.deposits),
      (growth - fees - tax, palette.growth),
      (fees, palette.fees),
      (tax, palette.tax),
    ].where((s) => s.$1 > 0).toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final (value, color) in segments)
                  Expanded(
                    flex: (value * t).round().clamp(1, 1 << 30),
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(end: 2),
                      color: color,
                    ),
                  ),
                if (t < 1)
                  Expanded(
                    flex: ((1 - t) * total).round().clamp(1, 1 << 30),
                    child: const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.color,
    this.muted = false,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool muted;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasised
        ? context.texts.titleMedium
        : context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.75),
          );

    final valueStyle = emphasised
        ? context.texts.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.palette.growth,
          )
        : context.texts.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted
                ? context.colors.onSurface.withValues(alpha: 0.55)
                : context.colors.onSurface,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (color != null) ...[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 11),
          ],
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          // Shrinks rather than overflows. At the largest accessibility text
          // sizes a full figure like $1,622,189.55 is wider than the card,
          // and a Row will not give it room on its own.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(value, style: valueStyle, maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }
}
