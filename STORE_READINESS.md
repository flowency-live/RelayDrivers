# Store Readiness Checklist

Status of native (Android/iOS) store-submission blockers. Items marked
**DONE (in-repo)** were fixed in code; items marked **NEEDS BINARY ASSET** or
**NEEDS SECRET** cannot be completed without files that must be generated
outside this repo.

## Done in-repo

- **Environment no longer hardcoded to dev.** `lib/config/environment.dart` now
  resolves from `--dart-define=ENVIRONMENT=dev|staging|prod` and **defaults to
  `prod`**. A plain release build ships prod config (logging off, no
  `X-Tenant-Id` spoof header). CI/local dev must pass `ENVIRONMENT=dev`.
- **Debug logging / token leaks removed.** All 38 `print()` calls (several
  logging token metadata) replaced with `AppLogger` (`lib/core/utils/app_logger.dart`),
  which compiles out in release via `kDebugMode`. Full-body `LogInterceptor` is
  already gated on `currentEnvironment.enableLogging`, which is now `false` in
  prod.
- **iOS Info.plist usage strings added:** `NSCameraUsageDescription`,
  `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`,
  `NSLocationWhenInUseUsageDescription`,
  `NSLocationAlwaysAndWhenInUseUsageDescription`.
- **AndroidManifest permissions added:** `INTERNET`, `CAMERA`,
  `READ_MEDIA_IMAGES`, `POST_NOTIFICATIONS`, `ACCESS_FINE_LOCATION`,
  `ACCESS_COARSE_LOCATION`, plus optional camera `uses-feature`.
- **Release signing config scaffolded.** `android/app/build.gradle.kts` now
  reads `android/key.properties` and signs release with a real keystore when
  present, falling back to debug only when absent (with a clear warning).

## Needs binary asset (cannot generate here)

- **Android launcher icons.** No `mipmap-*` directories exist, but
  `AndroidManifest.xml` references `@mipmap/ic_launcher` - the build will fail
  resource linking. Provide adaptive icons:
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
  - `.../mipmap-hdpi/ic_launcher.png` (72x72)
  - `.../mipmap-xhdpi/ic_launcher.png` (96x96)
  - `.../mipmap-xxhdpi/ic_launcher.png` (144x144)
  - `.../mipmap-xxxhdpi/ic_launcher.png` (192x192)
  - Recommended: use `flutter_launcher_icons` from a 1024x1024 master PNG.
- **iOS app icons.** `ios/Runner/Assets.xcassets/AppIcon.appiconset/` has only
  `Contents.json` (declares 19 filenames) - the PNGs are missing. Provide all
  declared sizes (20/29/40/58/60/76/80/87/120/152/167/180 and 1024 marketing).
- **iOS launch image.** `LaunchImage.imageset/` has only `Contents.json` +
  README; add the referenced PNGs.
- **Web PWA icons.** `web/icons/` is empty but `web/manifest.json` /
  `web/index.html` reference `Icon-192.png`, `Icon-512.png`, maskable variants,
  and `favicon.png`. Add them for a valid installable PWA.

## Needs secret (cannot commit here)

- **Release keystore.** Generate and store securely, then create
  `android/key.properties`:
  ```
  storePassword=***
  keyPassword=***
  keyAlias=upload
  storeFile=/absolute/path/to/upload-keystore.jks
  ```
  Generate: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA
  -keysize 2048 -validity 10000 -alias upload`.
- **Firebase config files** for push - see `FIREBASE_SETUP.md`.
- **APNs auth key** (`.p8`) uploaded to Firebase for iOS push.

## CI note

The only pipeline (`.github/workflows/deploy.yml`) builds Flutter **web** and
deploys to Firebase Hosting. There is no APK/AAB/IPA build or TestFlight/Play
pipeline; native store submission needs new CI once the assets above exist.
