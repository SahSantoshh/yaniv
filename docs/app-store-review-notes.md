# App Store Review Notes (paste into App Store Connect → Notes)

**Version:** 2.0.0 (build 9)

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

Release builds show Google AdMob banner and interstitial ads. Debug builds do not, unless a developer flag is turned on. TestFlight and App Store builds are release builds, so ads should appear.

After the setup screen is on screen, the app does this in order:

1. If the region requires it (for example EEA/UK), Google’s User Messaging Platform may show a consent form.
2. On iPhone, App Tracking Transparency is requested. Allowing it permits personalized ads. Denying it still allows scorekeeping, and ads load as non-personalized when advertising is allowed.
3. Ad requests are capped at teen (`MaxAdContentRating.t`). Mature ads are not requested.
4. The ads SDK starts only when consent allows an ad request. If consent refuses ads, no ad loads. Scorekeeping still works.

Users can reopen ad privacy options from the in-app Privacy screen when Google requires that entry point.

Privacy screen → “Report an inappropriate ad” opens an email to sahsantoshh@gmail.com with the subject “Inappropriate ad report”. The AdChoices overlay on an ad is a separate Google control.

Gameplay interstitials show at most every 3 rounds, and not more often than once every 90 seconds, plus natural breaks at match start and match end.

## Crash reporting

Firebase Crashlytics is enabled in release builds only.

## Encryption / export compliance

The app uses only standard HTTPS encryption (no custom/proprietary crypto). Answer the App Store Connect export questionnaire accordingly (standard exemption).

## iPhone and iPad

This build supports iPhone and iPad. Please test setup, scoring, and the QR scan on an iPad.

## Camera / QR game share

Sharing is a QR code between two phones. One phone shows the code. The other phone scans it.

- Camera is optional and used only to scan that QR.
- The code carries local game state. It does not unlock paid features or content (Guideline 3.1.1).
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
