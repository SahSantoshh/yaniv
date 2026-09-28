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

  testWidgets(
    "shows a distinct error when the game's values can't be shared via QR",
    (tester) async {
      final snapshot = GameSnapshot(
        players: const [
          PlayerSnapshot(name: 'Alice', joinedAtRound: 0),
          PlayerSnapshot(name: 'Bob', joinedAtRound: 0),
        ],
        roundHistory: const [
          [RoundScore(-1), RoundScore(12)],
        ],
        rules: const ScoringRules(),
      );

      await tester.pumpWidget(
        MaterialApp(home: ShareGameQrScreen(snapshot: snapshot)),
      );
      await tester.pump();

      expect(find.text("This game can't be shared via QR"), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    },
  );
}
