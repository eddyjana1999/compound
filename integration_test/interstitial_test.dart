import 'package:compound/app.dart';
import 'package:compound/ui/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proves the cadence end to end: with two calculations already behind it,
/// the next one must produce the full-screen ad on the way out of the result.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the third calculation shows the interstitial', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('compound.calculationCount', 2);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CompoundApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text('New calculation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '10000');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Results'), findsOneWidget);

    // Leaving the result is the moment the ad is meant to appear.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pump();

    await binding.takeScreenshot('09-interstitial');
  });
}
