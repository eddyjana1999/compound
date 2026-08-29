import 'dart:io' show Platform;

/// Which ad units the app asks for, and how often the video plays.
///
/// No `google_mobile_ads` import here on purpose: this file is plain Dart so
/// the numbers and the policy can be read, tested and reviewed without
/// dragging the SDK in.
class AdConfig {
  AdConfig._();

  /// Real ad units are opt-in at build time:
  ///
  ///   flutter build ipa --dart-define=USE_REAL_AD_UNITS=true \
  ///     --dart-define=AD_BANNER_IOS=ca-app-pub-…/… \
  ///     --dart-define=AD_INTERSTITIAL_IOS=ca-app-pub-…/…
  ///
  /// A debug build, a CI build, or a release someone forgot to configure all
  /// serve Google's test ads. Shipping test IDs costs nothing; shipping real
  /// IDs from a debug build gets the AdMob account suspended for invalid
  /// traffic, so the default is the safe one.
  static const bool useRealUnits =
      bool.fromEnvironment('USE_REAL_AD_UNITS');

  static const String _realBannerAndroid =
      String.fromEnvironment('AD_BANNER_ANDROID');
  static const String _realBannerIos =
      String.fromEnvironment('AD_BANNER_IOS');
  static const String _realInterstitialAndroid =
      String.fromEnvironment('AD_INTERSTITIAL_ANDROID');
  static const String _realInterstitialIos =
      String.fromEnvironment('AD_INTERSTITIAL_IOS');

  // Google's published test units. Safe to commit; they never bill anyone.
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';
  // The plain full-screen interstitial, not the video one. In production
  // this distinction is not yours to make: a real interstitial unit serves
  // whichever creative wins the auction, static or video. Restrict it in the
  // AdMob console under the ad unit's settings if you want static only.
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  static bool get _isIos => Platform.isIOS;

  static String get bannerUnitId {
    if (useRealUnits) {
      final real = _isIos ? _realBannerIos : _realBannerAndroid;
      if (real.isNotEmpty) return real;
    }
    return _isIos ? _testBannerIos : _testBannerAndroid;
  }

  static String get interstitialUnitId {
    if (useRealUnits) {
      final real = _isIos ? _realInterstitialIos : _realInterstitialAndroid;
      if (real.isNotEmpty) return real;
    }
    return _isIos ? _testInterstitialIos : _testInterstitialAndroid;
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
