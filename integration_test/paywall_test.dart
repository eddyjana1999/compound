import 'package:compound/iap/purchase_service.dart';
import 'package:compound/ui/screens/paywall_screen.dart';
import 'package:compound/ui/state/providers.dart';
import 'package:compound/ui/theme/app_theme.dart';
import 'package:compound/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store that always has something to sell.
///
/// The real product does not exist in App Store Connect yet, so without this
/// the paywall correctly refuses to render and there is nothing to look at.
class _FakeStore implements PurchaseService {
  const _FakeStore();

  @override
  Future<void> initialize() async {}

  @override
  Future<ProOffer?> offer() async =>
      const ProOffer(id: 'com.compoundapp.compound.pro', price: '₪24.90');

  @override
  Future<PurchaseOutcome> buy() async => PurchaseOutcome.cancelled;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.nothingToRestore;

  @override
  void dispose() {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> open(WidgetTester tester, Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          purchaseServiceProvider.overrideWithValue(const _FakeStore()),
        ],
        child: MaterialApp(
          locale: locale,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PaywallScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 900)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('paywall in English', (tester) async {
    await open(tester, const Locale('en'));

    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.textContaining('₪24.90'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    // The disclosure that keeps this out of subscription territory.
    expect(find.textContaining('not a subscription'), findsOneWidget);
    // All four benefits, and only benefits that did not exist before.
    expect(find.textContaining('Inflation'), findsOneWidget);
    expect(find.textContaining('grows with your salary'), findsOneWidget);
    expect(find.textContaining('PDF'), findsOneWidget);
    expect(find.textContaining('No advertising'), findsOneWidget);

    await binding.takeScreenshot('pro-1-paywall-en');
  });

  testWidgets('paywall in Hebrew, right to left', (tester) async {
    await open(tester, const Locale('he'));

    expect(find.text('קח שליטה מלאה על העתיד הפיננסי שלך'), findsOneWidget);
    expect(find.text('שחזור רכישות'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('שחזור רכישות'))),
      TextDirection.rtl,
    );

    await binding.takeScreenshot('pro-2-paywall-he');
  });
}
