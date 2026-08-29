import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'ui/screens/home_screen.dart';
import 'ui/state/providers.dart';
import 'ui/theme/app_theme.dart';

class CompoundApp extends ConsumerStatefulWidget {
  const CompoundApp({super.key});

  @override
  ConsumerState<CompoundApp> createState() => _CompoundAppState();
}

class _CompoundAppState extends ConsumerState<CompoundApp> {
  @override
  void initState() {
    super.initState();
    // Fire and forget: the first frame must not wait on the ad SDK, and every
    // ad surface already renders as nothing until it has something to show.
    ref.read(adServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
