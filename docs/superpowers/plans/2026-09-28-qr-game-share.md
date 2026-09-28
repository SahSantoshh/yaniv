# QR Game Share Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a player share the full current game (players, rounds, rule config) to another device via QR code, so that device can view or continue the same game.

**Architecture:** A compact custom binary encoding (not JSON) turns the live game state into bytes; those bytes are split into one or more QR-sized, checksummed "frames" (usually just one). A share screen renders the frame(s) — cycling automatically if there's more than one — and a scan screen (behind an explicit camera-permission gate) reads frames back with the camera until it has them all, then reconstructs the game and hands it to `GameScreen` to resume from.

**Tech Stack:** Flutter/Dart, `qr_flutter` (QR rendering), `mobile_scanner` (camera QR reading), `permission_handler` (camera permission).

**Spec:** `docs/superpowers/specs/2026-09-28-qr-game-share-design.md`

## Global Constraints

- Dart SDK is `^3.8.1` (`pubspec.yaml`) — use only syntax/APIs compatible with that.
- Transfer is QR-only: no network, Bluetooth, or server calls anywhere in this feature.
- Default to a single QR code; only split into multiple frames when the encoded game does not fit in one.
- New camera permission must be declared on both platforms: `CAMERA` in `android/app/src/main/AndroidManifest.xml`, `NSCameraUsageDescription` in `ios/Runner/Info.plist`.
- Follow existing app conventions: plain `StatefulWidget` + `setState` (no state-management package), plain `flutter_test` (no mocking framework in the repo).
- Let `flutter pub add` resolve dependency versions rather than hand-picking version numbers.

## Review Focus

- A misread or tampered QR frame must never silently produce wrong scores — it must be detected and rejected. (Task 2: corrupted-chunk test; Task 1: tampered-checksum test)
- A game with zero rounds played yet must still share/import correctly (not crash or lose the player list). (Task 1: empty-round-history round-trip test)
- Scanning a QR code that isn't one of this app's game-share codes must be rejected without crashing the scan screen. (Task 2: garbage-input test)
- A payload from a future, incompatible format version must produce an explicit "update the app" style error, not a silent misparse. (Task 1 and Task 2: version-mismatch tests)
- A game too large to fit even a full chunked QR set must be rejected up front on the share screen, not turned into an unusable QR sequence. (Task 3: too-large test)

---

### Task 1: Game snapshot model + binary codec

**Files:**
- Modify: `lib/scoring_rules.dart` (add `==`/`hashCode` to `RoundScore` and `ScoringRules`)
- Modify: `test/scoring_rules_test.dart` (append equality tests)
- Create: `lib/game_share/game_snapshot.dart`
- Create: `lib/game_share/game_snapshot_codec.dart`
- Create: `test/game_share/game_snapshot_codec_test.dart`

**Interfaces:**
- Consumes: `RoundScore` and `ScoringRules` from `lib/scoring_rules.dart` (existing).
- Produces:
  - `class PlayerSnapshot { final String name; final int joinedAtRound; }` (with value equality)
  - `class GameSnapshot { final List<PlayerSnapshot> players; final List<List<RoundScore>> roundHistory; final ScoringRules rules; }` (with value equality)
  - `Uint8List encodeSnapshotBody(GameSnapshot snapshot)`
  - `GameSnapshot decodeSnapshotBody(Uint8List body)`
  - `int fletcher16(Uint8List data)` — used again by Task 2
  - `const int kGameSnapshotFormatVersion`
  - `class GameSharePayloadCorruptedException implements Exception {}`
  - `class GameShareVersionException implements Exception { final int foundVersion; }`

- [ ] **Step 1: Write failing equality tests for `RoundScore` and `ScoringRules`**

Append to `test/scoring_rules_test.dart`:

```dart
  group('value equality', () {
    test('two RoundScore instances with the same fields are equal', () {
      const a = RoundScore(35, penalty: 30, isPenalty: true, isCaller: true);
      final b = RoundScore(35, penalty: 30, isPenalty: true, isCaller: true);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('RoundScore instances with different fields are not equal', () {
      const a = RoundScore(0, isCaller: true);
      const b = RoundScore(0, skipWinnerHalf: true);

      expect(a == b, isFalse);
    });

    test('two ScoringRules with the same fields are equal', () {
      const a = ScoringRules(endScore: 150, callScore: 7);
      const b = ScoringRules(endScore: 150, callScore: 7);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ScoringRules with different fields are not equal', () {
      const a = ScoringRules(endScore: 150);
      const b = ScoringRules(endScore: 124);

      expect(a == b, isFalse);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/scoring_rules_test.dart`
Expected: FAIL — the "different fields are not equal" cases pass by accident (default identity inequality), but the "same fields are equal" cases FAIL because `RoundScore`/`ScoringRules` have no `==` override yet, so two separately-constructed non-const instances are not `identical()`.

- [ ] **Step 3: Add equality to `RoundScore` and `ScoringRules`**

In `lib/scoring_rules.dart`, add to the end of the `RoundScore` class body (after the constructor, before the closing `}` at line 22):

```dart

  @override
  bool operator ==(Object other) =>
      other is RoundScore &&
      value == other.value &&
      penalty == other.penalty &&
      isPenalty == other.isPenalty &&
      isInactive == other.isInactive &&
      isCaller == other.isCaller &&
      skipWinnerHalf == other.skipWinnerHalf;

  @override
  int get hashCode => Object.hash(
    value,
    penalty,
    isPenalty,
    isInactive,
    isCaller,
    skipWinnerHalf,
  );
```

And to the end of the `ScoringRules` class body (after the constructor, before the closing `}` at line 44):

