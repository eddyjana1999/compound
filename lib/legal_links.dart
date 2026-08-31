/// Where the app's legal pages live.
///
/// Plain constants, not build-time flags. They are public URLs on a public
/// site — there is nothing to keep out of the repository, and a link that
/// only exists when someone remembers to pass a define is a link that ships
/// broken. App Review taps these.
class LegalLinks {
  LegalLinks._();

  static const String privacy =
      'https://eddyjana1999.github.io/compound/privacy.html';
  static const String terms =
      'https://eddyjana1999.github.io/compound/terms.html';

  /// The App Store record's numeric id, from its App Store Connect URL.
  /// Both links below 404 until the listing is public — which is correct, and
  /// is why neither is shown anywhere a reviewer is asked to tap it.
  static const String _appleId = '6807040692';

  /// The store page, for sharing.
  static const String appStore = 'https://apps.apple.com/app/id$_appleId';

  /// Straight into the review composer rather than the store page, so the
  /// person who meant to leave a rating does not have to find the button.
  static const String writeReview =
      'https://apps.apple.com/app/id$_appleId?action=write-review';
}
