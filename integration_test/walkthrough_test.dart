import 'package:compound/app.dart';
import 'package:compound/ui/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Walks the whole app on a real device and captures each screen.
///
/// Doubles as the end-to-end smoke test: if any of these finders stop
/// resolving, a screen has stopped rendering what it promises.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launch(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    // Everything the app persists is reset here. These tests share one app
    // install, so without this the language the RTL test picks leaks into the
    // next test and its finders stop matching — which is exactly what
    // happened before this line existed.
    await prefs.setInt('compound.calculationCount', 0);
    await prefs.remove('compound.locale');
    await prefs.remove('compound.currency');
    await prefs.remove('compound.themeMode');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CompoundApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Lets the real device finish painting before the surface is captured.
  ///
  /// `pumpAndSettle` settles the widget tree, but the screenshot comes off
  /// the device surface a moment later — without this, transitions and the
  /// count-up on the results header are caught mid-flight.
  Future<void> settleAndShoot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
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

  testWidgets('home, input, advanced, results', (tester) async {
    await launch(tester);

    expect(find.text('Your calculations'), findsOneWidget);
    await settleAndShoot(tester, '01-home');

    // Into the input screen.
    await tester.tap(find.text('New calculation'));
    await tester.pumpAndSettle();
    expect(find.text('Starting amount'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '25000');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '1500');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), '8');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(3), '30');
    await tester.pumpAndSettle();
    await settleAndShoot(tester, '02-input');

    // Open the advanced options and fill in fee and tax.
    await reveal(tester, find.text('Advanced'));
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Capital gains tax'));
    await tester.enterText(fieldFor('Annual management fee'), '0.75');
    await tester.pumpAndSettle();
    await tester.enterText(fieldFor('Capital gains tax'), '25');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await settleAndShoot(tester, '03-advanced');

    // Calculate.
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Results'), findsOneWidget);
    // The rate the projection assumed must travel with the result.
    expect(find.text('8% per year'), findsOneWidget);
    expect(find.text('Total deposited'), findsOneWidget);
    expect(find.text('Compound interest earned'), findsOneWidget);
    expect(find.text('Fees paid'), findsOneWidget);
    expect(find.text('Tax paid'), findsOneWidget);
    await settleAndShoot(tester, '04-results');

    // The chart sits below the fold.
    await tester.drag(find.byType(ListView).last, const Offset(0, -420));
    await tester.pumpAndSettle();
    await settleAndShoot(tester, '05-chart');
  });

  testWidgets('right to left layout in Hebrew', (tester) async {
    await launch(tester);

    // Switch the app language through the settings sheet, the same way a
    // user would, rather than forcing a locale the app never sets itself.
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('עברית'));
    await tester.pumpAndSettle();

    // Close the sheet through its own Navigator rather than by tapping a
    // guessed point above it. The sheet's height changes whenever a row is
    // added to settings, and a coordinate that used to land on the scrim
    // silently starts landing inside the sheet.
    Navigator.of(tester.element(find.text('עברית'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('החישובים שלך'), findsOneWidget);
    await settleAndShoot(tester, '06-home-rtl');

    await tester.tap(find.text('חישוב חדש'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '50000');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '2000');
    await tester.pumpAndSettle();
    await settleAndShoot(tester, '07-input-rtl');

    await tester.tap(find.text('חשב'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('תוצאות'), findsOneWidget);
    await settleAndShoot(tester, '08-results-rtl');
  });

  testWidgets('choosing the currency for a calculation', (tester) async {
    await launch(tester);

    await tester.tap(find.text('New calculation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '10000');
    await tester.pumpAndSettle();

    // The currency code in front of the amount is the control.
    expect(find.text('USD'), findsNWidgets(2));
    await tester.tap(find.text('USD').first);
    await tester.pumpAndSettle();
    expect(find.text('Currency'), findsWidgets);
    await settleAndShoot(tester, '10-currency-picker');

    // Narrow the list rather than scrolling it.
    await tester.enterText(find.byType(TextField).last, 'EUR');
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR').last);
    await tester.pumpAndSettle();

    expect(find.text('EUR'), findsNWidgets(2));
    expect(find.text('USD'), findsNothing);
    await settleAndShoot(tester, '11-input-eur');

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Results'), findsOneWidget);
    // The whole result is now denominated in the chosen currency.
    expect(find.textContaining('€'), findsWidgets);
    await settleAndShoot(tester, '12-results-eur');
  });
}
