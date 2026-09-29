# App Store Listing — Yaniv Score Tracker

Copy-paste ready fields for App Store Connect. Keep metadata accurate (Guideline 2.3).

**Version in app:** `1.4.0` (build `7`) — update What’s New when you bump.

**Privacy Policy URL:** https://sahsantoshh.com/legal/yaniv/privacy/  
**Support URL:** https://sahsantoshh.com/legal/yaniv/privacy/  
(Apple requires an https Support URL; `mailto:` is not accepted. Support is email-only — the privacy page already lists `sahsantoshh@gmail.com`. In-app: Privacy → tap the email.)  
**Marketing URL (optional):** https://sahsantoshh.com/

Related: [app-store-review-notes.md](./app-store-review-notes.md) (Notes for Review).

---

## Two names (Store vs device)

Apple allows different names for the store listing and the icon on the home screen.
They should stay recognizably related (Guideline 2.3.8).

| Where | Name | Limit | Set in |
|---|---|---|---|
| **App Store** | `Yaniv Score Tracker` | 30 chars | App Store Connect → App Information → Name |
| **Home screen** | `Yaniv` | ~10–12 visible | iOS `CFBundleDisplayName`, Android `android:label` |
| **In-app header** | `Yaniv` | — | UI (`lib/app_names.dart`) |

**App Store Connect Name** (paste):

```
Yaniv Score Tracker
```

**Device display name** is already configured as `Yaniv` in the iOS/Android project — do **not** put the long store name under the icon (it truncates).

Source of truth in code: [`lib/app_names.dart`](../lib/app_names.dart).

Do **not** use “For Kids” / “For Children” (Guideline 2.3.8 / Kids Category).

---

## Subtitle

**Subtitle** (max 30 characters):

```
Yaniv card game scorekeeper
```

(29 characters)

**Alternates:**

```
Scoreboard for Yaniv
```

```
Track Yaniv game scores
```

---

## Category

| Field | Suggestion |
|---|---|
| **Primary** | Games → **Card** (or **Board** if Card unavailable) |
| **Secondary** | Utilities |

Avoid Kids Category (AdMob + Crashlytics).

---

## Age rating

Answer App Store Connect questionnaires honestly.

Suggested outcomes for this app:

- **No** unrestricted web content, user-generated social chat, or gambling for real money
- **Yes** — infrequent/mild competitive scorekeeping for a card game
- **Contains ads** (AdMob) — age rating may rise based on ad content; do not claim 4+ if ads can show higher-rated creatives
- **No** Kids Category

Practical target: **12+** is often safest with third-party ads; confirm after the age questionnaire.

### Age questionnaire quick answers (verify in Connect)

| Topic | Suggested answer |
|---|---|
| Contests / score competition | Infrequent / mild (local scorekeeping) |
| Gambling / contests for money | None |
| Unrestricted web access | No (in-app links only to policy/support/Google report) |
| User-generated content / social | No |
| Ads | Yes — third-party (AdMob) |
| Medical / alcohol / drugs / violence | None intended by the app itself (ad creatives vary) |

---

## App Privacy nutrition labels (Connect)

Fill **App Privacy** to match the binary and hosted policy:

### Data Used to Track You

| Data type | Used for | Notes |
|---|---|---|
| Device ID | Third-Party Advertising | Only when user authorizes ATT; otherwise do not claim tracking for IDFA |

### Data Linked to You (typical for AdMob / Crashlytics)

Declare as **not linked** / diagnostics as appropriate if you do not create user accounts. Common set:

| Data type | Purpose | Tracking? |
|---|---|---|
| Device ID | Third-Party Advertising | Yes if ATT authorized |
| Advertising Data / Product Interaction (ads) | Third-Party Advertising | Per AdMob |
| Crash Data | App Functionality | No |
| Diagnostics / Performance Data | App Functionality | No (Crashlytics) |

**Do not** claim collection of Contact Info, Name, or Health for gameplay — player names stay on device only.

Re-check when Google’s privacy manifests or AdMob disclosures change.

---

## Promotional text

(Optional, up to 170 characters — can change without a new binary.)

```
Track Yaniv the easy way: custom rules, Asaf & call scores, live scoreboard, history, and QR handoff between devices.
```

---

## Description

