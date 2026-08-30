/// Where the paywall's footer links point.
///
/// Injected at build time rather than hardcoded, because the URLs depend on
/// where the pages end up hosted:
///
///   --dart-define=TERMS_URL=https://you.github.io/compound/terms.html
///   --dart-define=PRIVACY_URL=https://you.github.io/compound/privacy.html
///
/// Unset, the links are hidden rather than shown broken. A dead legal link on
/// a paywall is worse than no link — it is one of the things App Review
/// actually taps.
class LegalLinks {
  LegalLinks._();

  static const String terms = String.fromEnvironment('TERMS_URL');
  static const String privacy = String.fromEnvironment('PRIVACY_URL');

  static bool get hasTerms => terms.startsWith('https://');
  static bool get hasPrivacy => privacy.startsWith('https://');

  /// True once both are set. The store listing needs the privacy URL anyway,
  /// so shipping without these is a configuration mistake, not a choice.
  static bool get configured => hasTerms && hasPrivacy;
}
