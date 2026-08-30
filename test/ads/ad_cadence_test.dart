import 'dart:io';

import 'package:compound/ads/ad_config.dart';
import 'package:compound/ads/ad_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cadence = InterstitialCadence(everyNCalculations: 3);

  group('when the full screen ad is due', () {
    test('never before the first calculation', () {
      expect(cadence.isDueAfter(0), isFalse);
    });

    test('not on the first two', () {
      expect(cadence.isDueAfter(1), isFalse);
      expect(cadence.isDueAfter(2), isFalse);
    });

    test('on every third', () {
      expect(cadence.isDueAfter(3), isTrue);
      expect(cadence.isDueAfter(6), isTrue);
      expect(cadence.isDueAfter(9), isTrue);
      expect(cadence.isDueAfter(300), isTrue);
    });

    test('and on nothing in between', () {
      for (final n in [4, 5, 7, 8, 10, 11, 100, 101]) {
        expect(cadence.isDueAfter(n), isFalse, reason: 'n = $n');
      }
    });

    test('fires exactly a third of the time over a long run', () {
      final due = [
        for (var n = 1; n <= 300; n++) if (cadence.isDueAfter(n)) n,
      ];
      expect(due.length, 100);
    });

    test('a cadence of one shows on every calculation', () {
      const everyTime = InterstitialCadence(everyNCalculations: 1);
      expect(everyTime.isDueAfter(1), isTrue);
      expect(everyTime.isDueAfter(2), isTrue);
    });
  });

  group('configuration', () {
    test('the shipped cadence is every third calculation', () {
      expect(AdConfig.calculationsPerInterstitial, 3);
    });

    test('privacy prompts are on unless a run explicitly opts out', () {
      // If this fails by default, a shipped build has stopped asking for
      // consent and tracking permission — an App Store rejection at best and
      // a GDPR problem at worst.
      expect(AdConfig.showPrivacyPrompts, isTrue);
    });

    test('a test run serves test ads and never the real ones', () {
      // Tests run unoptimised, so this is the debug path. If it ever fails,
      // a debug build is about to request real ads, which is what gets an
      // AdMob account suspended for invalid traffic.
      expect(AdConfig.useRealUnits, isFalse);
      expect(AdConfig.bannerUnitId, startsWith('ca-app-pub-3940256099942544/'));
      expect(
        AdConfig.interstitialUnitId,
        startsWith('ca-app-pub-3940256099942544/'),
      );
    });

    test('every placement on both platforms has a real unit', () {
      // Four units: banner and interstitial, iOS and Android. A missing one
      // is not an error — it just makes that placement silently dark in
      // release — so it has to be asserted rather than noticed.
      final file = File('lib/ads/ad_config.dart').readAsStringSync();
      for (final name in const [
        '_realBannerIos',
        '_realInterstitialIos',
        '_realBannerAndroid',
        '_realInterstitialAndroid',
      ]) {
        final match =
            RegExp("$name =\\s*'([^']*)'").firstMatch(file)?.group(1) ?? '';
        expect(match, isNotEmpty, reason: '$name has no unit id');
        expect(match, startsWith('ca-app-pub-3386708172616785/'), reason: name);
      }
    });

    test('an empty unit still serves nothing rather than a test ad', () {
      // The guard stays even though every slot is filled: it is what makes
      // adding a fifth placement safe by default.
      final file = File('lib/ads/ad_config.dart').readAsStringSync();
      expect(file, contains('return real.isEmpty ? null : real;'));
    });

    test('the two app ids are per-platform and neither is a Google test id',
        () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(plist, contains('ca-app-pub-3386708172616785~5617600204'));
      expect(manifest, contains('ca-app-pub-3386708172616785~6902761716'));
      expect(plist, isNot(contains('ca-app-pub-3940256099942544~')));
      expect(manifest, isNot(contains('ca-app-pub-3940256099942544~')));
    });
  });

  group('ads switched off', () {
    test('every call is a harmless no-op', () async {
      const service = NoOpAdService();
      await service.initialize();
      expect(service.banner(), isA<SizedBox>());
      service.preloadInterstitial();
      expect(await service.showInterstitial(), isFalse);
      service.dispose();
    });
  });
}
