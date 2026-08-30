import 'dart:convert';

import 'package:compound/app.dart';
import 'package:compound/ui/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Produces the App Store and Play listing screenshots.
///
/// Not the walkthrough test wearing a different hat: a listing wants the app
/// at its best — history already populated, the strongest screen first — while
/// the walkthrough deliberately starts from nothing. Run it with
/// `--dart-define=SKIP_PRIVACY_PROMPTS=true`, which also means no ads load, so
/// no banner ends up in a marketing image.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String entry({
    required String id,
    required String createdAt,
    required int initial,
    required int monthly,
    required int annualReturn,
    required int years,
    int fee = 0,
    int tax = 0,
  }) {
    return jsonEncode({
      'v': 1,
      'id': id,
      'createdAt': createdAt,
      'currencyCode': 'USD',
      'currencyDigits': 2,
      'initialAmount': initial,
      'monthlyContribution': monthly,
      'annualReturn': annualReturn,
      'years': years,
      'annualManagementFee': fee,
      'capitalGainsTaxRate': tax,
      'rateConversion': 'geometric',
    });
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1400)),
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  /// The text field belonging to [label].
  ///
  /// By label, never by index: a ListView unbuilds rows that scroll out of
  /// view, so `find.byType(TextField).at(4)` means different fields at
  /// different scroll positions and on different sized phones.
  Finder fieldFor(String label) => find.descendant(
        of: find
            .ancestor(of: find.text(label), matching: find.byType(Column))
            .first,
        matching: find.byType(TextField),
      );

  /// Brings [target] into the viewport before touching it.
  ///
  /// A ListView only builds what is on screen, so `find.text` cannot see a row
  /// below the fold — and how far down the fold sits depends on the device and
  /// on whether the keyboard is up. Without this, a test that passes on a
  /// 6.3" phone fails on a 6.9" one.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('listing screenshots', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('compound.calculationCount', 0);
    await prefs.remove('compound.locale');
    await prefs.remove('compound.currency');
    await prefs.setStringList('compound.history.v1', [
      entry(
          id: 's1',
          createdAt: '2026-08-29T10:00:00.000Z',
          initial: 2500000,
          monthly: 150000,
          annualReturn: 800,
          years: 30,
          fee: 75,
          tax: 2500),
      entry(
          id: 's2',
          createdAt: '2026-08-21T10:00:00.000Z',
          initial: 500000,
          monthly: 100000,
          annualReturn: 700,
          years: 20),
      entry(
          id: 's3',
          createdAt: '2026-08-12T10:00:00.000Z',
          initial: 10000000,
          monthly: 0,
          annualReturn: 500,
          years: 10,
          tax: 2500),
      entry(
          id: 's4',
          createdAt: '2026-08-04T10:00:00.000Z',
          initial: 0,
          monthly: 50000,
          annualReturn: 900,
          years: 25,
          fee: 100),
      entry(
          id: 's5',
          createdAt: '2026-07-28T10:00:00.000Z',
          initial: 1500000,
          monthly: 75000,
          annualReturn: 600,
          years: 15,
          tax: 2000),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CompoundApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 1 — the app with something in it.
    await shoot(tester, 'store-1-home');

    // 2 — the inputs, filled in.
    await tester.tap(find.text('New calculation'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '25000');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '1500');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), '8');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(3), '30');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Advanced'));
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Capital gains tax'));
    await tester.enterText(fieldFor('Annual management fee'), '0.75');
    await tester.pumpAndSettle();
    await tester.enterText(fieldFor('Capital gains tax'), '25');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await shoot(tester, 'store-2-input');

    // 3 — the payoff.
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await shoot(tester, 'store-3-results');

    // 4 — the chart.
    await tester.drag(find.byType(ListView).last, const Offset(0, -430));
    await shoot(tester, 'store-4-chart');

    // 5 — 49 currencies, which is the reason it is a *universal* calculator.
    await tester.pageBack();
    await tester.pumpAndSettle();
    // Coming back from the results leaves the form scrolled to the advanced
    // section, where the amount fields are no longer built.
    await tester.drag(find.byType(ListView).last, const Offset(0, 700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').first);
    await shoot(tester, 'store-5-currencies');
  });
}
