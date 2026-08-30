import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;

/// Which ad units the app asks for, and how often the full-screen ad plays.
///
/// No `google_mobile_ads` import here on purpose: this file is plain Dart so
/// the ids and the policy can be read and reviewed without dragging the SDK
/// in.
class AdConfig {
  AdConfig._();

  /// Real units in a release build, Google's test units otherwise — decided
  /// by the build itself, not by a flag someone has to remember.
  ///
  /// The direction matters in both ways. A debug build that asks for real
  /// units generates invalid traffic and gets the AdMob account suspended; a
  /// release build serving units stamped "Test Ad" is an App Store rejection.
  /// Neither can happen now, because neither is a choice.
  static bool get useRealUnits => kReleaseMode;

  // ---------------------------------------------------------------------
  // Real units. Not secrets — they ship inside the app bundle either way.
  // An empty string means "not created in AdMob yet", and the app then
  // serves nothing at all in release rather than serving a test ad.
  // ---------------------------------------------------------------------
  static const String _realBannerIos = 'ca-app-pub-3386708172616785/6559041580';
  static const String _realInterstitialIos = '';
  static const String _realBannerAndroid = '';
  static const String _realInterstitialAndroid = '';

  // Google's published test units. Safe to commit; they never bill anyone.
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  static bool get _isIos => Platform.isIOS;

  /// The banner unit, or null when a release build has no real one to use.
  static String? get bannerUnitId {
    if (!useRealUnits) return _isIos ? _testBannerIos : _testBannerAndroid;
    final real = _isIos ? _realBannerIos : _realBannerAndroid;
    return real.isEmpty ? null : real;
  }

  /// The full-screen unit, or null when a release build has no real one.
  static String? get interstitialUnitId {
    if (!useRealUnits) {
      return _isIos ? _testInterstitialIos : _testInterstitialAndroid;
    }
    final real = _isIos ? _realInterstitialIos : _realInterstitialAndroid;
    return real.isEmpty ? null : real;
  }

  /// Show the full-screen ad after every third calculation.
  static const int calculationsPerInterstitial = 3;

  /// Whether to raise the privacy prompts: Google's consent form and the iOS
  /// tracking dialog.
  ///
  /// Off only for automated runs. Both are overlays the app does not own, so
  /// they sit on top of everything and swallow the integration tests' taps:
  ///
  ///   flutter drive … --dart-define=SKIP_PRIVACY_PROMPTS=true
  ///
  /// This suppresses the *display* only. Consent is still requested and
  /// `canRequestAds` is still honoured — which means a run with prompts off
  /// serves no ads at all, because consent was never granted. That is the
  /// safe direction and it is deliberate: the flag can hide an ad that should
  /// have shown, never show one that should have been withheld. A shipped
  /// build never sets it, and a test asserts that.
  static const bool showPrivacyPrompts =
      !bool.fromEnvironment('SKIP_PRIVACY_PROMPTS');
}
