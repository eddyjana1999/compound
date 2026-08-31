import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settings, style: context.texts.headlineMedium),
            const SizedBox(height: 24),
            // Apple requires a restore path for a non-consumable; an app that
            // can sell this but cannot restore it is rejected.
            _RestoreRow(purchased: ref.watch(adsRemovedProvider)),
            // Reachable from inside the app, not only from the store
            // listing. Both stores expect it of anything that carries ads or
            // sells something, and it is one of the things a reviewer taps.
            const _LegalRow(),
            Text(l10n.appearance, style: context.texts.labelMedium),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.systemDefault),
                ),
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.light)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.dark)),
              ],
              selected: {settings.themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  notifier.setThemeMode(selection.first),
            ),
            const SizedBox(height: 26),
            // Only shown where consent law requires an ongoing way to change
            // the answer. Elsewhere there is nothing to change, and an entry
            // that opens an empty form is worse than no entry.
            ref
                .watch(privacyOptionsRequiredProvider)
                .maybeWhen(
                  data: (required) => required
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 26),
                          child: OutlinedButton.icon(
                            onPressed: () => ref
                                .read(adServiceProvider)
                                .showPrivacyOptions(),
                            icon: const Icon(
                              Icons.privacy_tip_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.adPrivacy),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
            Text(l10n.language, style: context.texts.labelMedium),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _LanguageTile(
                      label: l10n.systemDefault,
                      selected: settings.locale == null,
                      onTap: () => notifier.setLocale(null),
                    ),
                    for (final entry in _languageNames.entries)
                      _LanguageTile(
                        label: entry.value,
                        selected: settings.locale?.languageCode == entry.key,
                        onTap: () => notifier.setLocale(Locale(entry.key)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: context.palette.growth,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.adsRemovedTitle,
              style: context.texts.titleMedium?.copyWith(
                color: context.palette.growth,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _restore,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restore_rounded, size: 18),
        label: Text(l10n.restorePurchases),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
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
