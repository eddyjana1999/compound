# Running Compound

## The short version

```bash
cd ~/Desktop/compound
open -a Simulator
flutter run
```

`flutter run` picks the booted simulator on its own. Once it is up:
`r` hot reload · `R` hot restart · `q` quit.

## Picking a specific device

```bash
flutter devices
flutter run -d "iPhone 16 Pro"
```

## First launch asks for consent

On a clean install the Google consent form appears, then the iOS tracking prompt. Answer them
once and they will not come back. Until you do, no ads load — that is deliberate.

To get back to a clean first-launch state:

```bash
xcrun simctl uninstall booted com.compoundapp.compound
```

## Running the tests

```bash
flutter test
```

The end-to-end run drives a real simulator and writes PNGs to `screenshots/`:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/walkthrough_test.dart -d "iPhone 16 Pro" --dart-define=SKIP_PRIVACY_PROMPTS=true
```

The flag is needed because the consent and tracking dialogs are OS overlays that swallow the
test's taps. Ads do not load in that mode, by design.

## Android

```bash
flutter emulators
flutter emulators --launch <id>
flutter run
```

## Release builds

Real ad units are opt-in, so a normal build always serves Google's test ads:

```bash
flutter build ipa --dart-define=USE_REAL_AD_UNITS=true --dart-define=AD_BANNER_IOS=ca-app-pub-XXXX/YYYY --dart-define=AD_INTERSTITIAL_IOS=ca-app-pub-XXXX/ZZZZ
```

Also swap the AdMob app ids in `ios/Runner/Info.plist` and
`android/app/src/main/AndroidManifest.xml` — both are Google's test ids right now.
