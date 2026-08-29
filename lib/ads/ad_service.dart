import 'package:flutter/widgets.dart';

/// What the app is allowed to ask of the ad network.
///
/// An interface so no screen imports the SDK, and so widget tests run without
/// a platform channel. The only implementation that touches
/// `google_mobile_ads` is [GoogleAdService].
abstract class AdService {
  /// Gathers consent, asks for tracking permission, then starts the SDK.
  ///
  /// Deliberately one call: the order matters legally — GDPR consent before
  /// anything is requested, iOS tracking permission before a personalised ad
  /// is requested — and a caller that could get the order wrong should not be
  /// given the chance.
  Future<void> initialize();

  /// Whether this user must be offered a way back into their ad privacy
  /// choices. Required in the EU; false almost everywhere else, and the
  /// settings entry is hidden when it is.
  Future<bool> privacyOptionsRequired();

  /// Reopens the consent form so a user can change their mind.
  Future<void> showPrivacyOptions();

  /// A bottom-anchored banner. Returns an empty box until one has loaded, so
  /// the layout never jumps and callers never branch on readiness.
  Widget banner();

  /// Fetches the next full-screen ad ahead of time. Showing an ad that has
  /// not loaded does nothing, so this is what makes the third calculation
  /// actually produce one.
  void preloadInterstitial();

  /// Shows the loaded full-screen ad. Returns whether one was actually shown.
  Future<bool> showInterstitial();

  void dispose();
}

/// Used in tests and anywhere ads are switched off. Every method is a
/// deliberate no-op rather than a throw: turning ads off must never be able
/// to break a screen.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Widget banner() => const SizedBox.shrink();

  @override
  void preloadInterstitial() {}

  @override
  Future<bool> showInterstitial() async => false;

  @override
  void dispose() {}
}

/// Counts finished calculations and says when the full-screen ad is due.
///
/// Pure logic, kept out of the SDK-facing class so the cadence — the part
/// that decides how often a user is interrupted — can be unit tested.
class InterstitialCadence {
  const InterstitialCadence({required this.everyNCalculations})
      : assert(everyNCalculations > 0);

  final int everyNCalculations;

  /// True on the 3rd, 6th, 9th … calculation, never on the 0th.
  bool isDueAfter(int completedCalculations) =>
      completedCalculations > 0 &&
      completedCalculations % everyNCalculations == 0;
}
