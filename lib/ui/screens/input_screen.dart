import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/calculation_input.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/amount_field.dart';
import '../formatting/currencies.dart';
import '../widgets/app_card.dart';
import '../widgets/currency_picker.dart';
import 'paywall_screen.dart';
import 'results_screen.dart';

/// Collects the inputs and hands them to the engine on demand.
///
/// Deliberately not live: the result appears when the user presses Calculate,
/// so a half-typed number never shows a figure that is about to change.
class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key, this.initial});

  final CalculationInput? initial;

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  late final TextEditingController _startingAmount;
  late final TextEditingController _monthly;
  late final TextEditingController _returnRate;
  late final TextEditingController _years;
  late final TextEditingController _fee;
  late final TextEditingController _tax;
  late final TextEditingController _inflation;
  late final TextEditingController _growth;

  bool _advancedOpen = false;
  bool _submitted = false;
  String? _currencyOverride;

  static const List<int> _yearPresets = [5, 10, 20, 30];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _startingAmount = TextEditingController();
    _monthly = TextEditingController();
    _returnRate = TextEditingController(text: '7');
    _years = TextEditingController(text: '20');
    _fee = TextEditingController();
    _tax = TextEditingController();
    _inflation = TextEditingController();
    _growth = TextEditingController();

    if (initial != null) {
      _advancedOpen = initial.hasFee ||
          initial.hasTax ||
          initial.hasInflation ||
          initial.hasContributionGrowth;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initial = widget.initial;
    if (initial != null && _startingAmount.text.isEmpty) {
      final format = _format;
      _startingAmount.text = format.plainAmount(initial.initialAmount);
      _monthly.text = format.plainAmount(initial.monthlyContribution);
      _returnRate.text = _plainPercent(initial.annualReturn);
      _years.text = '${initial.years}';
      if (initial.hasFee) _fee.text = _plainPercent(initial.annualManagementFee);
      if (initial.hasTax) {
        _tax.text = _plainPercent(initial.capitalGainsTaxRate);
      }
      if (initial.hasInflation) {
        _inflation.text = _plainPercent(initial.annualInflation);
      }
      if (initial.hasContributionGrowth) {
        _growth.text = _plainPercent(initial.annualContributionGrowth);
      }
    }
  }

  static String _plainPercent(int bps) {
    final value = bps / 100;
    return value == value.roundToDouble()
        ? '${value.round()}'
        : value.toStringAsFixed(2);
  }

  String get _localeName => Localizations.localeOf(context).toString();

  /// What the device would spend in, before the user overrides it.
  CurrencySpec get _deviceCurrency =>
      MoneyFormat.currencyForLocale(_localeName);

  /// The currency this calculation is in: the one being edited, else the one
  /// the user last chose, else the device's.
  CurrencySpec get _currency {
    final code = _currencyOverride ??
        widget.initial?.currency.code ??
        ref.read(preferredCurrencyProvider);
    return code == null ? _deviceCurrency : Currencies.specFor(code);
  }

  MoneyFormat get _format => MoneyFormat(_localeName, _currency);

  Future<void> _pickCurrency() async {
    FocusScope.of(context).unfocus();
    final chosen = await showCurrencyPicker(
      context,
      selected: _currency.code,
      deviceCurrency: _deviceCurrency.code,
    );
    if (chosen == null || !mounted) return;

    // The typed numbers are kept as typed. Converting them would need an
    // exchange rate the app does not have and would silently change the
    // user's inputs — switching currency reinterprets the figures, it does
    // not translate them.
    setState(() => _currencyOverride = chosen);
    await ref.read(preferredCurrencyProvider.notifier).set(chosen);
  }

  @override
  void dispose() {
    _startingAmount.dispose();
    _monthly.dispose();
    _returnRate.dispose();
    _years.dispose();
    _fee.dispose();
    _tax.dispose();
    _inflation.dispose();
    _growth.dispose();
    super.dispose();
  }

  /// Builds the input from the current text, or null if it cannot be built.
  CalculationInput? _buildInput() {
    final format = _format;
    final isPro = ref.read(isProProvider);
    final years = int.tryParse(_years.text.trim());
    final annualReturn = format.parsePercent(_returnRate.text);
    if (years == null || annualReturn == null) return null;

    return CalculationInput(
      currency: format.currency,
      initialAmount: format.parseAmount(_startingAmount.text) ?? 0,
      monthlyContribution: format.parseAmount(_monthly.text) ?? 0,
      annualReturn: annualReturn,
      years: years,
      annualManagementFee: format.parsePercent(_fee.text) ?? 0,
      capitalGainsTaxRate: format.parsePercent(_tax.text) ?? 0,
      // Pro only. A free user cannot type into these, so they stay zero and
      // the projection is exactly what it was before Pro existed.
      annualInflation: isPro ? (format.parsePercent(_inflation.text) ?? 0) : 0,
      annualContributionGrowth:
          isPro ? (format.parsePercent(_growth.text) ?? 0) : 0,
    );
  }

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);

    final input = _buildInput();
    if (input == null || !input.isValid) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();

    final adDue = await ref.read(calculationCounterProvider.notifier).record();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(input: input)),
    );

    // Shown on the way *out* of the result, not on the way in. Interrupting
    // the tap-to-answer moment is the one thing that would make the app feel
    // worse than its competitors; a user who has finished reading their
    // result is at a natural break.
    if (adDue && mounted) {
      await ref.read(adServiceProvider).showInterstitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = _format;
    final input = _buildInput();
    final problem = _submitted ? (input?.problem ?? InputProblem.nothingInvested) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newCalculation),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                  AmountField(
                    label: l10n.startingAmount,
                    controller: _startingAmount,
                    prefix: format.currency.code,
                    onPrefixTap: _pickCurrency,
                    autofocus: widget.initial == null,
                    onChanged: (_) => _onEdited(),
                  ),
                  const SizedBox(height: 18),
                  AmountField(
                    label: l10n.monthlyContribution,
                    controller: _monthly,
                    prefix: format.currency.code,
                    onPrefixTap: _pickCurrency,
                    onChanged: (_) => _onEdited(),
                  ),
                  const SizedBox(height: 18),
                  AmountField(
                    label: l10n.annualReturn,
                    controller: _returnRate,
                    suffix: '%',
                    onChanged: (_) => _onEdited(),
                  ),
                  const SizedBox(height: 18),
                  AmountField(
                    label: l10n.timeHorizon,
                    controller: _years,
                    allowDecimal: false,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _onEdited(),
                  ),
                  const SizedBox(height: 12),
                  _YearPresets(
                    selected: int.tryParse(_years.text.trim()),
                    onSelected: (years) {
                      setState(() => _years.text = '$years');
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(height: 20),
                  _AdvancedSection(
                    open: _advancedOpen,
                    onToggle: () =>
                        setState(() => _advancedOpen = !_advancedOpen),
                    feeController: _fee,
                    taxController: _tax,
                    inflationController: _inflation,
                    growthController: _growth,
                    isPro: ref.watch(isProProvider),
                    onEdited: _onEdited,
                    onLockedTap: () => showPaywall(context),
                  ),
                  if (problem != null) ...[
                    const SizedBox(height: 18),
                    _ProblemBanner(problem: problem),
                  ],
                ],
              ),
            ),
            _CalculateBar(onPressed: _calculate),
          ],
        ),
      ),
    );
  }

  void _onEdited() {
    if (_submitted) setState(() => _submitted = false);
  }
}

