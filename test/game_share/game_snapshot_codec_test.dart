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
