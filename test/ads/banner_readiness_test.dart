import 'package:compound/ads/google_ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the banner slot', () {
    testWidgets('appears when consent completes after the first frame',
        (tester) async {
      // The whole point. Readiness is set asynchronously, seconds into the
      // session, and the screens reach the service through a Provider that
      // never notifies. As a plain bool this flipped with nothing listening
      // and the banner never rendered at all.
      final service = GoogleAdService();
      addTearDown(service.dispose);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: service.banner())),
      );

      expect(find.byType(AnchoredBanner), findsNothing,
          reason: 'nothing may be requested before consent is settled');

      service.adsAllowed.value = true;
      await tester.pump();

      expect(find.byType(AnchoredBanner), findsOneWidget,
          reason: 'the slot did not react to readiness — the original bug');
    });

    testWidgets('disappears again if readiness is revoked', (tester) async {
      final service = GoogleAdService();
      addTearDown(service.dispose);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: service.banner())),
      );

      service.adsAllowed.value = true;
      await tester.pump();
      expect(find.byType(AnchoredBanner), findsOneWidget);

      service.adsAllowed.value = false;
      await tester.pump();
      expect(find.byType(AnchoredBanner), findsNothing);
    });

    test('starts closed, so a slow consent check cannot leak a request', () {
      final service = GoogleAdService();
      addTearDown(service.dispose);
      expect(service.adsAllowed.value, isFalse);
    });
  });
}
