import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../legal_links.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/remove_ads_card.dart';

/// Language and appearance, as a sheet rather than a screen — they are two
/// settings, not a section of the app.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // Without this the sheet is free to grow to the very top of the screen,
    // and with a long list open it slides under the camera cutout. It insets
    // the whole sheet rather than its contents, so the rounded top edge stays
    // visible below the island instead of the title hiding behind it.
    useSafeArea: true,
    showDragHandle: true,
    // No colour or shape passed here on purpose. Both come from
    // bottomSheetTheme so they follow a theme change while the sheet is open.
    builder: (_) => const _SettingsSheet(),
  );
}

/// The languages the app ships strings for, with their endonyms — a language
/// list that names languages in the reader's own language is useless to the
/// person looking for theirs.
const Map<String, String> _languageNames = {
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'zh': '中文',
  'ja': '日本語',
  'ar': 'العربية',
  'he': 'עברית',
};

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  /// The language list opens inside this sheet rather than in one of its own.
  ///
  /// It used to be a second modal route stacked on this one, and changing the
  /// language rebuilt the app underneath both of them — which left the picker
  /// unable to close. A sheet that opens a sheet that rebuilds its own parent
  /// is a knot; expanding in place has no route to lose.
  bool _languageOpen = false;

  /// Owned here so the scrollbar and the view are driven by the same object;
  /// a Scrollbar with no controller attaches to whatever PrimaryScrollController
  /// happens to be in scope, which inside a sheet is not this list.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final currentLanguage = settings.locale == null
        ? l10n.systemDefault
        : _languageNames[settings.locale!.languageCode] ?? l10n.systemDefault;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(l10n.settings, style: context.texts.headlineMedium),
          ),
          const SizedBox(height: 20),
          Flexible(
            // The scroll view runs the full width of the sheet so the thumb
            // sits in the margin rather than on top of the rows' chevrons;
            // the 20pt gutter moves onto the content instead.
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What this screen is for, first.
                    const RemoveAdsCard(padded: false),
                    _ActionGroup(
                      children: [
                        _RestoreRow(purchased: ref.watch(adsRemovedProvider)),
                        _ActionRow(
                          icon: Icons.star_outline_rounded,
                          label: l10n.rateApp,
                          onTap: () => _openUrl(LegalLinks.writeReview),
                        ),
                        _ActionRow(
                          icon: Icons.ios_share_rounded,
                          label: l10n.shareApp,
                          onTap: () => SharePlus.instance.share(
                            ShareParams(
                              text: '${l10n.shareAppMessage}\n'
                                  '${LegalLinks.appStore}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Then the two things a person actually comes here to
                    // change, in the order they are most often changed.
                    Text(l10n.appearance, style: context.texts.labelMedium),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.systemDefault),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.light),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.dark),
                        ),
                      ],
                      selected: {settings.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          notifier.setThemeMode(selection.first),
                    ),
                    const SizedBox(height: 22),

                    Text(l10n.language, style: context.texts.labelMedium),
                    const SizedBox(height: 10),
                    _ActionGroup(
                      children: [
                        _ActionRow(
                          icon: Icons.translate_rounded,
                          label: currentLanguage,
                          expanded: _languageOpen,
                          onTap: () => setState(
                            () => _languageOpen = !_languageOpen,
                          ),
                        ),
                        if (_languageOpen) ...[
                          _LanguageTile(
                            label: l10n.systemDefault,
                            selected: settings.locale == null,
                            onTap: () {
                              notifier.setLocale(null);
                              setState(() => _languageOpen = false);
                            },
                          ),
                          for (final entry in _languageNames.entries)
                            _LanguageTile(
                              label: entry.value,
                              selected:
                                  settings.locale?.languageCode == entry.key,
                              onTap: () {
                                notifier.setLocale(Locale(entry.key));
                                setState(() => _languageOpen = false);
                              },
                            ),
                        ],
                      ],
                    ),

                    // Only shown where consent law requires an ongoing way to
                    // change the answer. Elsewhere there is nothing to change,
                    // and an entry that opens an empty form is worse than
                    // no entry.
                    ref.watch(privacyOptionsRequiredProvider).maybeWhen(
                          data: (required) => required
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 22),
                                  child: _ActionGroup(
                                    children: [
                                      _ActionRow(
                                        icon: Icons.privacy_tip_outlined,
                                        label: l10n.adPrivacy,
                                        onTap: () => ref
                                            .read(adServiceProvider)
                                            .showPrivacyOptions(),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),

                    // Last, because nobody opens Settings to read them — but
                    // both stores expect them to be reachable from inside the
                    // app, and App Review taps them.
                    const SizedBox(height: 22),
                    const _LegalRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        label,
        style: context.texts.bodyMedium?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? context.palette.growth : null,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: context.palette.growth)
          : null,
      onTap: onTap,
    );
  }
}

class _RestoreRow extends ConsumerStatefulWidget {
  const _RestoreRow({required this.purchased});

  final bool purchased;

  @override
  ConsumerState<_RestoreRow> createState() => _RestoreRowState();
}

class _RestoreRowState extends ConsumerState<_RestoreRow> {
  bool _busy = false;

  Future<void> _restore() async {
    setState(() => _busy = true);
    final outcome = await ref.read(purchaseServiceProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    showPurchaseOutcome(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.purchased) {
      return _ActionRow(
        icon: Icons.check_circle_rounded,
        label: l10n.adsRemovedTitle,
        tint: context.palette.growth,
        onTap: null,
      );
    }

    return _ActionRow(
      icon: Icons.restore_rounded,
      label: l10n.restorePurchases,
      busy: _busy,
      onTap: _busy ? null : _restore,
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow();

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = context.texts.bodyMedium?.copyWith(
      fontSize: 13,
      color: context.colors.onSurface.withValues(alpha: 0.6),
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Wrap(
        spacing: 20,
        runSpacing: 4,
        children: [
          TextButton(
            onPressed: () => _open(LegalLinks.privacy),
            child: Text(l10n.privacyPolicy, style: style),
          ),
          TextButton(
            onPressed: () => _open(LegalLinks.terms),
            child: Text(l10n.termsOfUse, style: style),
          ),
        ],
      ),
    );
  }
}

/// Opens a link in the system browser, from anywhere on this sheet.
Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// A card that holds a run of [_ActionRow]s with hairlines between them.
class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 48,
                color: context.colors.onSurface.withValues(alpha: 0.07),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One tappable line: icon, label, chevron.
///
/// Replaces the stack of full-width outlined buttons this sheet used to be.
/// Three of those, plus a nine-row language list, filled the screen before
/// the reader reached anything they came here to change.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
    this.busy = false,
    this.expanded,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? tint;
  final bool busy;

  /// Non-null when this row opens something below it, and the chevron should
  /// point down rather than forward.
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final colour = tint ?? context.colors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 20, color: colour.withValues(alpha: 0.75)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                expanded == null
                    ? Icons.chevron_right_rounded
                    : expanded!
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                size: 20,
                color: context.colors.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}
