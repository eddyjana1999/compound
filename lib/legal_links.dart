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
}
