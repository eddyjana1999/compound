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

  /// The list as it will look, applied before anything is awaited.
  ///
  /// This is not an optimisation. `Dismissible` asserts that the entry it
  /// just dismissed is gone from the list by the end of that frame, and
  /// waiting on storage first means it is still there — which throws, freezes
  /// the frame, and leaves the gesture arena in a state where later taps go
  /// to the wrong place.
  void _apply(List<SavedCalculation> entries) {
    state = AsyncData(entries..sort(SavedCalculation.compare));
  }

  List<SavedCalculation> get _current =>
      [...state.value ?? const <SavedCalculation>[]];

  Future<void> add(SavedCalculation calculation) async {
    _apply(_current
      ..removeWhere((e) => e.id == calculation.id)
      ..add(calculation));
    state = AsyncData(await ref.read(repositoryProvider).save(calculation));
  }

  Future<void> remove(String id) async {
    _apply(_current..removeWhere((e) => e.id == id));
    state = AsyncData(await ref.read(repositoryProvider).delete(id));
  }

  Future<void> removeAll(Set<String> ids) async {
    _apply(_current..removeWhere((e) => ids.contains(e.id)));
    state = AsyncData(await ref.read(repositoryProvider).deleteAll(ids));
  }

  Future<void> setFavourite(String id, bool favourite) async {
    final entries = _current;
    final index = entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      entries[index] = entries[index].copyWith(favourite: favourite);
      _apply(entries);
    }
    state = AsyncData(
        await ref.read(repositoryProvider).setFavourite(id, favourite));
  }

  Future<void> clear() async {
    _apply([]);
    state = AsyncData(await ref.read(repositoryProvider).clear());
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
  // The entire gate for the paid tier. Every ad surface asks this provider
  // for its service, so a user who has paid gets a no-op everywhere at once —
  // no screen can forget to check, because no screen does the checking.
  if (ref.watch(adsRemovedProvider)) return const NoOpAdService();

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

/// Whether this user has paid to remove the ads.
///
/// Persisted locally. That is the right trade-off for a one-off unlock on a
/// calculator: the store is still the source of truth and Restore re-reads it,
/// but the app opens ad-free offline and without waiting on a network call.
class AdsRemoved extends Notifier<bool> {
  static const String _key = 'compound.adsRemoved';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> grant() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final adsRemovedProvider = NotifierProvider<AdsRemoved, bool>(AdsRemoved.new);

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = StorePurchaseService(
    // Fires for a fresh purchase, a restore, and for a deferred purchase that
    // clears while the app is open — all three mean the same thing here.
    onEntitled: () => ref.read(adsRemovedProvider.notifier).grant(),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// The price to show, straight from the store. Null hides the upsell entirely
/// rather than showing a price the app made up.
final removeAdsOfferProvider = FutureProvider<RemoveAdsOffer?>((ref) async {
  if (ref.watch(adsRemovedProvider)) return null;
  return ref.watch(purchaseServiceProvider).offer();
});
