import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yaniv/game_screen.dart';
import 'package:yaniv/main.dart';
import 'package:yaniv/player.dart';
import 'package:yaniv/scoreboard_widget.dart';
import 'package:yaniv/scoring_rules.dart';

void main() {
  testWidgets('Setup screen opens with two players', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const YanivScoreApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('YANIV'), findsAtLeastNWidgets(1));
    expect(find.text('PLAYERS'), findsOneWidget);
    expect(find.text('Enter name...'), findsNWidgets(2));

    await tester.tap(find.text('ADD NEW PLAYER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Enter name...'), findsNWidgets(3));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
    'GameScreen resumes with correct totals from an imported round history',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            players: [Player('Alice'), Player('Bob')],
            endScore: 124,
            callScore: 5,
            halvingRuleEnabled: true,
            winnerHalfPreviousScoreRule: true,
            asafPenaltyRuleEnabled: true,
            penaltyOnTieRuleEnabled: true,
            penaltyScore: 30,
            newPlayerJoinPenalty: 10,
            initialRoundHistory: const [
              [RoundScore(0, isCaller: true), RoundScore(37)],
            ],
          ),
        ),
      );
      await tester.pump();

      // Bob's total (37) should already be showing on the scoreboard,
      // without adding any round.
      expect(
        find.descendant(of: find.byType(Scoreboard), matching: find.text('37')),
        findsOneWidget,
      );
    },
  );
}
