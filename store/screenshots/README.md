# Store screenshots

Generated, never hand-captured:

    flutter drive --driver=test_driver/integration_test.dart \
      --target=integration_test/store_screenshots_test.dart \
      -d "iPhone 16 Pro Max" --dart-define=SKIP_PRIVACY_PROMPTS=true

`6.9-inch` is 1320x2868 (iPhone 16 Pro Max), `6.7-inch` is 1290x2796 (iPhone 16 Plus).

The `SKIP_PRIVACY_PROMPTS` flag matters twice: it keeps the consent and tracking dialogs from
covering the app, and because consent is then never granted, no ads load — so no banner ends up in
a marketing image.

The history shown is seeded by the test, so the listing never depends on whatever happened to be
on someone's simulator. Re-run it after any UI change; a stale screenshot is a rejection.
