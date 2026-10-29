# iOS dependency integration (CocoaPods)

This project uses **CocoaPods** for iOS plugins (`flutter.config.enable-swift-package-manager: false` in `pubspec.yaml`).

## Why CocoaPods (for now)

Several plugins still lack usable iOS Swift Package Manager support (`mobile_scanner`, `permission_handler_apple`, etc.), and recent FlutterFire/plugin releases that target SPM have shipped **without** CocoaPods `Sources/` trees on pub.dev. Enabling SPM failed earlier because `firebase_core` had no iOS package path Crashlytics expected.

## Broken pub.dev packages

These versions omit native Sources and produce empty CocoaPods aggregate targets (`Module '…' not found`).

Still pinned, because the newest release is still the broken one:

| Package | Broken (still latest) | Pinned |
|---|---|---|
| `mobile_scanner` | 7.4.2 | 7.4.1 (direct dependency) |
| `url_launcher_ios` | 6.4.2 | 6.4.1 (`dependency_overrides`) |

Later releases include CocoaPods sources again, so these pins were removed:

| Package | Broken | Now using |
|---|---|---|
| `firebase_core` | 4.15.0 | 5.1.0 |
| `permission_handler_apple` | 9.6.2 | 9.6.4 |
| `shared_preferences_foundation` | 2.5.7 | 2.6.1 |
| `webview_flutter_wkwebview` | 3.26.1 | 3.27.2 |

## Setup

1. Install CocoaPods: `brew install cocoapods`
2. From the repo root: `flutter pub get`
3. From `ios/`: `pod install`
4. Open `ios/Runner.xcworkspace` (not the `.xcodeproj`)

## Permission flags

`ios/Podfile` sets:

- `PERMISSION_CAMERA=1`
- `PERMISSION_APP_TRACKING_TRANSPARENCY=1`

Matching usage strings must remain in `Info.plist`.

## google_mobile_ads + static frameworks

`google_mobile_ads` public headers import `GoogleMobileAds_Beta.h` (non-modular). The Podfile forces `DEFINES_MODULE = NO` for that pod (including its generated xcconfigs) and sets `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES` on pods and Flutter xcconfigs.