(Up to 4000 characters. Paste as-is or trim.)

```
Yaniv Score Tracker is a dedicated scorekeeper for the Yaniv card game — not a card dealer, not a generic calculator. Set up your table, enter round scores, and let the app apply the rules your group actually plays.

WHY YANIV-SPECIFIC
• Configurable end score (default 124)
• Call score limit for when a player may call Yaniv
• Halving rule when a total hits key thresholds
• Winner halves previous total (optional house rule)
• Asaf penalty and penalty-on-tie options
• Penalty when a new player joins mid-match
• Built-in rule examples so everyone agrees on the math

DURING THE MATCH
• Add players with custom names (reorder as needed)
• Round-by-round scoreboard with clear totals
• Round winners highlighted
• Halved scores shown with strikethrough so the table stays readable
• Add or adjust players as the night goes on
• End the match when someone crosses the target — lowest total wins

SHARE & CONTINUE
• Share the current game via QR to another phone
• Join via QR on setup to continue the same match
• Game history kept on your device

PRIVACY
• Player names and scores stay on your device
• Optional camera only for scanning a game QR
• Privacy Policy: https://sahsantoshh.com/legal/yaniv/privacy/

The app is free and supported by ads. You can report an inappropriate ad from the in-app Privacy screen.
```

---

## Keywords

(Max 100 characters total, comma-separated, **no spaces after commas** preferred. Do not repeat the app name. No competitor trademark stuffing.)

```
yaniv,scorekeeper,scoreboard,card game,asaf,halving,score tracker,multiplayer scores,qr share
```

(Character count: check in Connect; trim from the end if over 100.)

**Shorter fallback if over limit:**

```
yaniv,scorekeeper,scoreboard,card game,asaf,halving,score tracker
```

---

## What’s New

For **1.4.0** (adjust if your release notes differ):

```
• Privacy Policy in the app, with a link to report inappropriate ads
• App Tracking Transparency on iOS — personalized ads only if you allow tracking
• Smoother ad timing during matches (fewer interruptions between rounds)
• Stability improvements
```

Generic bugfix–only style (if you prefer):

```
Bug fixes and improvements for App Store submission.
```

---

## Screenshots & preview (Guideline 2.3.3)

Show the **app in use**, not only the splash/logo.

Suggested set (iPhone 6.7" is usually required; add 6.5"/iPad if you support them):

1. **Setup** — players + rule toggles (call score, halving, Asaf)
2. **Scoreboard mid-game** — several rounds, yellow winner highlight, a halved/strikethrough score if possible
3. **Add round** dialog with scores entered
4. **Rule examples** screen (shows Yaniv-specific depth)
5. **Share / scan QR** (optional but helpful for reviewers and users)
6. **Game history** (optional)

Overlays: short captions are OK (“Halving rule”, “QR handoff”). No fake prices. No Android branding (Guideline 2.3.10).

---

## App Review information (Connect form)

| Field | Value |
|---|---|
| **Sign-in required?** | No |
| **Contact email** | sahsantoshh@gmail.com |
| **Contact phone** | Your number on file |
| **Notes** | Paste from [app-store-review-notes.md](./app-store-review-notes.md) |

---

## Copyright

```
© 2026 Santosh Prasad Sah
```

(Adjust year/legal name as needed.)

---

## Localization

Ship **English (U.S.)** first. Add more locales later with translated description/keywords only if you maintain them.

---

## Checklist before Submit

- [ ] Name / subtitle / description / keywords pasted
- [ ] Privacy Policy URL set → https://sahsantoshh.com/legal/yaniv/privacy/
- [ ] Support URL set → same as Privacy Policy URL (email support; Apple needs https)
- [ ] Age rating questionnaire completed (ads disclosed; ~12+)
- [ ] App Privacy nutrition labels filled (Advertising + Crash/Diagnostics; ATT tracking)
- [ ] Export compliance answered (HTTPS only / standard encryption exemption)
- [ ] Screenshots show real gameplay (setup, scoreboard, rules; optional QR)
- [ ] Notes for Review pasted from [app-store-review-notes.md](./app-store-review-notes.md)
- [ ] Not in Kids Category
- [ ] Pricing: Free (ads)
- [ ] Release AdMob app ID + unit IDs verified (not Google test IDs)
