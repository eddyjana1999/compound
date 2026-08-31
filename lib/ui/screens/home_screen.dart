import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saved_calculation.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/money_format.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_slot.dart';
import '../widgets/app_card.dart';
import 'input_screen.dart';
import 'results_screen.dart';
import 'settings_sheet.dart';

/// The screen people come back to.
///
/// Three ways to manage the list, because they answer different questions.
/// A star pins the one calculation you keep re-checking. A swipe removes one
/// you glanced at and do not need. A long press starts a selection, for the
/// clear-out you do every few months. Only the swipe is destructive without
/// asking, and it is the only one that offers an undo.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _selected = {};
  bool _selecting = false;

  void _startSelecting(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selecting = true;
      _selected
        ..clear()
        ..add(id);
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
      // Deselecting the last one leaves selection mode, so there is never a
      // selection bar offering to delete nothing.
      if (_selected.isEmpty) _selecting = false;
    });
  }

  void _stopSelecting() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context);
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSelectedTitle),
        content: Text(l10n.selectedCount(count)),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(historyProvider.notifier).removeAll(Set.of(_selected));
    if (mounted) _stopSelecting();
  }

  /// Runs on the screen, not on the card.
  ///
  /// A dismissed card is deactivated by the time its callback fires, and
  /// touching `ref` from a widget that is leaving the tree throws. The screen
  /// is still mounted, so it owns the delete and the undo.
  void _deleteWithUndo(SavedCalculation entry) {
    final l10n = AppLocalizations.of(context);
    final history = ref.read(historyProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    history.remove(entry.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.deleted),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => history.add(entry),
        ),
      ));
  }

  Future<void> _confirmClear() async {
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

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final entries = history.value ?? const <SavedCalculation>[];

    // A selection cannot outlive the entries it points at.
    if (_selecting && entries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selecting) _stopSelecting();
      });
    }

    return PopScope(
      // Back leaves the selection before it leaves the app.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopSelecting();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _selecting
                  ? _SelectionHeader(
                      count: _selected.length,
                      onClose: _stopSelecting,
                      onDelete: _deleteSelected,
                    )
                  : _Header(
                      onSettings: () => showSettingsSheet(context),
                      onClear: entries.isNotEmpty ? _confirmClear : null,
                    ),
              Expanded(
                child: history.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  error: (_, _) => _Empty(),
                  data: (entries) => entries.isEmpty
                      ? _Empty()
                      : ListView.separated(
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
                              selecting: _selecting,
                              selected: _selected.contains(entry.id),
                              onLongPress: () => _startSelecting(entry.id),
                              onToggle: () => _toggle(entry.id),
                              onDismissed: () => _deleteWithUndo(entry),
                            );
                          },
                        ),
                ),
              ),
              _NewCalculationBar(),
            ],
          ),
        ),
      ),
    );
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

/// Replaces the title while a selection is active, the way Photos and Files
/// do — the count is the title, and the only actions are leave and delete.
class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.count,
    required this.onClose,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: context.palette.growthSoft,
      padding: const EdgeInsetsDirectional.fromSTEB(6, 8, 6, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: l10n.cancel,
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(
              l10n.selectedCount(count),
              style: context.texts.titleMedium?.copyWith(fontSize: 17),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: l10n.delete,
            icon: Icon(Icons.delete_outline_rounded,
                color: context.colors.error),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({
    super.key,
    required this.entry,
    required this.selecting,
    required this.selected,
    required this.onLongPress,
    required this.onToggle,
    required this.onDismissed,
  });

  final SavedCalculation entry;
  final bool selecting;
  final bool selected;
  final VoidCallback onLongPress;
  final VoidCallback onToggle;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final localeName = Localizations.localeOf(context).toString();
    final format = MoneyFormat(localeName, entry.input.currency);
    final result = ref.read(engineProvider).calculate(entry.input);

    final card = AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 6, 10),
      color: selected ? palette.growthSoft : null,
      onTap: selecting
          ? onToggle
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultsScreen(input: entry.input, saved: true),
                ),
              ),
      child: Row(
        children: [
          if (selecting)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? palette.growth
                    : context.colors.onSurface.withValues(alpha: 0.3),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // One line, shrinking rather than wrapping. A seven-figure
                // result broke across two lines mid-number — "$30,276,9"
                // above "31" — which is the one figure on this card the eye
                // goes to first. Alignment keeps short and long amounts on
                // the same baseline instead of centring the small ones.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    format.moneyRounded(result.netFinalValue),
                    maxLines: 1,
                    softWrap: false,
                    style: context.texts.headlineMedium?.copyWith(
                      fontSize: 24,
                      color: palette.growth,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  // Compact here, full above. The summary line is read at a
                  // glance while scanning, and "$56,888 + $58…" cut mid-number
                  // says less than "$56.9K + $580/m" does.
                  //
                  // A term that is zero is left out rather than formatted:
                  // intl renders a compact zero as "$0.00", which sits oddly
                  // beside "$100K" and states nothing the reader needed.
                  '${[
                    if (entry.input.initialAmount > 0)
                      format.moneyCompact(entry.input.initialAmount),
                    if (entry.input.monthlyContribution > 0)
                      '${format.moneyCompact(entry.input.monthlyContribution)}/m',
                  ].join(' + ')} · ${format.percent(entry.input.annualReturn)}',
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
          const SizedBox(width: 8),
          Pill(label: l10n.yearsValue(entry.input.years)),
          // The star stays out of selection mode: two different toggles on
          // one row is how people delete the thing they meant to keep.
          if (!selecting)
            IconButton(
              tooltip: entry.favourite
                  ? l10n.removeFromFavourites
                  : l10n.addToFavourites,
              icon: Icon(
                entry.favourite ? Icons.star_rounded : Icons.star_border_rounded,
                color: entry.favourite
                    ? const Color(0xFFF0B429)
                    : context.colors.onSurface.withValues(alpha: 0.35),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                ref
                    .read(historyProvider.notifier)
                    .setFavourite(entry.id, !entry.favourite);
              },
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );

    final wrapped = GestureDetector(
      onLongPress: selecting ? null : onLongPress,
      child: card,
    );

    // No swiping while selecting: a swipe that deletes one row out of a
    // selection is the kind of thing nobody can undo in their head.
    if (selecting) return wrapped;

    return Dismissible(
      key: ValueKey('dismiss-${entry.id}'),
      direction: DismissDirection.endToStart,
      // The only destructive action here that does not ask first, so it is
      // the one that has to offer a way back. Handled by the screen; see
      // _deleteWithUndo.
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child:
            Icon(Icons.delete_outline, color: context.colors.onErrorContainer),
      ),
      child: wrapped,
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
          // Nothing will ever fill the bottom edge for someone who paid to
          // remove ads, so the gesture-bar inset is reserved for them alone.
          if (ref.watch(adsRemovedProvider))
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
