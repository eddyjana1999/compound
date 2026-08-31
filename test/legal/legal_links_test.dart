import 'package:compound/legal_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the legal URLs', () {
    // These are the links App Review taps. A broken one is a rejection, and
    // nothing else in the build would notice.
    test('are absolute https addresses', () {
      for (final url in [LegalLinks.privacy, LegalLinks.terms]) {
        final uri = Uri.tryParse(url);
        expect(uri, isNotNull, reason: url);
        expect(uri!.isAbsolute, isTrue, reason: url);
        expect(uri.scheme, 'https', reason: url);
        expect(uri.host, isNotEmpty, reason: url);
      }
    });

    test('are not placeholders', () {
      for (final url in [LegalLinks.privacy, LegalLinks.terms]) {
        expect(url, isNot(contains('YOUR_USERNAME')));
        expect(url, isNot(contains('example.com')));
      }
    });

    test('point at two different pages', () {
      expect(LegalLinks.privacy, isNot(LegalLinks.terms));
      expect(LegalLinks.privacy, endsWith('privacy.html'));
      expect(LegalLinks.terms, endsWith('terms.html'));
    });
  });
}
