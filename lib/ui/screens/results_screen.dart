import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saved_calculation.dart';
import '../../export/export_service.dart';
import '../../domain/models/calculation_input.dart';
import '../../domain/models/calculation_result.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_slot.dart';
import '../widgets/app_card.dart';
import '../widgets/breakdown_card.dart';
import '../widgets/growth_chart.dart';
import '../widgets/hero_result.dart';
import 'paywall_screen.dart';

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

  /// Pro only. A free user is shown the paywall rather than a disabled
  /// button, because a control that does nothing teaches nothing.
  Future<void> _export(CalculationResult result) async {
    if (!ref.read(isProProvider)) {
      await showPaywall(context);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final format = await showModalBottomSheet<ExportFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.exportPdf),
              onTap: () => Navigator.pop(context, ExportFormat.pdf),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.exportCsv),
              onTap: () => Navigator.pop(context, ExportFormat.csv),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // The share sheet needs somewhere to point on iPad, or it throws.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    try {
      await const ExportService().share(result, format, origin: origin);
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
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
      appBar: AppBar(
        title: Text(l10n.results),
        actions: [
          IconButton(
            tooltip: l10n.export,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _export(result),
          ),
        ],
      ),
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
                    subline: _Subline(result: result, format: format),
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
                          label: '${format.percent(widget.input.annualReturn)}'
                              ' ${l10n.perYear}',
                        ),
                        // Words, not icons. A piggy bank and a circled minus
                        // carry no meaning, and the costs figure now lives in
                        // the subline above where it reads as a comparison.
                        _HeroChip(
                          label: '${l10n.depositedShort} '
                              '${format.moneyCompact(result.totalDeposited)}',
                        ),
                        _HeroChip(
                          label: '${l10n.growthShort} '
                              '${format.moneyCompact(result.interestEarned)}',
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

/// What the headline figure cost to arrive at.
///
/// Every other calculator stops at the gross number. Showing both, on the
/// same card, is the whole argument for this app — so it is on the hero and
/// not buried in the breakdown below.
class _Subline extends StatelessWidget {
  const _Subline({required this.result, required this.format});

  final CalculationResult result;
  final MoneyFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = <String>[
      if (result.hasCosts)
        '${l10n.beforeCosts} ${format.moneyRounded(result.valueBeforeCosts)}'
            ' · ${l10n.youKeepShare(_percent(result.keptShare))}',
      if (result.input.hasInflation)
        '${l10n.inTodaysMoney} '
            '${format.moneyRounded(result.netFinalValueInTodaysMoney)}',
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(line),
          ),
      ],
    );
  }

  static String _percent(double share) =>
      '${(share * 100).round()}%';
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

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
