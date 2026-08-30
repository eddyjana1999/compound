import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saved_calculation.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../state/providers.dart';
import '../widgets/ad_slot.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pro_card.dart';
import 'input_screen.dart';
import 'results_screen.dart';
import 'settings_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              onSettings: () => showSettingsSheet(context),
              onClear: history.value?.isNotEmpty == true
                  ? () => _confirmClear(context, ref)
                  : null,
            ),
            Expanded(
              child: history.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                error: (_, _) => _Empty(),
                data: (entries) => entries.isEmpty
                    ? _Empty()
                    : _HistoryList(entries: entries),
              ),
            ),
            const ProCard(),
            _NewCalculationBar(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllTitle),
        content: Text(l10n.clearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(historyProvider.notifier).clear();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings, this.onClear});

  final VoidCallback onSettings;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        18,
        AppTheme.pagePadding - 8,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle.toUpperCase(),
                  style: context.texts.labelMedium?.copyWith(
                    color: context.palette.growth,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(l10n.historyTitle, style: context.texts.headlineMedium),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              tooltip: l10n.clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          IconButton(
            onPressed: onSettings,
            tooltip: l10n.settings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.entries});

  final List<SavedCalculation> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        8,
        AppTheme.pagePadding,
        16,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _HistoryCard(
          key: ValueKey(entry.id),
          entry: entry,
          onDelete: () => ref.read(historyProvider.notifier).remove(entry.id),
        );
      },
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({super.key, required this.entry, required this.onDelete});

  final SavedCalculation entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final localeName = Localizations.localeOf(context).toString();
    final format = MoneyFormat(localeName, entry.input.currency);
    final result = ref.read(engineProvider).calculate(entry.input);

    return Dismissible(
      key: ValueKey('dismiss-${entry.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        onDelete();
        // A swipe is easy to do by accident and this deletes permanently.
        // The bulk clear already asks for confirmation; the single delete had
        // no way back at all, which is the wrong way round.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.deleted),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () =>
                  ref.read(historyProvider.notifier).add(entry),
            ),
          ));
      },
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Icon(Icons.delete_outline, color: context.colors.onErrorContainer),
      ),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(input: entry.input, saved: true),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.moneyRounded(result.netFinalValue),
                    style: context.texts.headlineMedium?.copyWith(
                      fontSize: 24,
                      color: palette.growth,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${format.moneyRounded(entry.input.initialAmount)}'
                    ' + ${format.moneyRounded(entry.input.monthlyContribution)}/m'
                    ' · ${format.percent(entry.input.annualReturn)}',
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Pill(label: l10n.yearsValue(entry.input.years)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: palette.growthSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 44,
                color: palette.growth,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              l10n.emptyTitle,
              textAlign: TextAlign.center,
              style: context.texts.titleMedium?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyBody,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewCalculationBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.palette.cardBorder),
        ),
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
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InputScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(l10n.newCalculation),
            ),
          ),
          // Below the action, never beside it: a banner within a thumb's
          // reach of the primary button invites accidental taps, which AdMob
          // counts as invalid traffic.
          AdSlot(child: ref.watch(adServiceProvider).banner()),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
