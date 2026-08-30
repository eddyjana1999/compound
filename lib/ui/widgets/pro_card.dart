import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// The way into the paywall, offered on the home screen.
///
/// Renders nothing at all when the store has no offer to give — no store on
/// the device, no network, or the product not approved yet. Sending someone
/// to a paywall that cannot name a price is worse than not offering.
class ProCard extends ConsumerWidget {
  const ProCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isProProvider)) return const SizedBox.shrink();

    final offer = ref.watch(proOfferProvider).value;
    if (offer == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        4,
        AppTheme.pagePadding,
        12,
      ),
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
              child: Icon(Icons.workspace_premium_rounded, size: 22, color: palette.growth),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.proTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    l10n.proBlurb,
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
              onPressed: () => showPaywall(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // The store's own localised price string. Never formatted by
              // this app and never a constant.
              child: Text(offer.price, textDirection: TextDirection.ltr),
            ),
          ],
        ),
      ),
    );
  }
}
