import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../iap/purchase_service.dart';
import '../../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// The one-off unlock, offered on the home screen.
///
/// Always visible until it has been bought, whatever the store says. It used
/// to disappear whenever the offer had not resolved, on the principle that a
/// dead button priced from a constant is worse than no button — which is
/// right about the *price* and wrong about the *card*. An App Store reviewer
/// who opens the app while the product is still resolving sees no purchase at
/// all, and "we were unable to locate the in-app purchase" is a rejection.
///
/// So: the card stays, and only the button changes. The price is still never
/// invented — it is either the store's own string, a spinner, or a retry.
class RemoveAdsCard extends ConsumerStatefulWidget {
  const RemoveAdsCard({super.key, this.padded = true});

  /// Whether to add the page margin. False inside a sheet, which pads itself.
  final bool padded;

  @override
  ConsumerState<RemoveAdsCard> createState() => _RemoveAdsCardState();
}

class _RemoveAdsCardState extends ConsumerState<RemoveAdsCard> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    final outcome = await ref.read(purchaseServiceProvider).buy();
    if (!mounted) return;
    setState(() => _busy = false);
    showPurchaseOutcome(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(adsRemovedProvider)) return const SizedBox.shrink();

    final offerState = ref.watch(removeAdsOfferProvider);
    final offer = offerState.value;
    final resolving = offerState.isLoading;

    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return Padding(
      padding: widget.padded
          ? const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              4,
              AppTheme.pagePadding,
              12,
            )
          : const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.growthSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.block_rounded, size: 21, color: palette.growth),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.removeAds, style: context.texts.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    l10n.removeAdsBody,
                    style: context.texts.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      height: 1.3,
                      color:
                          context.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _busy || resolving
                  ? null
                  : offer == null
                      // Nothing to buy yet — no network, or the product is
                      // still propagating. Let them ask again rather than
                      // leaving a button that does nothing.
                      ? () => ref.invalidate(removeAdsOfferProvider)
                      : _buy,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                // Long prices exist — "CHF 24.90", "₩29,000" — and the title
                // must keep its room whatever the store sends back.
                maximumSize: const Size(150, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _busy || resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : offer == null
                      // An icon, not the word. "Try again" is wider than any
                      // price, and in German it is "Erneut versuchen" — long
                      // enough to squeeze the title into three lines on a
                      // narrow phone. The retry is the rare state; the price
                      // is the normal one, and the button should be sized for
                      // the price.
                      ? Tooltip(
                          message: l10n.tryAgain,
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: context.colors.onPrimary,
                          ),
                        )
                      // The store's own localised price string. Never
                      // formatted by this app and never a constant.
                      : Text(offer.price, textDirection: TextDirection.ltr),
            ),
          ],
        ),
      ),
    );
  }
}

/// Turns a store outcome into something worth saying.
///
/// A cancellation says nothing: the user chose to back out and does not need
/// to be told what they just did.
void showPurchaseOutcome(BuildContext context, PurchaseOutcome outcome) {
  final l10n = AppLocalizations.of(context);

  final String? message = switch (outcome) {
    PurchaseOutcome.purchased || PurchaseOutcome.restored => l10n.purchaseThanks,
    PurchaseOutcome.nothingToRestore => l10n.nothingToRestore,
    PurchaseOutcome.failed || PurchaseOutcome.unavailable => l10n.purchaseFailed,
    PurchaseOutcome.cancelled || PurchaseOutcome.pending => null,
  };
  if (message == null) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
