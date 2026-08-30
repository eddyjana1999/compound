import 'dart:ui' as ui;

import 'package:compound/domain/growth_engine.dart';
import 'package:compound/domain/models/calculation_input.dart';
import 'package:compound/domain/money.dart';
import 'package:compound/l10n/app_localizations.dart';
import 'package:compound/ui/formatting/money_format.dart';
import 'package:compound/ui/theme/app_theme.dart';
import 'package:compound/ui/widgets/share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The shared image, in both directions.
///
/// This is the one thing a PDF could not do: render Hebrew. If the card ever
/// comes back blank or boxed, this is where it shows up.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const engine = GrowthEngine();

  Future<void> pumpCard(
    WidgetTester tester,
    Locale locale,
    GlobalKey key,
  ) async {
    final currency = CurrencySpec(
      code: locale.languageCode == 'he' ? 'ILS' : 'USD',
      decimalDigits: 2,
    );
    final result = engine.calculate(
      CalculationInput(
        currency: currency,
        initialAmount: 2500000,
        monthlyContribution: 150000,
        annualReturn: 800,
        years: 30,
        annualManagementFee: 75,
        capitalGainsTaxRate: 2500,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The same unbounded constraints the real overlay gives it.
        home: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: RepaintBoundary(
                key: key,
                child: ShareCard(
                  result: result,
                  format: MoneyFormat(locale.toString(), currency),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 900)),
    );
    await tester.pumpAndSettle();
  }

  /// Returns the captured size, so a card taller than the screen can be
  /// proved to have been captured whole rather than clipped at the viewport.
  Future<(int width, int height, int bytes)> capture(
    WidgetTester tester,
    GlobalKey key,
  ) async {
    final object = key.currentContext!.findRenderObject()!;
    expect(object, isA<RenderRepaintBoundary>());
    final boundary = object as RenderRepaintBoundary;
    final logicalHeight = boundary.size.height;

    final captured = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final size = (image.width, image.height, data!.lengthInBytes);
      image.dispose();
      return size;
    });

    // The whole card, not just the part that happened to be on screen.
    expect(
      captured!.$2,
      closeTo(logicalHeight * 3, 3),
      reason: 'the image is shorter than the card — it was clipped',
    );
    // ignore: avoid_print
    print(
      'CAPTURED ${captured.$1}x${captured.$2} '
      '(card is ${boundary.size.width}x$logicalHeight logical), '
      '${(captured.$3 / 1024).round()} KB',
    );
    return captured;
  }

  testWidgets('the card renders and can be captured in English', (
    tester,
  ) async {
    final key = GlobalKey();
    await pumpCard(tester, const Locale('en'), key);

    expect(find.text('COMPOUND'), findsOneWidget);
    expect(find.textContaining('Total deposited'), findsOneWidget);
    expect(find.textContaining('Fees paid'), findsOneWidget);
    expect(find.textContaining('Not investment advice'), findsOneWidget);

    // Capturing an unpainted boundary yields nothing; a real card is large.
    expect((await capture(tester, key)).$3, greaterThan(20000));
    await binding.takeScreenshot('share-1-card-en');
  });

  testWidgets('and in Hebrew, right to left', (tester) async {
    final key = GlobalKey();
    await pumpCard(tester, const Locale('he'), key);

    expect(find.text('סך ההפקדות'), findsOneWidget);
    expect(find.text('רווחי ריבית דריבית'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('סך ההפקדות'))),
      TextDirection.rtl,
    );

    expect((await capture(tester, key)).$3, greaterThan(20000));
    await binding.takeScreenshot('share-2-card-he');
  });
}
