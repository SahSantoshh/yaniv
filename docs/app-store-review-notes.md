# App Store Review Notes (paste into App Store Connect → Notes)

Listing copy (name, description, keywords, screenshots): see [app-store-listing.md](./app-store-listing.md).

## Names

- **App Store Connect Name:** Yaniv Score Tracker  
- **Home-screen display name:** Yaniv (configured in the binary via `CFBundleDisplayName` / Android label)  
- These differ on purpose so the store listing is descriptive while the icon label stays short.

## Privacy Policy

https://sahsantoshh.com/legal/yaniv/privacy/

Also reachable in-app: setup screen → privacy shield icon → View Privacy Policy.

## Support / contact

Support is **email only**: sahsantoshh@gmail.com  

App Store Connect still requires an https **Support URL** — use the privacy policy page (it already shows the contact email):  
https://sahsantoshh.com/legal/yaniv/privacy/

## No account

The app does not require sign-in. All scoring works offline with local storage.

## Advertising & tracking

- The app shows Google AdMob banner and interstitial ads.
- On iOS, App Tracking Transparency is requested before ads initialize (after any required UMP privacy message).
- If the user denies tracking, ads still load as non-personalized (`nonPersonalizedAds`) when advertising is allowed.
- In regions that require it (e.g. EEA/UK), Google’s User Messaging Platform may show a consent form before ads. Users can reopen ad privacy options from the in-app Privacy screen when required.
- Users can report inappropriate ads from the Privacy screen → “Report an inappropriate ad” (opens Google’s report-an-ad help), or via the AdChoices overlay on ads.
- Gameplay interstitials are limited (about every 3 rounds with a cooldown), plus natural breaks at match start/end.

## Crash reporting

Firebase Crashlytics is enabled in release builds only.

## Encryption / export compliance

The app uses only standard HTTPS encryption (no custom/proprietary crypto). Answer the App Store Connect export questionnaire accordingly (standard exemption).

## Camera / QR game share

- Camera is optional and used only to scan a game QR shared from another device.
- QR codes transfer local game state between devices; they do **not** unlock paid features or content (Guideline 3.1.1).
- Core score tracking works without granting camera access.

### How to review QR import without a second device

1. On a device/simulator with the app, start a short match, add a round, open the in-game menu → share QR.
2. Screenshot or display the cycling QR frame(s).
3. On the review device, use Join via QR (scanner icon on setup) and scan those frames until import completes.

If a second device is unavailable, note that share/scan is local QR only (no backend). We can provide a pre-encoded sample on request.

## App Privacy nutrition labels (suggested)

Declare at least:

- **Advertising Data** / Device ID — used for Third-Party Advertising (AdMob); tracking only if the user authorizes ATT
- **Crash Data** / Diagnostics — used for App Functionality (Crashlytics)

See the detailed table in [app-store-listing.md](./app-store-listing.md#app-privacy-nutrition-labels-connect).

Do **not** place the app in the Kids Category (third-party ads).

## What this app is

A Yaniv-specific scorekeeper: call score, halving, winner-halves, Asaf / tie penalties, mid-game join penalty, rule examples, on-device history, and QR handoff — not a generic calculator and not a real-money gambling app.
