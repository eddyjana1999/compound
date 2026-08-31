import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wraps an ad in the app's own separation and background.
///
/// Two jobs. It keeps a visible gap between the ad and the app's controls, so
/// a mis-tap lands on nothing rather than on a banner. And it collapses to
/// zero height when the ad has not loaded, so a slow fill or no fill leaves
/// the layout exactly as it would be with ads switched off.
///
/// It does not reserve the home-indicator inset. A banner runs to the bottom
/// edge of the screen — the strip of app background under it read as a gap —
/// so the caller reserves that space only when it knows no banner is coming.
class AdSlot extends StatelessWidget {
  const AdSlot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ColoredBox(
        color: context.colors.surface,
        child: Align(alignment: Alignment.center, child: child),
      ),
    );
  }
}
