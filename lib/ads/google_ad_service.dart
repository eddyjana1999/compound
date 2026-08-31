import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';

/// The only file in the app that imports `google_mobile_ads`.
///
/// Everything else — screens, providers, tests — talks to [AdService]. That
/// keeps the SDK swappable, keeps widget tests free of platform channels, and
/// means there is exactly one place to audit when the ad policy changes.
class GoogleAdService implements AdService {
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  bool _initialised = false;

  /// False until consent has been gathered and the SDK started. Every ad
  /// surface checks it, so a user who declines simply never sees an ad
  /// request go out — not one that goes out non-personalised.
  ///
  /// A notifier rather than a bool. This is set asynchronously, seconds after
  /// the first frame, once consent and the tracking prompt have been answered
  /// — and the screens reach it through a plain Riverpod Provider that hands
  /// back one instance and never notifies. As a bare field it flipped to true
  /// with nothing listening, so `banner()` was called once during startup,
  /// answered `SizedBox.shrink()`, and was never asked again. No banner could
  /// ever appear, in any build.
  @visibleForTesting
  final ValueNotifier<bool> adsAllowed = ValueNotifier(false);

  @override
  Future<void> initialize() async {
    if (_initialised) return;
    _initialised = true;

    // Order is a legal requirement, not a preference:
    //   1. GDPR consent, before anything is requested;
    //   2. iOS tracking permission, before a personalised ad is requested;
    //   3. only then start the SDK, and only if consent allows it.
    await _gatherConsent();
    await _requestTrackingPermission();

    if (!await _canRequestAds()) return;

    await MobileAds.instance.initialize();
    adsAllowed.value = true;
    preloadInterstitial();
  }

  /// Runs Google's User Messaging Platform, which shows the EU consent form
  /// when the user's region requires one and does nothing anywhere else.
  ///
  /// Never rethrows. A consent form that fails to load — no network, an
  /// outage — must leave the user with a working calculator and no ads,
  /// never with a broken launch.
  Future<void> _gatherConsent() async {
    final completer = Completer<void>();

    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          if (!AdConfig.showPrivacyPrompts) {
            finish();
            return;
          }
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((_) => finish());
          } on Object {
            finish();
          }
        },
        (_) => finish(),
      );
    } on Object {
      finish();
    }

    return completer.future;
  }

  /// The iOS tracking prompt, asked once and never again.
  ///
  /// Only when the status is still undetermined: re-asking is impossible
  /// anyway once the user has answered, and calling it regardless would just
  /// delay the first frame for nothing.
  Future<void> _requestTrackingPermission() async {
    if (!Platform.isIOS || !AdConfig.showPrivacyPrompts) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;

      // iOS silently refuses to present the prompt unless the app is
      // actually active: the call returns notDetermined and nothing is shown.
      // A fixed 300ms was a guess that happened to work when the consent
      // check was slow enough to cover the gap. Wait for the real signal
      // instead, and give up rather than hang if it never arrives.
      await _whenResumed();
      await AppTrackingTransparency.requestTrackingAuthorization();
    } on Object {
      // A declined or unavailable prompt is a normal outcome, not an error.
    }
  }

  /// Resolves once the app is foregrounded, or after five seconds.
  ///
  /// Apple rejects an app that declares tracking and never presents the
  /// prompt, so the cost of asking too early is a rejection; the cost of
  /// waiting is a second of delay before the first ad request.
  Future<void> _whenResumed() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;

    const step = Duration(milliseconds: 100);
    var waited = Duration.zero;
    const limit = Duration(seconds: 5);
    while (binding.lifecycleState != AppLifecycleState.resumed &&
        waited < limit) {
      await Future<void>.delayed(step);
      waited += step;
    }
  }

  Future<bool> _canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } on Object {
      // Nothing useful to tell the user if the form itself will not open.
    }
  }

  @override
  Widget banner() => ValueListenableBuilder<bool>(
        valueListenable: adsAllowed,
        builder: (_, allowed, _) =>
            allowed ? const AnchoredBanner() : const SizedBox.shrink(),
      );

  @override
  void preloadInterstitial() {
    if (!adsAllowed.value) return;
    if (_interstitial != null || _loadingInterstitial) return;

    // No real unit for this placement on this platform yet. Showing nothing
    // is the only safe option: a release build serving an ad stamped
    // "Test Ad" is an App Store rejection.
    final unitId = AdConfig.interstitialUnitId;
    if (unitId == null) return;

    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          // No retry storm: a failed fill is normal, and the next calculation
          // asks again. Hammering the network here would burn battery for an
          // ad nobody is waiting on.
          _loadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      // Nothing loaded — get one ready for next time rather than blocking the
      // user while it downloads.
      preloadInterstitial();
      return false;
    }

    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preloadInterstitial();
      },
    );

    await ad.show();
    return true;
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
    adsAllowed.dispose();
  }
}

/// A banner sized to the device width, loaded once and disposed with the
/// widget.
///
/// Reserves nothing until the ad is ready, so a slow or absent fill leaves
/// the screen exactly as it would look with ads switched off.
class AnchoredBanner extends StatefulWidget {
  const AnchoredBanner({super.key});

  @override
  State<AnchoredBanner> createState() => _AnchoredBannerState();
}

class _AnchoredBannerState extends State<AnchoredBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  int _loadedForWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width != _loadedForWidth) {
      _loadedForWidth = width;
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    final unitId = AdConfig.bannerUnitId;
    if (unitId == null) return;

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null || !mounted) return;

    final previous = _ad;
    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _loaded = false);
        },
      ),
    );

    _ad = ad;
    await ad.load();
    previous?.dispose();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
