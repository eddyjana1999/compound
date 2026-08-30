import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../iap/legal_links.dart';
import '../../iap/purchase_service.dart';
import '../../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';

/// The one place Pro is sold.
///
/// Deliberately not a subscription sheet: there is one price, it is shown
/// before the button is pressed, and the button says what it does. Nothing
/// renews, so none of the auto-renewal disclosures apply — which is also why
/// this screen can stay this short.
Future<void> showPaywall(BuildContext context) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PaywallScreen()),
  );
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _buying = false;
  bool _restoring = false;

  Future<void> _run(
    Future<PurchaseOutcome> Function() action,
    void Function(bool) setBusy,
  ) async {
    setBusy(true);
    final outcome = await action();
    if (!mounted) return;
    setBusy(false);

    final l10n = AppLocalizations.of(context);
    final String? message = switch (outcome) {
      PurchaseOutcome.purchased || PurchaseOutcome.restored => l10n.proThanks,
      PurchaseOutcome.nothingToRestore => l10n.nothingToRestore,
      PurchaseOutcome.failed => l10n.purchaseFailed,
      PurchaseOutcome.unavailable => l10n.proUnavailable,
      // Backing out is a choice, not a failure, and Ask to Buy has not
      // resolved yet — neither deserves an error.
      PurchaseOutcome.cancelled || PurchaseOutcome.pending => null,
    };

    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    if (outcome == PurchaseOutcome.purchased ||
        outcome == PurchaseOutcome.restored) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offer = ref.watch(proOfferProvider).value;
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
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
                    AppTheme.pagePadding, 0, AppTheme.pagePadding, 24),
                children: [
                  _Hero(badge: l10n.proBadge),
                  const SizedBox(height: 26),
                  Text(l10n.proTitle, style: context.texts.displayLarge?.copyWith(fontSize: 30)),
                  const SizedBox(height: 10),
                  Text(
                    l10n.proBlurb,
                    style: context.texts.bodyMedium?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Feature(icon: Icons.trending_down_rounded, label: l10n.proInflation),
                  _Feature(icon: Icons.stacked_line_chart_rounded, label: l10n.proGrowth),
                  _Feature(icon: Icons.ios_share_rounded, label: l10n.proExport),
                  _Feature(icon: Icons.block_rounded, label: l10n.proNoAds),
                ],
              ),
            ),
            _Footer(
              isPro: isPro,
              offer: offer,
              buying: _buying,
              restoring: _restoring,
              onBuy: () => _run(
                () => ref.read(purchaseServiceProvider).buy(),
                (v) => setState(() => _buying = v),
              ),
              onRestore: () => _run(
                () => ref.read(purchaseServiceProvider).restore(),
                (v) => setState(() => _restoring = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.badge});

  final String badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: palette.heroGradient,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph_rounded, size: 52, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 2.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: palette.growthSoft, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 18, color: palette.growth),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(label, style: context.texts.bodyMedium?.copyWith(fontSize: 15.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isPro,
    required this.offer,
    required this.buying,
    required this.restoring,
    required this.onBuy,
    required this.onRestore,
  });

  final bool isPro;
  final ProOffer? offer;
  final bool buying;
  final bool restoring;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final linkStyle = context.texts.bodyMedium?.copyWith(
      fontSize: 12.5,
      color: context.colors.onSurface.withValues(alpha: 0.55),
      decoration: TextDecoration.underline,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(AppTheme.pagePadding, 14, AppTheme.pagePadding,
          MediaQuery.paddingOf(context).bottom + 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.palette.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Directly above the button, not buried up the page. Apple looks
          // for the billing terms next to the control that charges, and a
          // reader deciding to pay should not have to scroll to find out
          // whether it renews.
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_open_rounded,
                      size: 16,
                      color: context.colors.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      l10n.proNotSubscription,
                      style: context.texts.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        height: 1.35,
                        color: context.colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isPro)
            FilledButton.tonalIcon(
              onPressed: null,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(l10n.proActive),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            )
          else
            FilledButton(
              // Disabled until the store has answered. A button that cannot
              // name its price should not be pressable.
              onPressed: (offer == null || buying) ? null : onBuy,
              child: buying
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: Text(l10n.proCta, overflow: TextOverflow.ellipsis)),
                        if (offer != null) ...[
                          const SizedBox(width: 10),
                          Text('· ${offer!.price}', textDirection: TextDirection.ltr),
                        ],
                      ],
                    ),
            ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: restoring ? null : onRestore,
                child: Text(
                  l10n.restorePurchases,
                  style: linkStyle?.copyWith(decoration: TextDecoration.none),
                ),
              ),
              // Hidden rather than dead when the URLs are not configured.
              if (LegalLinks.hasTerms)
                TextButton(
                  onPressed: () => _open(LegalLinks.terms),
                  child: Text(l10n.termsOfUse, style: linkStyle),
                ),
              if (LegalLinks.hasPrivacy)
                TextButton(
                  onPressed: () => _open(LegalLinks.privacy),
                  child: Text(l10n.privacyPolicy, style: linkStyle),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
