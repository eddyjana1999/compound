import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ads/ad_config.dart';
import '../../ads/ad_service.dart';
import '../../ads/google_ad_service.dart';
import '../../data/calculation_repository.dart';
import '../../data/prefs_calculation_repository.dart';
import '../../data/saved_calculation.dart';
import '../../domain/growth_engine.dart';
import '../../iap/purchase_service.dart';
import '../../iap/store_purchase_service.dart';

/// Overridden in `main` once preferences have loaded, so nothing downstream
/// has to deal with an unopened store.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden at startup'),
);

final repositoryProvider = Provider<CalculationRepository>(
  (ref) => PrefsCalculationRepository(ref.watch(sharedPreferencesProvider)),
);

final engineProvider = Provider<GrowthEngine>((ref) => const GrowthEngine());

/// The saved calculations shown on the home screen, newest first.
class HistoryNotifier extends AsyncNotifier<List<SavedCalculation>> {
  @override
  Future<List<SavedCalculation>> build() =>
      ref.watch(repositoryProvider).load();

  Future<void> add(SavedCalculation calculation) async {
    final repo = ref.read(repositoryProvider);
    state = AsyncData(await repo.save(calculation));
  }

  Future<void> remove(String id) async {
    final repo = ref.read(repositoryProvider);
    state = AsyncData(await repo.delete(id));
  }

  Future<void> clear() async {
    final repo = ref.read(repositoryProvider);
    state = AsyncData(await repo.clear());
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<SavedCalculation>>(
  HistoryNotifier.new,
);

/// Everything the user can change about the app itself.
@immutable
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;

  /// Null means "follow the device", which is what most people want and what
  /// makes the app feel native in any of the eight languages.
  final Locale? locale;

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale, bool clearLocale = false}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'compound.themeMode';
  static const _localeKey = 'compound.locale';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeName = prefs.getString(_themeKey);
    final localeTag = prefs.getString(_localeKey);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      locale: localeTag == null ? null : Locale(localeTag),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(sharedPreferencesProvider).setString(_themeKey, mode.name);
  }

  Future<void> setLocale(Locale? locale) async {
    state = state.copyWith(locale: locale, clearLocale: locale == null);
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// The live ad network. Overridden with [NoOpAdService] in tests, which is
/// what keeps widget tests free of platform channels.
final adServiceProvider = Provider<AdService>((ref) {
  // The entire ad gate. Every ad surface asks this provider for its service,
  // so a Pro user gets a no-op everywhere at once — no screen can forget to
  // check, because no screen does the checking.
  if (ref.watch(isProProvider)) return const NoOpAdService();

  final service = GoogleAdService();
  ref.onDispose(service.dispose);
  return service;
});

const InterstitialCadence interstitialCadence = InterstitialCadence(
  everyNCalculations: AdConfig.calculationsPerInterstitial,
);

/// How many calculations this user has run, ever.
///
/// Persisted rather than held in memory: a counter that resets on every cold
/// start would show the full-screen ad far more often than every third
/// calculation, which is the sort of thing that gets an app one-star reviews.
class CalculationCounter extends Notifier<int> {
  static const String _key = 'compound.calculationCount';

  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_key) ?? 0;

  /// Records a finished calculation. Returns whether the full-screen ad is
  /// now due.
  Future<bool> record() async {
    final next = state + 1;
    state = next;
    await ref.read(sharedPreferencesProvider).setInt(_key, next);
    return interstitialCadence.isDueAfter(next);
  }
}

final calculationCounterProvider =
    NotifierProvider<CalculationCounter, int>(CalculationCounter.new);

/// Whether this user must be offered a way back into their ad privacy
/// choices. Required in the EU, false almost everywhere else — the settings
/// entry is hidden rather than greyed out when it is not needed.
final privacyOptionsRequiredProvider = FutureProvider<bool>(
  (ref) => ref.watch(adServiceProvider).privacyOptionsRequired(),
);

/// The currency the user last calculated in.
///
/// Null means "whatever this device spends in", which is right until the user
/// says otherwise — an Israeli phone should not have to pick shekels.
class PreferredCurrency extends Notifier<String?> {
  static const String _key = 'compound.currency';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  Future<void> set(String code) async {
    state = code;
    await ref.read(sharedPreferencesProvider).setString(_key, code);
  }
}

final preferredCurrencyProvider =
    NotifierProvider<PreferredCurrency, String?>(PreferredCurrency.new);

/// Whether this user has bought Pro.
///
/// Persisted locally. That is the right trade-off for a one-off unlock on a
/// calculator: the store is still the source of truth and Restore re-reads it,
/// but the app opens ad-free offline and without waiting on a network call.
class ProEntitlement extends Notifier<bool> {
  static const String _key = 'compound.pro';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> grant() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final isProProvider =
    NotifierProvider<ProEntitlement, bool>(ProEntitlement.new);

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = StorePurchaseService(
    // Fires for a fresh purchase, a restore, and for a deferred purchase that
    // clears while the app is open — all three mean the same thing here.
    onEntitled: () => ref.read(isProProvider.notifier).grant(),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// The price to show, straight from the store. Null hides the upsell entirely
/// rather than showing a price the app made up.
final proOfferProvider = FutureProvider<ProOffer?>((ref) async {
  if (ref.watch(isProProvider)) return null;
  return ref.watch(purchaseServiceProvider).offer();
});
