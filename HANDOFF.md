# Compound — Universal Investment Calculator

Handoff written 2026-08-29. Machine move: iMac -> MacBook Pro (iMac disk was 100% full).

## Status
Nothing built yet beyond `flutter create`. `pub get` failed — **no space left on device**.
Safe to delete this folder and start fresh on the new machine; this file is the only thing worth keeping.

Created with:
```
flutter create --org com.compoundapp --project-name compound --platforms ios,android,macos compound
```
Flutter 3.44.2 stable / Dart 3.12.2 on the iMac. Install the same on the MacBook Pro.

## Product spec
Global compound interest calculator. Clean, modern, visually striking. iOS + Android.

- **Home**: saved past calculations + prominent "New Calculation" button.
- **Input**: Starting Amount, Monthly Contribution, Annual Return (%), Time Horizon (Years).
  Expandable "Advanced" section: Annual Management Fee (%), Capital Gains Tax Rate (%).
  A **Calculate button** — no live recalculation (deliberate difference from netto).
- **Results**: Total Deposited, Interest Earned, Fees Paid, Tax Paid, Net.
  Interactive growth chart (`fl_chart`).

## Tech stack
Flutter (latest stable), Riverpod, `fl_chart`, `shared_preferences`, `intl`, `flutter_localizations`.

**Version pin found the hard way:** `flutter_localizations` pins `intl` to exactly `0.20.2`.
Do not write `intl: ^0.20.3` in pubspec — version solving fails.

## Core rules
1. **Money is integer minor units.** Never a double in `lib/domain/`. Doubles only at the display layer.
   `Money` carries `minorUnits` + `decimalDigits`, because JPY has 0 decimals and USD has 2 —
   "cents" is not a universal assumption.
2. **Monthly compounding.** Order of operations inside each month (carried over from netto, where it
   is documented as the part that changes the answer, so it is stated rather than implied):
   1. monthly deposit added at the *start* of the month, so it earns that month's return;
   2. return applied to the post-deposit balance;
   3. management fee applied to the post-return balance.
   Fee is charged monthly against the running balance, never as one deduction at the end.
   Because it leaves the balance, it also reduces the taxable gain.
3. **Capital gains tax** deducted from total profit on the results screen: `tax = rate * (final - deposited)`,
   floored at zero.
4. **Rate conversion is an explicit input, not a buried assumption** — copy `rate_conversion.dart` from
   `~/Desktop/netto/lib/domain/`. Geometric (default: "8% a year" means 8% in a year) vs nominal.
   Note a fee converts differently from a return: the monthly equivalent of an annual drag `f` is
   `1 - (1-f)^(1/12)`, not `(1+f)^(1/12) - 1`.
5. Rates stored as integer basis points (700 = 7.00%), for the same no-floats reason as money.

## i18n
`flutter_localizations` + gen_l10n, 8 locales: en, es, fr, de, zh, ja, ar, he.
Seamless LTR/RTL. Currency formatting via `NumberFormat.simpleCurrency(locale:)` — derive both the
symbol and the decimal digit count from the locale rather than assuming 2.

## Workflow
Pure Dart domain in `lib/domain/` with full unit test coverage **before** any UI.
Then data/persistence, then l10n, then theme (dark/light, modern cards, soft shadows,
micro-interactions), then screens.
Edgar works to a checkpoint plan and wants work to stop for review at each step.

## Reference
`~/Desktop/netto` (this iMac) — earlier Hebrew/Israeli version of the same idea. Worth copying
`lib/domain/money.dart`, `rate_conversion.dart`, `growth_engine.dart` as starting points and
generalising them. Its `HANDOFF.md` has the wider product history.

## Currency selection (added 2026-08-29)

Per calculation, not a global setting — `CalculationInput` already carried a `CurrencySpec` and the
saved history already persisted the code and scale, so only the UI had to expose it.

- The currency code in front of the amount fields *is* the control. Tapping it opens the picker.
- `lib/ui/formatting/currencies.dart` lists 49 ISO codes but **no decimal places**: `intl` already
  knows the yen has none and the Kuwaiti dinar has three, and a hand-kept table would be one more
  thing to get wrong.
- The picker pins the device's own currency to the top; the rest is alphabetical.
- Switching currency **reinterprets** the typed figures, it does not convert them. Converting would
  need an exchange rate the app does not have and would silently change the user's inputs.
