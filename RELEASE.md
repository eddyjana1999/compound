# Pre-launch checklist

Audited 2026-08-29 against the actual project, not from a generic template. Every item below was
checked; the code itself is finished and both stores' builds already succeed.

    flutter build appbundle --release   ✓ builds (56MB, but ~15MB delivered — the rest is
                                          debug symbols and the ProGuard map, which Play strips)
    flutter build ios --release         ✓ compiles

What follows is everything between here and a live listing.

---

## 1. Blocking, and only you can do them

### Apple Developer + Google Play accounts
$99/year and $25 once. Apple's approval can take a few days for an individual account, longer for
a company. Start this first — everything else waits on it.

### Signing

**Android is currently signed with the debug key.** `android/app/build.gradle.kts` line 32:

    signingConfig = signingConfigs.getByName("debug")

Play rejects this outright. Create a keystore, put it in `android/key.properties` (git-ignored),
and point the release config at it:

```bash
keytool -genkey -v -keystore ~/compound-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Lose that file and you can never update the app under the same listing. Back it up somewhere that
is not this Mac.

**iOS has no signing team.** `DEVELOPMENT_TEAM` does not appear anywhere in
`ios/Runner.xcodeproj/project.pbxproj`. Open the project in Xcode, pick your team under
Signing & Capabilities, and let it create the provisioning profile.

### Real AdMob IDs
Everything ad-related is Google's test IDs right now, deliberately. Three places to change:

- `ios/Runner/Info.plist` → `GADApplicationIdentifier`
- `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
- the unit ids, passed at build time — never hardcoded:

```bash
flutter build appbundle --release --dart-define=USE_REAL_AD_UNITS=true --dart-define=AD_BANNER_ANDROID=ca-app-pub-XXXX/YYYY --dart-define=AD_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/ZZZZ
```

Shipping without `USE_REAL_AD_UNITS` is safe — you simply earn nothing. Shipping a *debug* build
against real units is what gets the AdMob account suspended, which is why the flag exists.

### Privacy policy, hosted at a public URL
Both stores require one, and this app is not exempt: it serves ads and the AdMob SDK merges
`com.google.android.gms.permission.AD_ID` into the manifest (I checked the merged output). The
policy has to say that advertising identifiers are collected and link to Google's own policy.
A GitHub Pages file is fine.

---

## 2. Blocking, and I can do them — say the word

### App icon
Still Flutter's default. This is the single most visible "unfinished" signal in a listing.
Give me a 1024×1024 PNG and I will wire up `flutter_launcher_icons` to generate every size for
both platforms.

### Android app name
`android/app/src/main/AndroidManifest.xml` says `android:label="compound"` — lowercase, the Dart
package name. iOS is already correct ("Compound").

### iOS privacy manifest — `PrivacyInfo.xcprivacy`
**Missing, and Apple rejects builds without it.** Required since May 2024. The app uses
`UserDefaults` through `shared_preferences`, which is a "required reason API" and must declare
reason code `CA92.1`. It also has to declare the data collected for advertising.

### Version number
`pubspec.yaml` says `0.1.0+1`. Ship as `1.0.0+1`.

### Launch screen
Still the default blank Flutter storyboard. Not a rejection, but it is the first thing a user sees.

---

## 3. Store paperwork — yours to fill in, mine to advise on

### Google Play
- **Data safety form.** Declare: advertising ID collected, used for advertising, not linked to
  identity, and that the app has no account system. Getting this wrong is the most common cause of
  Play review rejection.
- **Ads declaration**: yes, the app contains ads.
- **Content rating** questionnaire.
- Listing: title, short description (80 chars), full description, feature graphic 1024×500,
  at least 2 phone screenshots.

### App Store
- **App Privacy nutrition labels.** Declare identifiers → advertising ID, used for third-party
  advertising, and tracking = yes (which is exactly why ATT is implemented).
- **Export compliance**: the app only uses HTTPS, so answer "exempt".
- Screenshots for 6.7" and 6.5" iPhone. `screenshots/` already has real ones from the E2E run,
  though they are 6.3" (iPhone 16 Pro) — I can regenerate at the required sizes.
- Review notes: the calculator needs no login, so nothing else is required.

---

## 4. Not blocking, but worth doing before you press submit

- **Test on a physical device.** Everything so far has been the simulator. The ATT prompt in
  particular behaves differently on real hardware.
- **A real AdMob fill test** — test ads always fill; real ones do not, and the layout has to look
  right when a banner returns nothing. The code already collapses the slot to zero height, but see
  it happen.
- **`flutter build ios --release`** with real signing, then TestFlight to yourself.
- The 8 locales have never been proofread by a native speaker. Machine-quality translations in a
  finance app read as careless. Hebrew and English are solid; the other six I would have someone
  check.
- The disclaimer is on the results screen, which is correct, but if you ever add anything that
  reads as a recommendation, both stores treat it as financial advice and the review gets much
  harder.

---

## Rough order

1. Open both developer accounts (slowest, unblocks everything)
2. Icon + app name + version + privacy manifest ← ask me
3. Keystore and Xcode signing team
4. Privacy policy page
5. Real AdMob IDs
6. TestFlight / Play internal testing on real hardware
7. Store listings and the two privacy forms
8. Submit
