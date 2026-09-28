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

  group('encode-side validation', () {
    test('a negative round score throws GameShareUnsupportedException', () {
      final snapshot = GameSnapshot(
        players: const [PlayerSnapshot(name: 'Alice', joinedAtRound: 0)],
        roundHistory: const [
          [RoundScore(-1)],
        ],
        rules: const ScoringRules(),
      );

      expect(
        () => encodeSnapshotBody(snapshot),
        throwsA(isA<GameShareUnsupportedException>()),
      );
    });

    test('an out-of-range endScore throws GameShareUnsupportedException', () {
      final snapshot = GameSnapshot(
        players: const [PlayerSnapshot(name: 'Alice', joinedAtRound: 0)],
        roundHistory: const [],
        rules: const ScoringRules(endScore: 0x10000),
      );

      expect(
        () => encodeSnapshotBody(snapshot),
        throwsA(isA<GameShareUnsupportedException>()),
      );
    });

    test(
      'a player name longer than 255 UTF-8 bytes throws GameShareUnsupportedException',
      () {
        final snapshot = GameSnapshot(
          players: [PlayerSnapshot(name: 'A' * 256, joinedAtRound: 0)],
          roundHistory: const [],
          rules: const ScoringRules(),
        );

        expect(
          () => encodeSnapshotBody(snapshot),
          throwsA(isA<GameShareUnsupportedException>()),
        );
      },
    );

    test('more than 255 players throws GameShareUnsupportedException', () {
      final snapshot = GameSnapshot(
        players: [
          for (var i = 0; i < 256; i++)
            PlayerSnapshot(name: 'P$i', joinedAtRound: 0),
        ],
        roundHistory: const [],
        rules: const ScoringRules(),
      );

      expect(
        () => encodeSnapshotBody(snapshot),
        throwsA(isA<GameShareUnsupportedException>()),
      );
    });

    test('boundary values (255 players, 255-byte name, 0xFFFF value/penalty) '
        'do not throw and round-trip correctly', () {
      final players = [
        PlayerSnapshot(name: 'A' * 255, joinedAtRound: 0),
        for (var i = 1; i < 255; i++)
          PlayerSnapshot(name: 'P$i', joinedAtRound: 0),
      ];
      expect(players.length, 255);

      final snapshot = GameSnapshot(
        players: players,
        roundHistory: [
          [
            for (var i = 0; i < 255; i++)
              const RoundScore(0xFFFF, penalty: 0xFFFF),
          ],
        ],
        rules: const ScoringRules(),
      );

      final decoded = decodeSnapshotBody(encodeSnapshotBody(snapshot));

      expect(decoded, snapshot);
    });
  });

  group('decode-side consistency validation', () {
    test('decoding a payload with zero players throws', () {
      // Hand-built: version, rules (default), playerCount=0, roundCount=0.
      final payload = <int>[
        kGameSnapshotFormatVersion,
        0, 124, // endScore
        0, 5, // callScore
        0, 30, // penaltyScore
        0, 10, // newPlayerJoinPenalty
        0x0F, // ruleFlags: all default rule toggles on
        0, // playerCount
        0, 0, // roundCount
      ];
      final rebuilt = _withChecksum(Uint8List.fromList(payload));

      expect(
        () => decodeSnapshotBody(rebuilt),
        throwsA(isA<GameSharePayloadCorruptedException>()),
      );
    });

    test(
      'decoding a payload with joinedAtRound beyond the round count throws',
      () {
        final snapshot = GameSnapshot(
          players: const [PlayerSnapshot(name: 'Alice', joinedAtRound: 5)],
          roundHistory: const [],
          rules: const ScoringRules(),
        );
        final body = encodeSnapshotBody(snapshot);

        expect(
          () => decodeSnapshotBody(body),
          throwsA(isA<GameSharePayloadCorruptedException>()),
        );
      },
    );

    test('decoding a payload with unexpected trailing bytes throws', () {
      final snapshot = GameSnapshot(
        players: const [PlayerSnapshot(name: 'Alice', joinedAtRound: 0)],
        roundHistory: const [],
        rules: const ScoringRules(),
      );
      final body = encodeSnapshotBody(snapshot);
      final payloadWithoutChecksum = body.sublist(0, body.length - 2);
      final withTrailingByte = Uint8List.fromList([
        ...payloadWithoutChecksum,
        0xAB,
      ]);
      final rebuilt = _withChecksum(withTrailingByte);

      expect(
        () => decodeSnapshotBody(rebuilt),
        throwsA(isA<GameSharePayloadCorruptedException>()),
      );
    });
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
