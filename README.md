# RGB 🎮

A neon, **piano-tiles-style reflex game**. Three lanes — **R**ed, **G**reen,
**B**lue. Colors fall faster and faster; tap the matching lane. When a **mixed**
color falls (yellow / cyan / magenta) you must press **both** matching lanes
**at the same time**. Two-finger combos pay 3× and trigger chunky particle
bursts + screen shake.

Built with **Flutter** (single codebase → iOS + Android), a custom
`CustomPainter` game loop, **Firebase** (anonymous-first auth + Firestore
leaderboards) and **Google AdMob** (banner + interstitial + rewarded "continue").

---

## What's in the box

```
lib/
  main.dart              # bootstrap: prefs, Firebase, ads, providers
  app.dart               # MaterialApp + localization
  theme.dart             # neon palette + glow helpers
  l10n/strings.dart      # EN / IT / ES (no codegen needed)
  game/
    game_config.dart     # all gameplay tuning lives here
    tile.dart            # the 6 tile types + their required lanes
    particle.dart        # spark burst system
    game_engine.dart     # pure game logic + combo/fail rules (unit-tested)
    game_painter.dart    # neon rendering
  services/
    settings_service.dart      # volume, language, haptics, local best
    audio_service.dart         # music + SFX (degrades silently)
    auth_service.dart          # anon → email/Google/Apple upgrade
    ads_service.dart           # AdMob banner/interstitial/rewarded
    leaderboard_service.dart   # all-time + daily Firestore boards
  screens/                     # home, game, settings, leaderboard, auth
  widgets/neon_button.dart
test/game_engine_test.dart     # combo + fail-rule tests
firestore.rules                # leaderboard security rules
```

> **Design choice — auth:** every player starts in an **anonymous** session so
> they can play instantly (best retention for casual games). They only see the
> sign-in screen if they *choose* to upgrade (Settings → Account) to sync scores
> across devices. The same uid is preserved on upgrade, so no score is lost.

---

## 1. Prerequisites

- **Flutter SDK 3.19+** (`flutter doctor` should be all green).
- **Android:** Android Studio + an emulator or device.
- **iOS:** a Mac with Xcode 15+ and CocoaPods (`sudo gem install cocoapods`).
- A **Firebase** project and a **Google AdMob** account (both free).

## 2. First-time setup

This repo contains the Dart source. Generate the native iOS/Android projects and
pull dependencies:

```bash
cd rgb
flutter create . --org com.yourcompany --project-name rgb --platforms=android,ios
flutter pub get
```

`flutter create .` is non-destructive — it adds the `android/` and `ios/`
folders without touching `lib/`.

### Run it immediately (test/guest mode)

You can run **right now** before configuring Firebase — the app falls back to
local/guest mode (global leaderboards are disabled, everything else works, and
AdMob shows Google **test** ads):

```bash
flutter run
flutter test          # runs the game-logic unit tests
```

## 3. Firebase (auth + leaderboards)

```bash
dart pub global activate flutterfire_cli
flutterfire configure        # pick/create your project; regenerates lib/firebase_options.dart
```

Then in the [Firebase console](https://console.firebase.google.com):

1. **Authentication → Sign-in method:** enable **Anonymous**, **Email/Password**,
   **Google**, and **Apple** (Apple requires an Apple Developer account).
2. **Firestore Database → Create database** (production mode).
3. Deploy the security rules in this repo:
   ```bash
   firebase deploy --only firestore:rules
   ```
4. The leaderboard queries need single-field indexes on `score` (descending).
   Firestore will print a one-click "create index" link the first time the query
   runs — just follow it.

`flutterfire configure` also drops `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist`. These are git-ignored on purpose — keep
them out of public repos.

### Google / Apple sign-in native bits

- **Google (Android):** add your debug + release **SHA-1/SHA-256** fingerprints
  in Firebase → Project settings, then re-download `google-services.json`.
  ```bash
  cd android && ./gradlew signingReport   # copy the SHA-1
  ```
- **Google (iOS):** in `ios/Runner/Info.plist` add a URL scheme equal to the
  `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`.
- **Apple:** in Xcode → Runner → Signing & Capabilities, add the
  **Sign in with Apple** capability.

## 4. AdMob

The code ships with Google's **official test ad unit IDs** so you never risk a
policy strike while developing. Before publishing:

1. Create your app + ad units in the [AdMob console](https://apps.admob.com).
2. In `lib/services/ads_service.dart`, set `useTestAds = false` and replace the
   IDs in the `_test` map with your real unit IDs (banner/interstitial/rewarded
   for both platforms).
3. Add your **App ID** natively:

   **Android** — `android/app/src/main/AndroidManifest.xml`, inside
   `<application>`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
   ```

   **iOS** — `ios/Runner/Info.plist`:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
   <key>NSUserTrackingUsageDescription</key>
   <string>This identifier will be used to deliver personalized ads to you.</string>
   ```

   On iOS 14+ also add the recommended `SKAdNetworkItems` list from the
   [AdMob docs](https://developers.google.com/admob/ios/quick-start).

## 5. Tuning the game

Everything you'd want to balance is in `lib/game/game_config.dart`: fall speed,
speed ramp, spawn rate, combo frequency, hit-window forgiveness, point values.
Tweak, hot-reload, repeat.

---

## 6. Build & publish

### Android (Google Play)

```bash
# one-time: create an upload keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```
Create `android/key.properties` (git-ignored) pointing at it, wire it into
`android/app/build.gradle` (see Flutter's
[Android signing guide](https://docs.flutter.dev/deployment/android#signing-the-app)),
bump `version:` in `pubspec.yaml`, then:

```bash
flutter build appbundle --release      # -> build/app/outputs/bundle/release/app-release.aab
```

In the **Play Console**: create the app, fill the store listing (title, short +
full description, screenshots, feature graphic), complete the Data Safety &
content-rating forms, set up your AdMob app, then upload the `.aab` to the
**Internal testing** track first, and promote to Production once it looks good.

### iOS (App Store)

```bash
flutter build ipa --release            # or: open ios/Runner.xcworkspace in Xcode
```
In Xcode set your **Team / bundle id**, then **Product → Archive → Distribute App**
to upload to **App Store Connect**. Create the app there, fill the listing +
privacy details (declare IDFA use because of ads), submit a build to
**TestFlight**, then **Submit for Review**.

### Store-listing tips for virality

- Lead the screenshots with a satisfying 2-color **combo burst** mid-action.
- A 15–20s portrait gameplay video converts best for hyper-casual.
- ASO keywords: *tiles, reflex, color, rhythm, tap, RGB, arcade*.
- Add a "share your score" button later to feed the daily leaderboard loop.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `firebase_options.dart` has `REPLACE_ME` | run `flutterfire configure` |
| Leaderboard tab says "Connect Firebase" | Firebase not initialized yet (step 3) |
| Ads don't show | test ads need a network connection; real ads can take hours to fill a brand-new unit |
| No sound | add the audio files in `assets/audio/` (see its README) |
| Apple sign-in button missing | it only appears on iOS devices, by design |
