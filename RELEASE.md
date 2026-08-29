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

---

# App Store: the actual upload

Steps 1–3 are one-time setup. After that, shipping an update is step 4 onward.

## 1. Enrol in the Apple Developer Program
https://developer.apple.com/programs — $99/year. Individual enrolment is usually approved in a
day or two; a company needs a D-U-N-S number and takes longer. Nothing below works until this is
done, so start it first.

## 2. Signing, in Xcode
```bash
open ios/Runner.xcworkspace
```
Select the **Runner** target → **Signing & Capabilities** → tick *Automatically manage signing*
and pick your Team. Xcode registers the bundle id `com.compoundapp.compound` and creates the
provisioning profile. This is the only step that must happen in the Xcode GUI.

## 3. Create the app record
https://appstoreconnect.apple.com → My Apps → **+** → New App.
- Platform: iOS
- Bundle ID: pick `com.compoundapp.compound` from the list (it appears after step 2)
- SKU: anything unique, e.g. `compound-001`
- Name: must be unique across the whole App Store. "Compound" is likely taken — have a fallback
  ready, e.g. "Compound — Investment Calculator".

## 4. Build the archive
```bash
flutter build ipa --release \
  --dart-define=USE_REAL_AD_UNITS=true \
  --dart-define=AD_BANNER_IOS=ca-app-pub-XXXX/YYYY \
  --dart-define=AD_INTERSTITIAL_IOS=ca-app-pub-XXXX/ZZZZ
```
Output lands in `build/ios/ipa/`. Omit the dart-defines and you ship working test ads that earn
nothing — safe, just pointless.

## 5. Upload
Either open `build/ios/archive/Runner.xcarchive` in Xcode → **Distribute App** → App Store Connect,
or drag the `.ipa` into Apple's **Transporter** app (free on the Mac App Store). Transporter is
simpler and gives clearer errors.

Processing on Apple's side takes 15–60 minutes. You get an email when the build is ready.

## 6. TestFlight first
Install the build on your own iPhone through TestFlight before submitting. This is where you find
out whether the ATT prompt, the consent form and a real (non-test) ad fill behave the way they did
on the simulator. They often do not.

## 7. Fill in the review paperwork
In App Store Connect, on the version:
- **App Privacy** → Identifiers → Device ID → used for Third-Party Advertising, **Tracking: Yes**.
  This must match what `PrivacyInfo.xcprivacy` declares, or the build is rejected.
- **Screenshots**: 6.7" and 6.5" iPhone required. `screenshots/` has real ones at 6.3"; regenerate
  at the required sizes.
- Description, keywords, support URL, **privacy policy URL** (mandatory).
- **Export compliance**: HTTPS only → "exempt".
- Age rating questionnaire.

## 8. Submit
Review is typically 24–48 hours. Common rejections for an app like this: missing privacy policy,
App Privacy labels that disagree with the privacy manifest, and wording anywhere in the app or
listing that reads as financial advice rather than an estimate.

## Still blocking, as of 2026-08-29
- Apple Developer account — yours
- Signing team in Xcode — yours
- **App icon is still Flutter's default** — give me a 1024×1024 PNG and I will generate every size
- Real AdMob unit ids
- Privacy policy at a public URL

---

# In-app purchase: remove ads

A single non-consumable, `com.compoundapp.compound.remove_ads`, priced at tier $2.99.

The app never hardcodes that price. It asks the store and shows whatever string comes back, so a
German user sees euros and Apple can re-tier without a release. If the store has no answer — no
network, product not approved yet — the upsell card renders nothing rather than offering a price
the app invented.

## What you must create before it works

**App Store Connect** → your app → Monetization → In-App Purchases → **+**
- Type: **Non-Consumable**
- Reference name: `Remove Ads`
- Product ID: `com.compoundapp.compound.remove_ads` (must match exactly)
- Price: Tier 3 ($2.99 in the US; every other currency is set by Apple's matrix)
- Add a localised display name and description for **every** language the app ships — a missing
  one blocks review
- Upload a screenshot of the purchase in the app for review

**You must also complete Agreements, Tax and Banking** in App Store Connect. Until the Paid
Applications agreement is active, `queryProductDetails` returns nothing and the card stays hidden.
This trips up almost everyone the first time.

**Play Console** → Monetize → Products → In-app products → Create
- Same product ID, price $2.99, activate it
- Products only resolve for a build uploaded to a track (internal testing is enough) and signed
  with the upload key — not for a local debug build

## Testing it

- iOS: create a **Sandbox tester** in App Store Connect → Users and Access, then sign into it on
  the device under Settings → Developer. Sandbox purchases are free and repeatable.
- Android: add your account to the **License testers** list in the Play Console.
- Neither works on a plain simulator or emulator, which is why the card is invisible there.

## How it behaves in the app

- Entitlement is stored locally at `compound.adsRemoved`. The store stays the source of truth and
  Restore re-reads it, but the app opens ad-free offline and without waiting on the network.
- **Restore purchases** lives in the settings sheet. Apple rejects a non-consumable that cannot be
  restored, so do not remove it.
- One provider is the whole gate: when the entitlement is set, `adServiceProvider` hands out a
  `NoOpAdService` and every ad surface in the app goes quiet at once. No screen checks for itself,
  so no screen can forget.
- A cancelled purchase says nothing to the user. Backing out is a choice, not an error.
- Ask to Buy returns `pending`, which deliberately does not grant the entitlement — it arrives
  later through the purchase stream once a parent approves.

## Not done, and worth knowing

Receipts are not verified against Apple's or Google's servers. For a one-off unlock on a free
calculator that is the normal trade-off — server-side validation needs a backend this app does not
have. A determined user on a jailbroken device can bypass it. If that ever matters more than the
simplicity, the place to add it is `StorePurchaseService`.
