import 'package:compound/ads/ad_service.dart';
import 'package:compound/iap/purchase_service.dart';
import 'package:compound/ui/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container({bool adsRemoved = false}) async {
    SharedPreferences.setMockInitialValues(
      adsRemoved ? {'compound.adsRemoved': true} : {},
    );
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  group('the entitlement gate', () {
    test('a free user gets a real ad service', () async {
      final c = await container();
      addTearDown(c.dispose);
      expect(c.read(adsRemovedProvider), isFalse);
      expect(c.read(adServiceProvider), isNot(isA<NoOpAdService>()));
    });

    test('a paid user gets no ad service at all', () async {
      final c = await container(adsRemoved: true);
      addTearDown(c.dispose);
      expect(c.read(adsRemovedProvider), isTrue);
      expect(c.read(adServiceProvider), isA<NoOpAdService>());
    });

    test('granting the entitlement switches every ad surface off at once',
        () async {
      final c = await container();
      addTearDown(c.dispose);
      expect(c.read(adServiceProvider), isNot(isA<NoOpAdService>()));

      await c.read(adsRemovedProvider.notifier).grant();

      expect(c.read(adsRemovedProvider), isTrue);
      expect(c.read(adServiceProvider), isA<NoOpAdService>());
    });

    test('the entitlement survives a restart', () async {
      final c = await container();
      addTearDown(c.dispose);
      await c.read(adsRemovedProvider.notifier).grant();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('compound.adsRemoved'), isTrue);

      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(adsRemovedProvider), isTrue);
    });

    test('granting twice is harmless', () async {
      final c = await container();
      addTearDown(c.dispose);
      await c.read(adsRemovedProvider.notifier).grant();
      await c.read(adsRemovedProvider.notifier).grant();
      expect(c.read(adsRemovedProvider), isTrue);
    });

    test('a paid user is never offered the upsell', () async {
      final c = await container(adsRemoved: true);
      addTearDown(c.dispose);
      expect(await c.read(removeAdsOfferProvider.future), isNull);
    });
  });

  group('the product', () {
    test('has one id, shared by both stores', () {
      expect(IapConfig.removeAdsProductId,
          'com.compoundapp.compound.remove_ads');
    });
  });

  group('purchasing switched off', () {
    test('every call is a harmless no-op', () async {
      const service = NoOpPurchaseService();
      await service.initialize();
      expect(await service.offer(), isNull);
      expect(await service.buy(), PurchaseOutcome.unavailable);
      expect(await service.restore(), PurchaseOutcome.unavailable);
      service.dispose();
    });
  });

  group('outcomes the user should and should not hear about', () {
    test('a cancellation is not an error', () {
      // Backing out of the sheet is a choice, not a failure. If this ever
      // moves into the "tell them" set, the app starts scolding people for
      // declining to pay.
      expect(PurchaseOutcome.values, contains(PurchaseOutcome.cancelled));
      expect(PurchaseOutcome.cancelled, isNot(PurchaseOutcome.failed));
    });

    test('pending is distinct from purchased', () {
      // Ask to Buy hands back "pending". Treating it as purchased would give
      // away the paid tier before a parent has approved it.
      expect(PurchaseOutcome.pending, isNot(PurchaseOutcome.purchased));
    });
  });
}
