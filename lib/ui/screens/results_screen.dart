import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saved_calculation.dart';
import '../../share/share_calculation.dart';
import '../../domain/models/calculation_input.dart';
import '../../domain/models/calculation_result.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import 'input_screen.dart';
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
  /// Same reason as the settings sheet: this page is well over a screen tall
  /// once the chart, the tax bridge and the assumptions are all on it, and
  /// nothing said so. Owned here so the bar and the list share one object.
  final ScrollController _scroll = ScrollController();

  late bool _saved = widget.saved;
  bool _sharing = false;

  Future<void> _share(CalculationResult result) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // The share sheet is a popover on iPad and needs something to point at.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    setState(() => _sharing = true);
    try {
      await const ShareCalculation().share(context, result, origin: origin);
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
        // Back steps to the input screen, which is one of several ways in.
        // Home is the way out of all of them, and without it a reader who
        // arrived from a saved calculation has to guess how many taps back.
        // Two 48pt tap targets plus their padding. 92 was a guess and the
        // row overflowed it — invisibly in release, and caught by the
        // screenshot run rather than by anything that reads the source.
        leadingWidth: 104,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BackButton(),
            IconButton(
              tooltip: l10n.home,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: const Icon(Icons.home_outlined),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
        title: Text(l10n.results),
        actions: [
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _sharing ? null : () => _share(result),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        // The banner runs to the very bottom edge; the inset below it is
        // reserved by AdSlot only when there is no banner to fill it.
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    8,
                    AppTheme.pagePadding,
                    24,
                  ),
                  children: [
                    HeroResult(
                      caption: l10n.youWouldHave(
                        l10n.yearsValue(widget.input.years),
                      ),
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
                            label:
                                '${format.percent(widget.input.annualReturn)}'
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
                          if (result.capitalGainsTax > 0) ...[
                            const SizedBox(height: 18),
                            _TaxBridge(result: result, format: format),
                          ],
                          const SizedBox(height: 20),
                          _Assumptions(result: result, format: format),
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
                          color: context.colors.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
          // Nothing will ever fill the bottom edge for someone who paid to
          // remove ads, so the gesture-bar inset is reserved for them alone.
          if (ref.watch(adsRemovedProvider))
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, AppLocalizations l10n) {
    // Save is the primary action, but the common next move after reading a
    // result is to try a different one — and the only route to that was two
    // taps back through the input screen that produced this.
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InputScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 19),
            label: _fit(l10n.newCalculation),
            style: _pairStyle(OutlinedButton.styleFrom()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _saveButton(context, l10n)),
      ],
    );
  }

  /// Keeps a label on one line, shrinking it only when the label is too long
  /// for its half of the row.
  ///
  /// Two buttons of equal width with labels of unequal length is the whole
  /// problem: "Save" has room to spare while "New calculation" wraps, and in
  /// German it is "Neue Berechnung". Wrapping made one button taller than the
  /// other and left a single letter on its own line.
  static Widget _fit(String label) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(label, maxLines: 1, softWrap: false),
  );

  /// One shape for both, so they sit as a pair rather than as two buttons
  /// that happen to be adjacent.
  static ButtonStyle _pairStyle(ButtonStyle base) => base.copyWith(
    minimumSize: WidgetStateProperty.all(const Size.fromHeight(56)),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 12),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );

  Widget _saveButton(BuildContext context, AppLocalizations l10n) {
    return saved
        ? FilledButton.tonalIcon(
            onPressed: null,
            icon: const Icon(Icons.check_rounded, size: 19),
            label: _fit(l10n.savedToHistory),
            style: _pairStyle(FilledButton.styleFrom()),
          )
        : FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_add_outlined, size: 19),
            label: _fit(l10n.save),
            style: _pairStyle(FilledButton.styleFrom()),
          );
  }
}

/// What produced the curve, stated plainly underneath it.
///
/// The results screen showed four output figures and none of the inputs, so a
/// reader coming back to a saved calculation could not tell what it assumed.
/// It also closes a gap that read as an error: the chart plots the balance
/// *before* capital gains tax while the headline is the net figure, and with
/// nothing saying so the two look like they disagree.
class _Assumptions extends StatelessWidget {
  const _Assumptions({required this.result, required this.format});

  final CalculationResult result;
  final MoneyFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final input = result.input;
    final muted = context.colors.onSurface.withValues(alpha: 0.55);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 13.5,
                color: muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: context.texts.bodyMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: context.colors.onSurface.withValues(alpha: 0.08)),
        const SizedBox(height: 12),
        Text(
          l10n.assumptions,
          style: context.texts.labelMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 6),
        row(l10n.startingAmount, format.money(input.initialAmount)),
        if (input.monthlyContribution > 0)
          row(
            l10n.monthlyContribution,
            format.money(input.monthlyContribution),
          ),
        row(l10n.annualReturn, format.percent(input.annualReturn)),
        row(l10n.timeHorizon, l10n.yearsValue(input.years)),
        if (input.annualManagementFee > 0)
          row(l10n.managementFee, format.percent(input.annualManagementFee)),
        if (input.capitalGainsTaxRate > 0)
          row(l10n.capitalGainsTax, format.percent(input.capitalGainsTaxRate)),
      ],
    );
  }
}

/// The one subtraction that reconciles the chart with the headline.
///
/// A sentence saying the chart is pre-tax was not enough: the reader is
/// looking at two large figures that differ by six digits and wants to see
/// where the difference went. So show the arithmetic, with the same three
/// numbers already on the screen, in the order they happen.
class _TaxBridge extends StatelessWidget {
  const _TaxBridge({required this.result, required this.format});

  final CalculationResult result;
  final MoneyFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    Widget line(String label, String value, {bool emphasis = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: emphasis ? FontWeight.w600 : null,
                color: emphasis
                    ? null
                    : context.colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: context.texts.bodyMedium?.copyWith(
              fontSize: emphasis ? 15.5 : 13.5,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
              color: emphasis ? palette.growth : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(l10n.chartEndsAt, format.money(result.grossFinalValue)),
          line(l10n.taxPaid, '\u2212${format.money(result.capitalGainsTax)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              height: 1,
              color: context.colors.onSurface.withValues(alpha: 0.12),
            ),
          ),
          line(
            l10n.yoursAfterTax,
            format.money(result.netFinalValue),
            emphasis: true,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.chartIsPreTax,
            style: context.texts.bodyMedium?.copyWith(
              fontSize: 11.5,
              height: 1.35,
              color: context.colors.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
