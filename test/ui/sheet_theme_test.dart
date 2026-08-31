import 'dart:io';

import 'package:compound/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The colour actually painted behind an open bottom sheet.
Color? sheetBackground(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Material),
        )
        .first,
  );
  return material.color;
}

void main() {
  group('a sheet that is open when the theme changes', () {
    testWidgets('repaints its background with the new theme', (tester) async {
      // Driven from outside the widget tree: a button that switches the theme
      // would sit behind the sheet's barrier, and tapping it would dismiss the
      // sheet instead — which is the one thing this test must not do.
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: mode,
          builder: (context, value, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => const SizedBox(height: 200),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final light = sheetBackground(tester);
      expect(light, AppTheme.light.colorScheme.surfaceContainerLowest);

      // The sheet stays open across the change. This is the case that broke:
      // its contents repainted and its background did not.
      mode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget,
          reason: 'the sheet should still be open');
      final dark = sheetBackground(tester);

      expect(
        dark,
        AppTheme.dark.colorScheme.surfaceContainerLowest,
        reason: 'the sheet kept the colour it was opened with',
      );
      expect(dark, isNot(light));
    });

    test('no call site hands a captured colour to a sheet route', () {
      // The widget test above proves the theme supplies the colour. It cannot
      // prove a call site is not overriding it: showModalBottomSheet stores
      // whatever `backgroundColor` it is passed as a field on the route, read
      // once at open time from the *caller's* context, so the sheet keeps that
      // colour when the theme flips underneath it. Guard the call sites.
      final offenders = <String>[];

      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].contains('showModalBottomSheet')) continue;
          // A prose mention is not a call site — app_theme.dart explains this
          // very bug in a comment, and scanning on from there walked straight
          // into the bottomSheetTheme that fixes it.
          if (lines[i].trimLeft().startsWith('//')) continue;
          // The argument list, up to the builder that opens the subtree.
          for (var j = i; j < lines.length && j < i + 12; j++) {
            if (lines[j].contains('builder:')) break;
            final arg = lines[j];
            if (arg.trimLeft().startsWith('//')) continue;
            if (arg.contains('backgroundColor:') || arg.contains('shape:')) {
              offenders.add('${file.path}:${j + 1}: ${arg.trim()}');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These pass a value that is captured when the sheet opens and '
            'never re-read. Move it to bottomSheetTheme in app_theme.dart:\n'
            '${offenders.join('\n')}',
      );
    });

    test('both themes define the sheet colour, so neither can fall back', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.bottomSheetTheme.backgroundColor, isNotNull);
        expect(theme.bottomSheetTheme.modalBackgroundColor, isNotNull);
      }
      expect(
        AppTheme.light.bottomSheetTheme.modalBackgroundColor,
        isNot(AppTheme.dark.bottomSheetTheme.modalBackgroundColor),
      );
    });
  });
}
