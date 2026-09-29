/// Product naming — keep in sync with platform display names and App Store Connect.
///
/// | Surface              | Value                     | Where it lives                          |
/// |----------------------|---------------------------|-----------------------------------------|
/// | App Store listing    | [kAppStoreName]           | App Store Connect → Name (not in binary)|
/// | Home screen / tray   | [kAppDisplayName]         | iOS CFBundleDisplayName, Android label  |
/// | In-app chrome        | [kAppBrandName]           | Setup AppBar, etc.                      |
library;

/// Name shown on the App Store (max 30 characters). Set this in App Store Connect.
const String kAppStoreName = 'Yaniv Score Tracker';

/// Short name under the icon on the device home screen.
///
/// Must match:
/// - `ios/Runner/Info.plist` → `CFBundleDisplayName`
/// - `ios/Runner.xcodeproj` → `INFOPLIST_KEY_CFBundleDisplayName`
/// - `android/app/src/main/AndroidManifest.xml` → `android:label` (plus debug suffix)
const String kAppDisplayName = 'Yaniv';

/// Compact brand label used inside the UI (e.g. setup AppBar).
const String kAppBrandName = 'Yaniv';
