import 'dart:convert';

import 'package:compound/app.dart';
import 'package:compound/ui/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stars, swipe-to-delete and the selection mode, driven end to end.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String entry(String id, int day, int initial, int years) => jsonEncode({
        'v': 2,
        'id': id,
        'createdAt': '2026-08-${day.toString().padLeft(2, '0')}T10:00:00.000Z',
        'currencyCode': 'USD',
        'currencyDigits': 2,
        'initialAmount': initial,
        'monthlyContribution': 50000,
        'annualReturn': 700,
        'years': years,
        'annualManagementFee': 0,
        'capitalGainsTaxRate': 0,
        'rateConversion': 'geometric',
        'favourite': false,
      });

  Future<void> launch(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('compound.calculationCount', 0);
    await prefs.remove('compound.locale');
    await prefs.setStringList('compound.history.v1', [
      entry('newest', 29, 100000, 10),
      entry('middle', 20, 200000, 20),
      entry('oldest', 10, 300000, 30),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CompoundApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1000)));
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  /// The years pill is the one bit of text unique to each card.
  Finder cardFor(String years) => find.text(years);

  int rowOf(WidgetTester tester, String years) {
    final positions = <double>[];
    for (final y in const ['10 years', '20 years', '30 years']) {
      positions.add(tester.getTopLeft(cardFor(y)).dy);
    }
    final mine = tester.getTopLeft(cardFor(years)).dy;
    final sorted = [...positions]..sort();
    return sorted.indexOf(mine);
  }

  testWidgets('a star pins its calculation to the top', (tester) async {
    await launch(tester);

    // Newest first to begin with: 10, 20, 30 years.
    expect(rowOf(tester, '30 years'), 2);

    // Star the oldest one.
    await tester.tap(find.byIcon(Icons.star_border_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(rowOf(tester, '30 years'), 0,
        reason: 'the starred calculation should be pinned above newer ones');

    await shoot(tester, 'fav-1-starred');

    // Unstarring puts it back where the date says it belongs.
    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();
    expect(rowOf(tester, '30 years'), 2);
  });

  testWidgets('long press starts a selection and deletes several at once',
      (tester) async {
    await launch(tester);

    await tester.longPress(cardFor('20 years'));
    await tester.pumpAndSettle();

    // The header becomes the count, and the stars step aside so there are
    // never two different toggles on one row.
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);

    await tester.tap(cardFor('30 years'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await shoot(tester, 'fav-2-selection');

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Delete the selected calculations?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(cardFor('20 years'), findsNothing);
    expect(cardFor('30 years'), findsNothing);
    expect(cardFor('10 years'), findsOneWidget);
    // Selection ends with the selection.
    expect(find.textContaining('selected'), findsNothing);
  });

  testWidgets('deselecting the last one leaves selection mode',
      (tester) async {
    await launch(tester);
    await tester.longPress(cardFor('20 years'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(cardFor('20 years'));
    await tester.pumpAndSettle();
    // No selection bar offering to delete nothing.
    expect(find.textContaining('selected'), findsNothing);
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(3));
  });

  testWidgets('a swipe deletes one and offers it back', (tester) async {
    await launch(tester);

    await tester.drag(cardFor('20 years'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(cardFor('20 years'), findsNothing);

    // The only destructive action that does not ask first, so it is the one
    // that has to offer a way back.
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(cardFor('20 years'), findsOneWidget);
  });
}