```dart

  @override
  bool operator ==(Object other) =>
      other is ScoringRules &&
      endScore == other.endScore &&
      callScore == other.callScore &&
      halvingRuleEnabled == other.halvingRuleEnabled &&
      winnerHalfPreviousScoreRule == other.winnerHalfPreviousScoreRule &&
      asafPenaltyRuleEnabled == other.asafPenaltyRuleEnabled &&
      penaltyOnTieRuleEnabled == other.penaltyOnTieRuleEnabled &&
      penaltyScore == other.penaltyScore &&
      newPlayerJoinPenalty == other.newPlayerJoinPenalty;

  @override
  int get hashCode => Object.hash(
    endScore,
    callScore,
    halvingRuleEnabled,
    winnerHalfPreviousScoreRule,
    asafPenaltyRuleEnabled,
    penaltyOnTieRuleEnabled,
    penaltyScore,
    newPlayerJoinPenalty,
  );
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/scoring_rules_test.dart`
Expected: PASS (all tests, including the pre-existing ones — const-canonicalized instances still compare equal under the new `==`).

- [ ] **Step 5: Commit**

```bash
git add lib/scoring_rules.dart test/scoring_rules_test.dart
git commit -m "Add value equality to RoundScore and ScoringRules"
```

- [ ] **Step 6: Write failing codec round-trip tests**

Create `test/game_share/game_snapshot_codec_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/game_share/game_snapshot.dart';
import 'package:yaniv/game_share/game_snapshot_codec.dart';
import 'package:yaniv/scoring_rules.dart';

void main() {
  test('round-trips a typical game', () {
    final snapshot = GameSnapshot(
      players: const [
        PlayerSnapshot(name: 'Alice', joinedAtRound: 0),
        PlayerSnapshot(name: 'Bob', joinedAtRound: 0),
        PlayerSnapshot(name: 'Cleo', joinedAtRound: 2),
      ],
      roundHistory: const [
        [
          RoundScore(0, isCaller: true),
          RoundScore(12),
          RoundScore(0, isInactive: true),
        ],
        [
          RoundScore(35, penalty: 30, isPenalty: true, isCaller: true),
          RoundScore(0),
          RoundScore(0, isInactive: true),
        ],
        [RoundScore(4), RoundScore(0, isCaller: true), RoundScore(10)],
      ],
      rules: const ScoringRules(
        endScore: 150,
        callScore: 7,
        penaltyScore: 30,
        newPlayerJoinPenalty: 15,
      ),
    );

    final decoded = decodeSnapshotBody(encodeSnapshotBody(snapshot));

    expect(decoded, snapshot);
  });

  test('round-trips a game with no rounds played yet', () {
    final snapshot = GameSnapshot(
      players: const [
        PlayerSnapshot(name: 'Alice', joinedAtRound: 0),
        PlayerSnapshot(name: 'Bob', joinedAtRound: 0),
      ],
      roundHistory: const [],
      rules: const ScoringRules(),
    );

    final decoded = decodeSnapshotBody(encodeSnapshotBody(snapshot));

    expect(decoded, snapshot);
  });

  test('round-trips every rule toggle combination', () {
    for (final halving in [true, false]) {
      for (final winnerHalf in [true, false]) {
        for (final asaf in [true, false]) {
          for (final tiePenalty in [true, false]) {
            final snapshot = GameSnapshot(
              players: const [
                PlayerSnapshot(name: 'Alice', joinedAtRound: 0),
                PlayerSnapshot(name: 'Bob', joinedAtRound: 0),
              ],
              roundHistory: const [
                [RoundScore(0, isCaller: true), RoundScore(9)],
              ],
              rules: ScoringRules(
                halvingRuleEnabled: halving,
                winnerHalfPreviousScoreRule: winnerHalf,
                asafPenaltyRuleEnabled: asaf,
                penaltyOnTieRuleEnabled: tiePenalty,
              ),
            );

            final decoded = decodeSnapshotBody(encodeSnapshotBody(snapshot));

            expect(decoded, snapshot);
          }
        }
      }
    }
  });

  test('round-trips a non-ASCII player name', () {
    final snapshot = GameSnapshot(
      players: const [
        PlayerSnapshot(name: 'José 🎉', joinedAtRound: 0),
        PlayerSnapshot(name: 'Bob', joinedAtRound: 0),
      ],
      roundHistory: const [],
      rules: const ScoringRules(),
    );

    final decoded = decodeSnapshotBody(encodeSnapshotBody(snapshot));

    expect(decoded, snapshot);
  });

  test('rejects a payload whose checksum was tampered with', () {
    final snapshot = GameSnapshot(
      players: const [PlayerSnapshot(name: 'Alice', joinedAtRound: 0)],
      roundHistory: const [],
      rules: const ScoringRules(),
    );
    final body = encodeSnapshotBody(snapshot);
    final tampered = Uint8List.fromList(body);
    tampered[0] = tampered[0] ^ 0xFF;

    expect(
      () => decodeSnapshotBody(tampered),
      throwsA(isA<GameSharePayloadCorruptedException>()),
    );
  });

  test('rejects a payload from a newer, unsupported format version', () {
    final snapshot = GameSnapshot(
      players: const [PlayerSnapshot(name: 'Alice', joinedAtRound: 0)],
      roundHistory: const [],
      rules: const ScoringRules(),
    );
    final body = encodeSnapshotBody(snapshot);
    final payload = Uint8List.fromList(body.sublist(0, body.length - 2));
    payload[0] = kGameSnapshotFormatVersion + 1;
    final rebuilt = _withChecksum(payload);

    expect(
      () => decodeSnapshotBody(rebuilt),
      throwsA(isA<GameShareVersionException>()),
    );
  });
}

Uint8List _withChecksum(Uint8List payload) {
  final checksum = fletcher16(payload);
  final result = Uint8List(payload.length + 2);
  result.setRange(0, payload.length, payload);
  result[payload.length] = (checksum >> 8) & 0xFF;
  result[payload.length + 1] = checksum & 0xFF;
  return result;
}
```