- The last chosen currency is remembered in `compound.currency`; null means "follow the device".

## Chart smoothing

The chart samples the monthly series down to 140 points and joins them with straight segments.
It used to plot one point a year and smooth with a spline — on a genuinely exponential curve the
spline overshoots and gets corrected, which showed as visible kinks in the app's centrepiece.
Do not reintroduce `isCurved: true` here.

## Ads (added 2026-08-29)

AdMob via `google_mobile_ads`. Anchored adaptive banner at the bottom of the home and results
screens; a full-screen interstitial after every third calculation.

- **`google_mobile_ads` is imported in exactly one file**, `lib/ads/google_ad_service.dart`.
  Everything else talks to the `AdService` interface, which is what keeps widget tests free of
  platform channels. `NoOpAdService` is the off switch and must never throw.
- **Test ad units are the default.** Real ones require `--dart-define=USE_REAL_AD_UNITS=true`
  plus the per-platform unit ids. A debug build pointed at real units gets the AdMob account
  suspended for invalid traffic, so the unsafe path is the one that needs the flag.
  The app ids in `AndroidManifest.xml` and `Info.plist` are also Google's test ids and must be
  swapped at release build time.
- **Interstitial, not rewarded.** Rewarded ads require something to give the user; there is
  nothing to reward here. Interstitial needs no reward.
- **The interstitial shows on the way *out* of the results screen**, not between Calculate and
  the result. Interrupting the tap-to-answer moment is the one thing that would make the app
  feel worse than its competitors.
- The counter is persisted (`compound.calculationCount`). An in-memory counter would reset on
  every cold start and show the ad far more often than every third calculation.
### Privacy (done 2026-08-29)

- **UMP / GDPR.** `ConsentInformation.requestConsentInfoUpdate` then
  `ConsentForm.loadAndShowConsentFormIfRequired` run before the SDK starts. Nothing is requested
  until `canRequestAds()` is true, so a user who declines gets no ad request at all rather than a
  non-personalised one. Verified on the simulator: the UMP form appears on first launch.
- **ATT.** `app_tracking_transparency`, asked only when the status is still `notDetermined`, after
  a 300ms wait — iOS silently refuses the prompt while the app is still becoming active.
  `NSUserTrackingUsageDescription` is in `Info.plist`.
- **Order is legal, not stylistic**: consent, then tracking permission, then SDK start. It lives
  inside a single `initialize()` so no caller can get it wrong.
- **`SKAdNetworkItems`**: 50 identifiers from https://developers.google.com/admob/ios/ios14,
  synced 2026-08-29. Re-check before each release; Google adds networks over time.
- **Privacy options entry point** appears in the settings sheet only where
  `getPrivacyOptionsRequirementStatus()` says it is required — i.e. in the EU.

### Running the integration tests

Both privacy prompts are OS-level overlays that swallow the tests' taps, so automated runs need:

    flutter drive --driver=test_driver/integration_test.dart \
      --target=integration_test/walkthrough_test.dart -d <simulator-udid> \
      --dart-define=SKIP_PRIVACY_PROMPTS=true

Consequence, and it is the correct one: consent is never granted in that mode, so **no ads load
during E2E runs**. The flag can only hide an ad that should have shown, never show one that should
have been withheld. To see the banner and interstitial you have to run the app normally and tap
through the consent form by hand.

### Known limitation on this machine

`/var/db/xcode_select_link` does not exist, so the live simulator panel is unavailable and nothing
here can tap the simulator. Fix with:

    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

## Session end, 2026-08-30

Working tree clean, 8 commits, nothing on a remote yet. `flutter analyze` clean, 136 unit tests and
5 end-to-end tests passing.

Read `RELEASE.md` for what is left before either store, and `TRANSLATIONS.md` for the queued
translation pass — both are self-contained.

Two things that will bite whoever picks this up:

- The end-to-end tests need `--dart-define=SKIP_PRIVACY_PROMPTS=true`, or the consent and tracking
  dialogs sit on top of the app and swallow every tap.
- A rebuilt app icon can look like it has a dark border on the simulator. That is the springboard's
  icon cache, not the file. Uninstall, stop SpringBoard, reinstall.