class _YearPresets extends StatelessWidget {
  const _YearPresets({required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 8,
      children: [
        for (final years in _InputScreenState._yearPresets)
          ChoiceChip(
            label: Text(l10n.yearsValue(years)),
            selected: selected == years,
            showCheckmark: false,
            onSelected: (_) => onSelected(years),
            labelStyle: context.texts.labelMedium?.copyWith(
              color: selected == years
                  ? context.colors.onPrimaryContainer
                  : context.colors.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: context.palette.cardBorder),
            selectedColor: context.colors.primaryContainer,
            backgroundColor: context.colors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({
    required this.open,
    required this.onToggle,
    required this.feeController,
    required this.taxController,
    required this.inflationController,
    required this.growthController,
    required this.isPro,
    required this.onEdited,
    required this.onLockedTap,
  });

  final bool open;
  final VoidCallback onToggle;
  final TextEditingController feeController;
  final TextEditingController taxController;
  final TextEditingController inflationController;
  final TextEditingController growthController;
  final bool isPro;
  final VoidCallback onEdited;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: context.colors.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.advanced, style: context.texts.titleMedium),
                        Text(
                          l10n.advancedSubtitle,
                          style: context.texts.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: context.colors.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 18),
                        AmountField(
                          label: l10n.managementFee,
                          controller: feeController,
                          suffix: '%',
                          helper: l10n.optional,
                          onChanged: (_) => onEdited(),
                        ),
                        const SizedBox(height: 18),
                        AmountField(
                          label: l10n.capitalGainsTax,
                          controller: taxController,
                          suffix: '%',
                          helper: l10n.optional,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => onEdited(),
                        ),
                        const SizedBox(height: 18),
                        _ProField(
                          label: l10n.inflationLabel,
                          controller: inflationController,
                          isPro: isPro,
                          onEdited: onEdited,
                          onLockedTap: onLockedTap,
                        ),
                        const SizedBox(height: 18),
                        _ProField(
                          label: l10n.contributionGrowthLabel,
                          controller: growthController,
                          isPro: isPro,
                          onEdited: onEdited,
                          onLockedTap: onLockedTap,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A percentage field that only Pro can fill in.
///
/// Shown rather than hidden, and tapping it opens the paywall. A locked field
/// a free user can see teaches them the feature exists; a hidden one teaches
/// nothing, and a greyed-out one that does nothing on tap is just a dead end.
class _ProField extends StatelessWidget {
  const _ProField({
    required this.label,
    required this.controller,
    required this.isPro,
    required this.onEdited,
    required this.onLockedTap,
  });

  final String label;
  final TextEditingController controller;
  final bool isPro;
  final VoidCallback onEdited;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = AmountField(
      label: label,
      controller: controller,
      suffix: '%',
      helper: isPro ? l10n.optional : null,
      textInputAction: TextInputAction.done,
      onChanged: (_) => onEdited(),
    );

    if (isPro) return field;

    return Stack(
      children: [
        AbsorbPointer(child: Opacity(opacity: 0.55, child: field)),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onLockedTap,
              borderRadius: BorderRadius.circular(16),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 14, top: 22),
                  child: Pill(label: l10n.proBadge),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.problem});

  final InputProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: context.colors.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.checkYourNumbers,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculateBar extends StatelessWidget {
  const _CalculateBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        MediaQuery.viewInsetsOf(context).bottom > 0
            ? 12
            : MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.palette.cardBorder)),
      ),
      child: FilledButton(
        onPressed: onPressed,
        child: Text(l10n.calculate),
      ),
    );
  }
}
