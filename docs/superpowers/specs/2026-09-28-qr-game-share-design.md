# QR Game Share — Design

## Purpose

Let a player share the current live game (all players, all rounds played so
far, and the active rule configuration) to a second device via QR code, so
that device can view or continue the same game. There is currently no
sharing, export, or multi-device feature in the app, and no serialization of
game state anywhere in the codebase.

## Scope

- Sharing the *full* current game snapshot: players, per-round scores, and
  the active `ScoringRules` configuration.
- Transfer via QR code only. No network, no Bluetooth, no server.
- Primary path is a single QR code. A multi-QR fallback (auto-cycling frames)
  is used only when a game's data does not fit in one scannable QR code.
- Out of scope: live/ongoing sync between devices, joining a game session
  before it starts, anything beyond a one-time snapshot handoff.

## Current State (relevant to this feature)

- No `Game` model exists. Live game state is loose fields on
  `_GameScreenState` (`lib/game_screen.dart`):
  - `_players`: `List<Player>` (`lib/player.dart`)
  - `_rawScoreHistory`: `List<List<RoundScore>>` — the source of truth per
    round per player (`lib/scoring_rules.dart`)
  - Rule config fields passed into `GameScreen`'s constructor, from which a
    `ScoringRules` object is built (`_rules` getter, `lib/game_screen.dart`)
  - Totals and display strings (`roundHistory`) are derived from
    `_rawScoreHistory` via `_recalculateTotals()` / `scoreRound()` — they do
    not need to be transmitted, only recomputed on the receiving device.
- `GameScreen` is only ever constructed with a fresh player list (from
  `SetupScreen`); it has no path today to resume from an existing round
  history.
- No `toJson`/`fromJson` exists on `Player` or `RoundScore`.
- No QR, camera, or sharing package is in `pubspec.yaml`. No `CAMERA`
  permission (Android) or `NSCameraUsageDescription` (iOS) is declared.

## Data Format

A compact custom binary payload (not JSON), to keep a typical game's data
small enough to fit one QR code at a reliably scannable density:

- **Header:** magic bytes + a format version byte, so a future incompatible
  payload version is detected and rejected explicitly rather than silently
  misparsed.
- **Rules:** `endScore`, `callScore`, and the rule toggle flags / penalty
  values from `ScoringRules`, packed as ints and bit-flags.
- **Players:** count, then for each player: name (length-prefixed string) +
  `joinedAtRound`.
- **Rounds:** count, then for each round, for each player: `RoundScore`
  fields (`value`, `penalty`, `isPenalty`, `isInactive`, `isCaller`,
  `skipWinnerHalf`) — the five booleans packed into bits rather than one
  field each.
- **Checksum:** a lightweight integrity check over the payload, so a camera
  misread is detected and rejected instead of importing corrupted scores.

The binary payload is base64-encoded to become the QR's string content.

## Single-QR vs Multi-QR

- Default path: encode the whole payload, generate one QR (`qr_flutter`).
  This is expected to cover realistic games (a handful of players, dozens of
  rounds) comfortably.
- Fallback path: if the encoded payload exceeds a size threshold chosen for
  reliable scanning (not simply QR's theoretical max), split it into
  indexed chunks. Each chunk carries its own small header (`chunk index /
  chunk count`) and checksum.
  - The share screen auto-cycles through the chunk QR codes (e.g. every
    ~1.5s) rather than requiring manual next/prev taps.
  - The scan screen keeps the camera open, accumulates chunks as they're
    read (ignoring already-seen or unparseable frames), and shows progress
    (e.g. "Scanned 2 of 3"). No manual coordination is required beyond
    keeping both screens open until the scan screen reports completion.
- If even chunked the payload is unreasonably large (some sanity cap on
  chunk count), the share screen shows "Game too large to share via QR"
  up front instead of generating something unscannable.

## UI Flow

- **`GameScreen`** (`lib/game_screen.dart`): add a "Share Game" action
  (AppBar icon) that encodes the current `_players` / `_rawScoreHistory` /
  rules and opens a new `ShareGameQrScreen` showing the QR (single or
  auto-cycling set).
- **`SetupScreen`** (`lib/setup_screen.dart`): add a "Join via QR" button
  that opens a new `ScanGameQrScreen` using `mobile_scanner` for the camera
  feed. Once fully decoded, it navigates directly into `GameScreen`,
  pre-loaded with the imported players, round history, and rules —
  bypassing normal setup.
- `GameScreen`'s constructor gains an optional initial round history
  parameter so it can resume mid-game instead of only starting fresh.
- New dependencies: `qr_flutter` (pure Dart, no permissions),
  `mobile_scanner` (camera), and `permission_handler` (explicit camera
  permission check/request, independent of `mobile_scanner`'s own
  internal handling). Requires adding `CAMERA` permission to the Android
  manifest and `NSCameraUsageDescription` to iOS's `Info.plist`.

## Camera Permission Flow

Handled explicitly via `permission_handler` before the camera view is shown,
rather than relying only on `mobile_scanner`'s internal error state:

- On opening `ScanGameQrScreen`, check `Permission.camera.status` first.
  - **Not yet determined:** request it. Granted → show the scanner.
  - **Already granted** (e.g. re-opening the screen later): go straight to
    the scanner, no prompt.
  - **Denied** (user said no, but can be asked again): show an inline
    explanation ("Camera access is needed to scan a game QR code") with a
    button to request again.
  - **Permanently denied** (denied twice on Android, or previously denied
    and the OS won't re-prompt): show a dialog explaining this, with a
    button that calls `openAppSettings()` so the user can enable it
    manually.
- The same check runs again if the screen resumes from the background
  (e.g. the user went to Settings and came back), so granting permission
  there is picked up without needing to leave and re-enter the screen.

## Error Handling

| Case | Behavior |
|---|---|
| Happy path, fits in 1 QR | Scan once → `GameScreen` opens with identical players/rounds/totals |
| Happy path, needs multiple QRs | Frames auto-cycle; scan screen shows progress; completes → same result |
| Empty game (0 rounds played) | Payload has an empty round list → import lands on a fresh `GameScreen` with the same players, no rounds |
| Invalid/foreign QR (wrong magic bytes) | Rejected immediately; scanner shows "Not a valid game QR" and keeps scanning; no crash, no partial state |
| Corrupted/misread chunk (checksum fails) | Silently dropped; scanner keeps waiting for a good read of that chunk; never assembles into wrong scores |
| Version mismatch (older app scanning newer payload) | Explicit "Update the app to import this game" error; import aborted |
| Payload absurdly oversized (even chunked) | Share screen shows "Game too large to share via QR" before generating anything |
| Camera permission denied (can re-prompt) | Inline explanation with a "grant access" button that requests again; no crash |
| Camera permission permanently denied | Dialog explaining why camera is needed, with a button to open app settings; no crash |

## Testing

- Unit tests: encode → decode round-trip, including 0 rounds, a large
  realistic player count, all rule-toggle combinations, and
  checksum-tamper detection.
- Unit tests: chunk split/reassembly — chunk-count math, duplicate-frame
  handling, out-of-order frame arrival.
- Manual QA (not unit-testable): actual camera scan on device, for both the
  single-QR and multi-QR-cycling cases.
