import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saved_calculation.dart';
import '../../domain/models/calculation_input.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_slot.dart';
import '../widgets/app_card.dart';
import '../widgets/breakdown_card.dart';
import '../widgets/growth_chart.dart';
import '../widgets/hero_result.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.input, this.saved = false});

  final CalculationInput input;

  /// True when arriving from history, where saving again would duplicate.
  final bool saved;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late bool _saved = widget.saved;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final entry = SavedCalculation(
      id: _newId(),
      createdAt: DateTime.now(),
      input: widget.input,
    );
    await ref.read(historyProvider.notifier).add(entry);

    if (!mounted) return;
    setState(() => _saved = true);
    HapticFeedback.mediumImpact();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.savedToHistory)));
  }

  static String _newId() {
    final random = math.Random();
    return '${DateTime.now().microsecondsSinceEpoch}'
        '-${random.nextInt(1 << 32)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = ref.read(engineProvider).calculate(widget.input);
    final format = MoneyFormat(
      Localizations.localeOf(context).toString(),
      widget.input.currency,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.results)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  8,
                  AppTheme.pagePadding,
                  24,
                ),
                children: [
                  HeroResult(
                    caption: l10n.youWouldHave(l10n.yearsValue(widget.input.years)),
                    amount: result.netFinalValue,
                    format: format,
                    // Wrap, not Row: with the rate chip added these overflow a
                    // narrow screen, and a headline that renders a yellow
                    // overflow stripe is worse than one that takes two lines.
                    footnote: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // The assumption the whole projection rests on. Shown
                        // beside the result so the number is never read
                        // without the rate that produced it.
                        _HeroChip(
                          icon: Icons.percent_rounded,
                          label: '${format.percent(widget.input.annualReturn)}'
                              ' ${l10n.perYear}',
                        ),
                        _HeroChip(
                          icon: Icons.savings_outlined,
                          label: format.moneyCompact(result.totalDeposited),
                        ),
                        _HeroChip(
                          icon: Icons.trending_up_rounded,
                          label: format.moneyCompact(result.interestEarned),
                        ),
                        if (result.hasCosts)
                          _HeroChip(
                            icon: Icons.remove_circle_outline_rounded,
                            label: format.moneyCompact(result.totalCosts),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BreakdownCard(result: result, format: format),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.growthOverTime,
                          style: context.texts.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        GrowthChart(result: result, format: format),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.disclaimer,
                      style: context.texts.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        color:
                            context.colors.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _SaveBar(saved: _saved, onSave: _save),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends ConsumerWidget {
  const _SaveBar({required this.saved, required this.onSave});

  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.palette.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              12,
              AppTheme.pagePadding,
              12,
            ),
            child: _button(context, l10n),
          ),
          AdSlot(child: ref.watch(adServiceProvider).banner()),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, AppLocalizations l10n) {
    return saved
          ? FilledButton.tonalIcon(
              onPressed: null,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(l10n.savedToHistory),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.bookmark_add_outlined, size: 20),
              label: Text(l10n.save),
            );
  }
}
