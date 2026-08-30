import 'package:flutter/material.dart';

import '../../domain/money.dart';
import '../formatting/money_format.dart';
import '../theme/app_theme.dart';

/// The headline figure on the results screen.
///
/// The number counts up on arrival. Not decoration: the growth this app
/// models is a process over time, and a figure that arrives by accumulating
/// says so before the chart below it does.
class HeroResult extends StatelessWidget {
  const HeroResult({
    super.key,
    required this.caption,
    required this.amount,
    required this.format,
    this.footnote,
    this.subline,
  });

  final String caption;
  final MinorUnits amount;
  final MoneyFormat format;
  final Widget? footnote;

  /// A single line under the amount. The place the gross figure goes, so the
  /// number the user came for is never read without what it cost to get it.
  final Widget? subline;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: palette.heroGradient,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.heroGradient.last.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: context.texts.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  format.moneyRounded(value.round()),
                  maxLines: 1,
                  style: context.texts.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 46,
                  ),
                ),
              );
            },
          ),
          if (subline != null) ...[
            const SizedBox(height: 6),
            DefaultTextStyle.merge(
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13.5,
                height: 1.35,
              ),
              child: subline!,
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 14),
            DefaultTextStyle.merge(
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              child: footnote!,
            ),
          ],
        ],
      ),
    );
  }
}
