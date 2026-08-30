import 'package:compound/domain/growth_engine.dart';
import 'package:compound/domain/models/calculation_input.dart';
import 'package:compound/domain/money.dart';
import 'package:compound/l10n/app_localizations.dart';
import 'package:compound/share/share_calculation.dart';
import 'package:compound/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Exercises the path the button actually takes — through a real Overlay —
/// rather than pumping the card straight into the tree, which is what the
/// first test did and why it passed while the button failed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const engine = GrowthEngine();

  Future<void> run(WidgetTester tester, Locale locale) async {
    const usd = CurrencySpec(code: 'USD', decimalDigits: 2);
    final result = engine.calculate(const CalculationInput(
      currency: usd,
      initialAmount: 2500000,
      monthlyContribution: 100000,
      annualReturn: 1000,
      years: 20,
      annualManagementFee: 75,
      capitalGainsTaxRate: 2500,
    ));

    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          captured = context;
          return const Scaffold(body: SizedBox());
        }),
      ),
    );
    await tester.pumpAndSettle();

    Object? failure;
    int? bytes;
    // Not inside runAsync: the render pumps its own frames, and a test
    // binding only produces those while the test is pumping.
    // The widget stays pumped for the whole test, so the context is alive.
    // ignore: use_build_context_synchronously
    final render = const ShareCalculation().renderImage(captured, result);
    final pending = render
        .then((data) => bytes = data?.lengthInBytes)
        .catchError((Object e) {
      failure = e;
      return null;
    });
    for (var i = 0; i < 20 && bytes == null && failure == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await pending;
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('RENDER ${locale.languageCode}: bytes=$bytes failure=$failure');
    expect(failure, isNull, reason: 'rendering threw');
    expect(bytes, isNotNull, reason: 'rendering produced nothing');
    expect(bytes, greaterThan(20000));
  }

  testWidgets('the share button path renders in English',
      (tester) => run(tester, const Locale('en')));

  testWidgets('and in Hebrew', (tester) => run(tester, const Locale('he')));
}