(The `dart:convert` import above is unused by this file's current tests but harmless; remove it if `flutter analyze` flags it as unused.)

- [ ] **Step 7: Run tests to verify they fail**

Run: `flutter test test/game_share/game_snapshot_codec_test.dart`
Expected: FAIL to compile — `lib/game_share/game_snapshot.dart` and `lib/game_share/game_snapshot_codec.dart` don't exist yet.

- [ ] **Step 8: Create the snapshot model**

Create `lib/game_share/game_snapshot.dart`:

```dart
import 'package:yaniv/scoring_rules.dart';

class PlayerSnapshot {
  final String name;
  final int joinedAtRound;

  const PlayerSnapshot({required this.name, required this.joinedAtRound});

  @override
  bool operator ==(Object other) =>
      other is PlayerSnapshot &&
      name == other.name &&
      joinedAtRound == other.joinedAtRound;

  @override
  int get hashCode => Object.hash(name, joinedAtRound);
}

class GameSnapshot {
  final List<PlayerSnapshot> players;
  final List<List<RoundScore>> roundHistory;
  final ScoringRules rules;

  const GameSnapshot({
    required this.players,
    required this.roundHistory,
    required this.rules,
  });

  @override
  bool operator ==(Object other) {
    if (other is! GameSnapshot) return false;
    if (rules != other.rules) return false;
    if (!_listEquals(players, other.players)) return false;
    if (roundHistory.length != other.roundHistory.length) return false;
    for (var r = 0; r < roundHistory.length; r++) {
      if (!_listEquals(roundHistory[r], other.roundHistory[r])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(players),
    Object.hashAll(roundHistory.map(Object.hashAll)),
    rules,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

- [ ] **Step 9: Create the codec**

Create `lib/game_share/game_snapshot_codec.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:yaniv/scoring_rules.dart';

import 'game_snapshot.dart';

const int kGameSnapshotFormatVersion = 1;

class GameSharePayloadCorruptedException implements Exception {
  const GameSharePayloadCorruptedException();

  @override
  String toString() => 'Game share payload failed its integrity check';
}

class GameShareVersionException implements Exception {
  final int foundVersion;

  const GameShareVersionException(this.foundVersion);

  @override
  String toString() =>
      'Game share payload uses format version $foundVersion, this app '
      'supports up to $kGameSnapshotFormatVersion';
}

/// Fletcher-16 checksum — cheap enough for a QR-misread integrity check,
/// not meant to defend against a deliberate attacker.
int fletcher16(Uint8List data) {
  var sum1 = 0;
  var sum2 = 0;
  for (final byte in data) {
    sum1 = (sum1 + byte) % 255;
    sum2 = (sum2 + sum1) % 255;
  }
  return (sum2 << 8) | sum1;
}

Uint8List encodeSnapshotBody(GameSnapshot snapshot) {
  final writer = BytesBuilder();
  writer.addByte(kGameSnapshotFormatVersion);

  final rules = snapshot.rules;
  _writeUint16(writer, rules.endScore);
  _writeUint16(writer, rules.callScore);
  _writeUint16(writer, rules.penaltyScore);
  _writeUint16(writer, rules.newPlayerJoinPenalty);
  var ruleFlags = 0;
  if (rules.halvingRuleEnabled) ruleFlags |= 0x01;
  if (rules.winnerHalfPreviousScoreRule) ruleFlags |= 0x02;
  if (rules.asafPenaltyRuleEnabled) ruleFlags |= 0x04;
  if (rules.penaltyOnTieRuleEnabled) ruleFlags |= 0x08;
  writer.addByte(ruleFlags);

  writer.addByte(snapshot.players.length);
  for (final player in snapshot.players) {
    final nameBytes = utf8.encode(player.name);
    writer.addByte(nameBytes.length);
    writer.add(nameBytes);
    _writeUint16(writer, player.joinedAtRound);
  }

  _writeUint16(writer, snapshot.roundHistory.length);
  for (final round in snapshot.roundHistory) {
    for (final score in round) {
      _writeUint16(writer, score.value);
      _writeUint16(writer, score.penalty);
      var scoreFlags = 0;
      if (score.isPenalty) scoreFlags |= 0x01;
      if (score.isInactive) scoreFlags |= 0x02;
      if (score.isCaller) scoreFlags |= 0x04;
      if (score.skipWinnerHalf) scoreFlags |= 0x08;
      writer.addByte(scoreFlags);
    }
  }

  final payload = writer.toBytes();
  final checksum = fletcher16(payload);
  final withChecksum = BytesBuilder();
  withChecksum.add(payload);
  _writeUint16(withChecksum, checksum);
  return withChecksum.toBytes();
}

GameSnapshot decodeSnapshotBody(Uint8List body) {
  if (body.length < 3) {
    throw const GameSharePayloadCorruptedException();
  }
  final payload = body.sublist(0, body.length - 2);
  final expectedChecksum = _readUint16(body, body.length - 2);
  if (fletcher16(payload) != expectedChecksum) {
    throw const GameSharePayloadCorruptedException();
  }

  final reader = _ByteReader(payload);
  final version = reader.readByte();
  if (version > kGameSnapshotFormatVersion) {
    throw GameShareVersionException(version);
  }

  final endScore = reader.readUint16();
  final callScore = reader.readUint16();
  final penaltyScore = reader.readUint16();
  final newPlayerJoinPenalty = reader.readUint16();
  final ruleFlags = reader.readByte();
  final rules = ScoringRules(
    endScore: endScore,
    callScore: callScore,
    halvingRuleEnabled: ruleFlags & 0x01 != 0,
    winnerHalfPreviousScoreRule: ruleFlags & 0x02 != 0,
    asafPenaltyRuleEnabled: ruleFlags & 0x04 != 0,
    penaltyOnTieRuleEnabled: ruleFlags & 0x08 != 0,
    penaltyScore: penaltyScore,
    newPlayerJoinPenalty: newPlayerJoinPenalty,
  );

  final playerCount = reader.readByte();
  final players = <PlayerSnapshot>[];
  for (var i = 0; i < playerCount; i++) {
    final nameLength = reader.readByte();
    final name = utf8.decode(reader.readBytes(nameLength));
    final joinedAtRound = reader.readUint16();
    players.add(PlayerSnapshot(name: name, joinedAtRound: joinedAtRound));
  }

  final roundCount = reader.readUint16();
  final roundHistory = <List<RoundScore>>[];
  for (var r = 0; r < roundCount; r++) {
    final round = <RoundScore>[];
    for (var p = 0; p < playerCount; p++) {
      final value = reader.readUint16();
      final penalty = reader.readUint16();
      final scoreFlags = reader.readByte();
      round.add(
        RoundScore(
          value,
          penalty: penalty,
          isPenalty: scoreFlags & 0x01 != 0,
          isInactive: scoreFlags & 0x02 != 0,
          isCaller: scoreFlags & 0x04 != 0,
          skipWinnerHalf: scoreFlags & 0x08 != 0,
        ),
      );
    }
    roundHistory.add(round);
  }

  return GameSnapshot(
    players: players,
    roundHistory: roundHistory,
    rules: rules,
  );
}

void _writeUint16(BytesBuilder writer, int value) {
  writer.addByte((value >> 8) & 0xFF);
  writer.addByte(value & 0xFF);
}

int _readUint16(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

class _ByteReader {
  final Uint8List _bytes;
  int _offset = 0;

  _ByteReader(this._bytes);

  int readByte() => _bytes[_offset++];

  int readUint16() {
    final value = _readUint16(_bytes, _offset);
    _offset += 2;
    return value;
  }

  Uint8List readBytes(int length) {
    final slice = _bytes.sublist(_offset, _offset + length);
    _offset += length;
    return slice;
  }
}
```

Malformed/truncated input (e.g. a body shorter than the header claims) surfaces as a `RangeError` from `sublist`/index access — callers in later tasks treat any exception from `decodeSnapshotBody` other than `GameShareVersionException` as "corrupted, cannot import."

- [ ] **Step 10: Run tests to verify they pass**

Run: `flutter test test/game_share/game_snapshot_codec_test.dart`
Expected: PASS

- [ ] **Step 11: Commit**

```bash
git add lib/game_share/game_snapshot.dart lib/game_share/game_snapshot_codec.dart test/game_share/game_snapshot_codec_test.dart
git commit -m "Add compact binary codec for sharing a game snapshot"
```

---

### Task 2: QR chunking and reassembly

**Files:**
- Create: `lib/game_share/qr_chunker.dart`
- Create: `test/game_share/qr_chunker_test.dart`

**Interfaces:**
- Consumes: `fletcher16(Uint8List) -> int` from `lib/game_share/game_snapshot_codec.dart` (Task 1).
- Produces:
  - `const int maxChunkPayloadBytes` (700)
  - `const int maxChunkCount` (40)
  - `const int kQrFrameFormatVersion`
  - `List<String> chunkForQr(Uint8List body)` — throws `GameShareTooLargeException` if it would need more than `maxChunkCount` frames
  - `class GameShareTooLargeException implements Exception { final int requiredChunks; }`
  - `enum AddChunkResult { added, duplicate, complete, invalidFormat, versionMismatch, corrupted }`
  - `class GameShareAssembler` with `addChunk(String) -> AddChunkResult`, `bool get isComplete`, `int get expectedChunkCount`, `int get receivedChunkCount`, `Uint8List assembleBody()`, `void reset()`

- [ ] **Step 1: Write failing chunking/reassembly tests**

Create `test/game_share/qr_chunker_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/game_share/qr_chunker.dart';

void main() {
  test('a small payload fits in a single frame', () {
    final body = Uint8List.fromList(List.generate(50, (i) => i));
    final frames = chunkForQr(body);

    expect(frames, hasLength(1));

    final assembler = GameShareAssembler();
    expect(assembler.addChunk(frames[0]), AddChunkResult.complete);
    expect(assembler.assembleBody(), body);
  });

  test(
    'a large payload splits into multiple frames and reassembles out of order',
    () {
      final body = Uint8List.fromList(List.generate(2500, (i) => i % 256));
      final frames = chunkForQr(body);

      expect(frames.length, greaterThan(1));

      final assembler = GameShareAssembler();
      final shuffled = frames.reversed.toList();
      for (var i = 0; i < shuffled.length - 1; i++) {
        expect(assembler.addChunk(shuffled[i]), AddChunkResult.added);
      }
      expect(assembler.addChunk(shuffled.last), AddChunkResult.complete);
      expect(assembler.assembleBody(), body);
    },
  );

  test('a duplicate frame is reported without breaking assembly', () {
    final body = Uint8List.fromList(List.generate(2500, (i) => i % 256));
    final frames = chunkForQr(body);
    final assembler = GameShareAssembler();

    assembler.addChunk(frames[0]);
    expect(assembler.addChunk(frames[0]), AddChunkResult.duplicate);

    for (var i = 1; i < frames.length; i++) {
      assembler.addChunk(frames[i]);
    }
    expect(assembler.isComplete, isTrue);
    expect(assembler.assembleBody(), body);
  });

  test('a corrupted frame is rejected and does not corrupt assembly', () {
    final body = Uint8List.fromList(List.generate(50, (i) => i));
    final frames = chunkForQr(body);
    final rawFrame = base64Decode(frames[0]);
    rawFrame[rawFrame.length - 1] ^= 0xFF; // flip a payload byte
    final corruptedFrame = base64Encode(rawFrame);

    final assembler = GameShareAssembler();
    expect(assembler.addChunk(corruptedFrame), AddChunkResult.corrupted);
    expect(assembler.isComplete, isFalse);

    expect(assembler.addChunk(frames[0]), AddChunkResult.complete);
  });

  test('garbage text is rejected as an invalid format', () {
    final assembler = GameShareAssembler();
    expect(
      assembler.addChunk('not a valid qr payload'),
      AddChunkResult.invalidFormat,
    );
  });

  test('a frame from a newer format version is rejected', () {
    final body = Uint8List.fromList(List.generate(10, (i) => i));
    final frames = chunkForQr(body);
    final rawFrame = base64Decode(frames[0]);
    rawFrame[2] = kQrFrameFormatVersion + 1; // version byte

    final assembler = GameShareAssembler();
    expect(
      assembler.addChunk(base64Encode(rawFrame)),
      AddChunkResult.versionMismatch,
    );
  });

  test('reset clears assembled state', () {
    final body = Uint8List.fromList(List.generate(50, (i) => i));
    final frames = chunkForQr(body);
    final assembler = GameShareAssembler();
    assembler.addChunk(frames[0]);

    assembler.reset();

    expect(assembler.isComplete, isFalse);
    expect(assembler.receivedChunkCount, 0);
  });

  test('a payload needing too many chunks is rejected up front', () {
    final body = Uint8List(30000);

    expect(() => chunkForQr(body), throwsA(isA<GameShareTooLargeException>()));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/game_share/qr_chunker_test.dart`
Expected: FAIL to compile — `lib/game_share/qr_chunker.dart` doesn't exist yet.

- [ ] **Step 3: Create the chunker**

Create `lib/game_share/qr_chunker.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'game_snapshot_codec.dart' show fletcher16;

const int kQrFrameFormatVersion = 1;
const int _magicByte1 = 0x59; // 'Y'
const int _magicByte2 = 0x53; // 'S'

/// Keeps each QR frame small enough to stay reliably scannable.
const int maxChunkPayloadBytes = 700;

/// Sanity cap: a body needing more chunks than this is rejected as too
/// large to share via QR, rather than producing an unusable QR set.
const int maxChunkCount = 40;

class GameShareTooLargeException implements Exception {
  final int requiredChunks;

  const GameShareTooLargeException(this.requiredChunks);

  @override
  String toString() =>
      'Game is too large to share via QR ($requiredChunks chunks needed)';
}

/// Splits [body] into one or more base64 QR-ready frame strings.
List<String> chunkForQr(Uint8List body) {
  final chunkCount = (body.length / maxChunkPayloadBytes).ceil();
  if (chunkCount > maxChunkCount) {
    throw GameShareTooLargeException(chunkCount);
  }

  final frames = <String>[];
  for (var i = 0; i < chunkCount; i++) {
    final start = i * maxChunkPayloadBytes;
    final end = (start + maxChunkPayloadBytes < body.length)
        ? start + maxChunkPayloadBytes
        : body.length;
    final payload = body.sublist(start, end);

    final frame = BytesBuilder();
    frame.addByte(_magicByte1);
    frame.addByte(_magicByte2);
    frame.addByte(kQrFrameFormatVersion);
    frame.addByte(i);
    frame.addByte(chunkCount);
    final checksum = fletcher16(payload);
    frame.addByte((checksum >> 8) & 0xFF);
    frame.addByte(checksum & 0xFF);
    frame.add(payload);

    frames.add(base64Encode(frame.toBytes()));
  }
  return frames;
}

enum AddChunkResult {
  added,
  duplicate,
  complete,
  invalidFormat,
  versionMismatch,
  corrupted,
}

class GameShareAssembler {
  final Map<int, Uint8List> _chunks = {};
  int? _expectedChunkCount;

  bool get isComplete =>
      _expectedChunkCount != null && _chunks.length == _expectedChunkCount;

  int get expectedChunkCount => _expectedChunkCount ?? 0;

  int get receivedChunkCount => _chunks.length;

  AddChunkResult addChunk(String rawText) {
    Uint8List frame;
    try {
      frame = base64Decode(rawText);
    } catch (_) {
      return AddChunkResult.invalidFormat;
    }

    if (frame.length < 7 || frame[0] != _magicByte1 || frame[1] != _magicByte2) {
      return AddChunkResult.invalidFormat;
    }

    final version = frame[2];
    if (version > kQrFrameFormatVersion) {
      return AddChunkResult.versionMismatch;
    }

    final chunkIndex = frame[3];
    final chunkCount = frame[4];
    final expectedChecksum = (frame[5] << 8) | frame[6];
    final payload = frame.sublist(7);

    if (fletcher16(payload) != expectedChecksum) {
      return AddChunkResult.corrupted;
    }

    if (chunkIndex >= chunkCount) {
      return AddChunkResult.invalidFormat;
    }

    if (_expectedChunkCount != null && chunkCount != _expectedChunkCount) {
      // A frame from a different share set; ignore it rather than
      // corrupting the set already in progress.
      return AddChunkResult.invalidFormat;
    }

    _expectedChunkCount = chunkCount;

    if (_chunks.containsKey(chunkIndex)) {
      return AddChunkResult.duplicate;
    }

    _chunks[chunkIndex] = payload;
    return isComplete ? AddChunkResult.complete : AddChunkResult.added;
  }

  Uint8List assembleBody() {
    if (!isComplete) {
      throw StateError('Cannot assemble before all chunks are received');
    }
    final builder = BytesBuilder();
    for (var i = 0; i < _expectedChunkCount!; i++) {
      builder.add(_chunks[i]!);
    }
    return builder.toBytes();
  }

  void reset() {
    _chunks.clear();
    _expectedChunkCount = null;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/game_share/qr_chunker_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/game_share/qr_chunker.dart test/game_share/qr_chunker_test.dart
git commit -m "Add QR chunking and reassembly for oversized game payloads"
```

---

### Task 3: Share screen (generate QR) + wire into GameScreen

**Files:**
- Modify: `pubspec.yaml` (add `qr_flutter`)
- Create: `lib/game_share/share_game_qr_screen.dart`
- Create: `test/game_share/share_game_qr_screen_test.dart`
- Modify: `lib/game_screen.dart` (add a "Share Game" action)

**Interfaces:**
- Consumes: `GameSnapshot`/`PlayerSnapshot` (Task 1), `encodeSnapshotBody` (Task 1), `chunkForQr`/`GameShareTooLargeException` (Task 2).
- Produces: `class ShareGameQrScreen extends StatefulWidget { final GameSnapshot snapshot; }`

- [ ] **Step 1: Add the QR rendering dependency**

Run: `flutter pub add qr_flutter`
Expected: `pubspec.yaml` gains a `qr_flutter` entry and `flutter pub get` completes without errors.

- [ ] **Step 2: Write failing widget tests**

Create `test/game_share/share_game_qr_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yaniv/game_share/game_snapshot.dart';
import 'package:yaniv/game_share/share_game_qr_screen.dart';
import 'package:yaniv/scoring_rules.dart';

void main() {
  testWidgets('renders a single QR for a small game', (tester) async {
    final snapshot = GameSnapshot(
      players: const [
        PlayerSnapshot(name: 'Alice', joinedAtRound: 0),
        PlayerSnapshot(name: 'Bob', joinedAtRound: 0),
      ],
      roundHistory: const [
        [RoundScore(0, isCaller: true), RoundScore(12)],
      ],
      rules: const ScoringRules(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ShareGameQrScreen(snapshot: snapshot)),
    );
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('QR 1 of'), findsNothing);
  });

  testWidgets('cycles through multiple QR frames for a large game', (
    tester,
  ) async {
    final snapshot = GameSnapshot(
      players: const [
        PlayerSnapshot(name: 'A', joinedAtRound: 0),
        PlayerSnapshot(name: 'B', joinedAtRound: 0),
      ],
      roundHistory: List.generate(
        400,
        (_) => const [RoundScore(0, isCaller: true), RoundScore(12)],
      ),
      rules: const ScoringRules(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ShareGameQrScreen(snapshot: snapshot)),
    );
    await tester.pump();

    expect(find.textContaining('QR 1 of'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.textContaining('QR 2 of'), findsOneWidget);
  });

  testWidgets('shows an error when the game is too large for QR', (
    tester,
  ) async {
    final snapshot = GameSnapshot(
      players: const [
        PlayerSnapshot(name: 'A', joinedAtRound: 0),
        PlayerSnapshot(name: 'B', joinedAtRound: 0),
      ],
      roundHistory: List.generate(
        3000,
        (_) => const [RoundScore(0, isCaller: true), RoundScore(12)],
      ),
      rules: const ScoringRules(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ShareGameQrScreen(snapshot: snapshot)),
    );
    await tester.pump();

    expect(find.text('Game too large to share via QR'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/game_share/share_game_qr_screen_test.dart`
Expected: FAIL to compile — `lib/game_share/share_game_qr_screen.dart` doesn't exist yet.

- [ ] **Step 4: Create the share screen**

Create `lib/game_share/share_game_qr_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'game_snapshot.dart';
import 'game_snapshot_codec.dart';
import 'qr_chunker.dart';

class ShareGameQrScreen extends StatefulWidget {
  final GameSnapshot snapshot;

  const ShareGameQrScreen({super.key, required this.snapshot});

  @override
  State<ShareGameQrScreen> createState() => _ShareGameQrScreenState();
}

class _ShareGameQrScreenState extends State<ShareGameQrScreen> {
  List<String>? _frames;
  Object? _error;
  int _frameIndex = 0;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    try {
      final body = encodeSnapshotBody(widget.snapshot);
      _frames = chunkForQr(body);
      if (_frames!.length > 1) {
        _cycleTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
          setState(() {
            _frameIndex = (_frameIndex + 1) % _frames!.length;
          });
        });
      }
    } on GameShareTooLargeException catch (e) {
      _error = e;
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SHARE GAME')),
      body: Center(
        child: _error != null
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Game too large to share via QR',
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: _frames![_frameIndex],
                    size: 260,
                    key: ValueKey('qr_frame_$_frameIndex'),
                  ),
                  const SizedBox(height: 16),
                  if (_frames!.length > 1)
                    Text('QR ${_frameIndex + 1} of ${_frames!.length}')
                  else
                    const Text('Scan this on the other device'),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/game_share/share_game_qr_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Wire a "Share Game" action into `GameScreen`**

In `lib/game_screen.dart`, add imports near the top (after the existing `import 'scoring_rules.dart';` at line 11):

```dart
import 'game_share/game_snapshot.dart';
import 'game_share/share_game_qr_screen.dart';
```

In the `actions` list of the `AppBar` in `build()` (around line 1154), add a new `IconButton` before the existing "Manage Players" button:

```dart
            IconButton(
              icon: const Icon(Icons.qr_code_rounded),
              tooltip: "Share Game",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShareGameQrScreen(
                      snapshot: GameSnapshot(
                        players: [
                          for (final p in _players)
                            PlayerSnapshot(
                              name: p.name,
                              joinedAtRound: p.joinedAtRound,
                            ),
                        ],
                        roundHistory: _rawScoreHistory,
                        rules: _rules,
                      ),
                    ),
                  ),
                );
              },
            ),
```

- [ ] **Step 7: Verify the app still builds**

Run: `flutter analyze`
Expected: no new errors or warnings.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/game_share/share_game_qr_screen.dart test/game_share/share_game_qr_screen_test.dart lib/game_screen.dart
git commit -m "Add QR share screen and wire it into the game scoreboard"
```

---

### Task 4: Camera permission gate

**Files:**
- Modify: `pubspec.yaml` (add `mobile_scanner`, `permission_handler`)
- Modify: `android/app/src/main/AndroidManifest.xml` (add `CAMERA` permission)
- Modify: `ios/Runner/Info.plist` (add `NSCameraUsageDescription`)
- Create: `lib/game_share/camera_permission_gate.dart`
- Create: `test/game_share/camera_permission_gate_test.dart`

**Interfaces:**
- Produces: `class CameraPermissionGate extends StatefulWidget { final WidgetBuilder granted; final Future<PermissionStatus> Function() checkPermission; final Future<bool> Function() openSettings; }` — consumed by Task 5's `ScanGameQrScreen`.

- [ ] **Step 1: Add the scanning and permission dependencies**

Run: `flutter pub add mobile_scanner permission_handler`
Expected: `pubspec.yaml` gains both entries and `flutter pub get` completes without errors. If it reports a minimum Android SDK requirement higher than this project's current `minSdk`, bump `minSdk` in `android/app/build.gradle.kts` to match.

- [ ] **Step 2: Declare the camera permission on both platforms**

In `android/app/src/main/AndroidManifest.xml`, add this line right after the opening `<manifest ...>` tag (before `<application ...>`):

```xml
    <uses-permission android:name="android.permission.CAMERA" />
```

In `ios/Runner/Info.plist`, add this entry inside the top-level `<dict>` (e.g. right after the `<key>CFBundleSignature</key><string>????</string>` pair):

```xml
	<key>NSCameraUsageDescription</key>
	<string>Camera access is used to scan a game QR code shared from another device.</string>
```

- [ ] **Step 3: Write failing tests for the permission gate**

Create `test/game_share/camera_permission_gate_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaniv/game_share/camera_permission_gate.dart';

void main() {
  testWidgets('shows granted content when permission is granted', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async => PermissionStatus.granted,
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });

  testWidgets('shows a retry button when denied, which re-checks', (
    tester,
  ) async {
    var checkCount = 0;
    var nextStatus = PermissionStatus.denied;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async {
            checkCount++;
            return nextStatus;
          },
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('GRANT ACCESS'), findsOneWidget);
    expect(checkCount, 1);

    nextStatus = PermissionStatus.granted;
    await tester.tap(find.text('GRANT ACCESS'));
    await tester.pump();

    expect(checkCount, 2);
    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });

  testWidgets('shows an open-settings button when permanently denied', (
    tester,
  ) async {
    var settingsOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async => PermissionStatus.permanentlyDenied,
          openSettings: () async {
            settingsOpened = true;
            return true;
          },
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('OPEN SETTINGS'), findsOneWidget);
    await tester.tap(find.text('OPEN SETTINGS'));
    await tester.pump();

    expect(settingsOpened, isTrue);
  });

  testWidgets('re-checks permission when the app resumes', (tester) async {
    var checkCount = 0;
    var nextStatus = PermissionStatus.denied;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async {
            checkCount++;
            return nextStatus;
          },
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();
    expect(checkCount, 1);

    nextStatus = PermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(checkCount, 2);
    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `flutter test test/game_share/camera_permission_gate_test.dart`
Expected: FAIL to compile — `lib/game_share/camera_permission_gate.dart` doesn't exist yet.

- [ ] **Step 5: Create the permission gate**

Create `lib/game_share/camera_permission_gate.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<PermissionStatus> _requestCameraPermission() {
  return Permission.camera.request();
}

/// Shows [granted] once camera permission is available; otherwise shows an
/// explanation with a way to grant it (or open Settings if permanently
/// denied). Re-checks whenever the app resumes, in case the user granted
/// it from Settings and came back.
class CameraPermissionGate extends StatefulWidget {
  final WidgetBuilder granted;
  final Future<PermissionStatus> Function() checkPermission;
  final Future<bool> Function() openSettings;

  const CameraPermissionGate({
    super.key,
    required this.granted,
    this.checkPermission = _requestCameraPermission,
    this.openSettings = openAppSettings,
  });

  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate>
    with WidgetsBindingObserver {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final status = await widget.checkPermission();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case null:
        return const Center(child: CircularProgressIndicator());
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return widget.granted(context);
      case PermissionStatus.permanentlyDenied:
        return _PermissionMessage(
          message:
              'Camera access is needed to scan a game QR code. '
              'Enable it in Settings to continue.',
          buttonLabel: 'OPEN SETTINGS',
          onPressed: widget.openSettings,
        );
      default:
        return _PermissionMessage(
          message: 'Camera access is needed to scan a game QR code.',
          buttonLabel: 'GRANT ACCESS',
          onPressed: _refresh,
        );
    }
  }
}

class _PermissionMessage extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final Object Function() onPressed;

  const _PermissionMessage({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onPressed(),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/game_share/camera_permission_gate_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist lib/game_share/camera_permission_gate.dart test/game_share/camera_permission_gate_test.dart
git commit -m "Add camera permission gate for QR scanning"
```

---

### Task 5: Scan screen (read QR) + resume a game from it

**Files:**
- Create: `lib/game_share/scan_game_qr_screen.dart`
- Modify: `lib/game_screen.dart` (accept an optional `initialRoundHistory` to resume from)
- Modify: `lib/setup_screen.dart` (add a "Join via QR" action)

**Interfaces:**
- Consumes: `CameraPermissionGate` (Task 4), `GameShareAssembler`/`AddChunkResult` (Task 2), `decodeSnapshotBody`/`GameSnapshot`/`PlayerSnapshot` (Task 1).
- Produces: `class ScanGameQrScreen extends StatefulWidget { final ValueChanged<GameSnapshot> onImported; }`; `GameScreen` gains `final List<List<RoundScore>>? initialRoundHistory`.

This task's screens drive an actual camera, which `flutter_test` cannot exercise — the scan flow itself is manual QA (see the plan's testing note), but the pieces it's built from (the permission gate and the assembler) are already unit/widget-tested in Tasks 2 and 4.

- [ ] **Step 1: Let `GameScreen` resume from an existing round history**

In `lib/game_screen.dart`, add a field to the widget (after `final int newPlayerJoinPenalty;` at line 22):

```dart
  final List<List<RoundScore>>? initialRoundHistory;
```

Add it to the constructor (after `required this.newPlayerJoinPenalty,` at line 34):

```dart
    this.initialRoundHistory,
```

In `_GameScreenState.initState()` (line 53-59), resume from it if present:

```dart
  @override
  void initState() {
    super.initState();
    _players = List.from(widget.players);
    if (widget.initialRoundHistory != null) {
      _rawScoreHistory.addAll(widget.initialRoundHistory!);
      _recalculateTotals();
    }

    _loadMainBanner();
    _loadInterstitialAd();
  }
```

- [ ] **Step 2: Create the scan screen**

Create `lib/game_share/scan_game_qr_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'camera_permission_gate.dart';
import 'game_snapshot.dart';
import 'game_snapshot_codec.dart';
import 'qr_chunker.dart';

class ScanGameQrScreen extends StatefulWidget {
  final ValueChanged<GameSnapshot> onImported;

  const ScanGameQrScreen({super.key, required this.onImported});

  @override
  State<ScanGameQrScreen> createState() => _ScanGameQrScreenState();
}

class _ScanGameQrScreenState extends State<ScanGameQrScreen> {
  final _assembler = GameShareAssembler();
  final _controller = MobileScannerController();
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null) _handleFrame(raw);
    }
  }

  void _handleFrame(String raw) {
    switch (_assembler.addChunk(raw)) {
      case AddChunkResult.invalidFormat:
      case AddChunkResult.corrupted:
        setState(() => _statusMessage = 'Not a valid game QR');
        break;
      case AddChunkResult.versionMismatch:
        _controller.stop();
        setState(() => _statusMessage = 'Update the app to import this game');
        break;
      case AddChunkResult.duplicate:
      case AddChunkResult.added:
        setState(
          () => _statusMessage =
              'Scanned ${_assembler.receivedChunkCount} of '
              '${_assembler.expectedChunkCount}',
        );
        break;
      case AddChunkResult.complete:
        _finish();
        break;
    }
  }

  void _finish() {
    _controller.stop();
    try {
      final snapshot = decodeSnapshotBody(_assembler.assembleBody());
      widget.onImported(snapshot);
    } catch (_) {
      _assembler.reset();
      _controller.start();
      setState(() => _statusMessage = 'Scan failed, please try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SCAN GAME QR')),
      body: CameraPermissionGate(
        granted: (context) => Stack(
          children: [
            MobileScanner(controller: _controller, onDetect: _handleDetect),
            if (_statusMessage != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add a "Join via QR" action to `SetupScreen`**

In `lib/setup_screen.dart`, add imports after the existing `import 'package:yaniv/player.dart';` at line 4:

```dart
import 'game_share/game_snapshot.dart';
import 'game_share/scan_game_qr_screen.dart';
```

Add a method to `SetupScreenState` (near `_navigateToGame`, around line 202):

```dart
  void _navigateToImportedGame(GameSnapshot snapshot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          players: [
            for (final p in snapshot.players)
              Player(p.name, joinedAtRound: p.joinedAtRound),
          ],
          initialRoundHistory: snapshot.roundHistory,
          endScore: snapshot.rules.endScore,
          callScore: snapshot.rules.callScore,
          halvingRuleEnabled: snapshot.rules.halvingRuleEnabled,
          winnerHalfPreviousScoreRule:
              snapshot.rules.winnerHalfPreviousScoreRule,
          asafPenaltyRuleEnabled: snapshot.rules.asafPenaltyRuleEnabled,
          penaltyOnTieRuleEnabled: snapshot.rules.penaltyOnTieRuleEnabled,
          penaltyScore: snapshot.rules.penaltyScore,
          newPlayerJoinPenalty: snapshot.rules.newPlayerJoinPenalty,
        ),
      ),
    );
  }
```

In the `SliverAppBar.large`'s `actions` list (around line 295-307), add a new button before the history `IconButton`:

```dart
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: "Join via QR",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanGameQrScreen(
                        onImported: (snapshot) {
                          Navigator.pop(context);
                          _navigateToImportedGame(snapshot);
                        },
                      ),
                    ),
                  );
                },
              ),
```

- [ ] **Step 4: Verify the app still builds**

Run: `flutter analyze`
Expected: no new errors or warnings.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS — every test from this plan plus all pre-existing tests.

- [ ] **Step 6: Commit**

```bash
git add lib/game_share/scan_game_qr_screen.dart lib/game_screen.dart lib/setup_screen.dart
git commit -m "Add QR scan screen and resume-from-import support"
```

- [ ] **Step 7: Manual QA (camera-dependent, not unit-testable)**

On two physical devices (or one device plus an emulator/simulator with camera access):
1. Start a game on device A, play a few rounds, tap "Share Game" — confirm a QR appears.
2. On device B, tap "Join via QR" and grant camera access when prompted — confirm it scans and opens `GameScreen` with the same players, rounds, and totals as device A.
3. Add enough rounds/players on device A to force multiple QR frames — confirm the share screen cycles frames and device B's scan screen shows "Scanned X of Y" progress and completes.
4. Deny camera permission on device B — confirm the "GRANT ACCESS" message appears and requesting again works.
5. Point device B's scanner at an unrelated QR code — confirm it shows "Not a valid game QR" without crashing.
