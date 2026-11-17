import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaniv/game_screen.dart';
import 'package:yaniv/game_share/game_snapshot.dart';
import 'package:yaniv/main.dart';
import 'package:yaniv/player.dart';
import 'package:yaniv/saved_match.dart';
import 'package:yaniv/scoreboard_widget.dart';
import 'package:yaniv/scoring_rules.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  const snapshot = GameSnapshot(
    players: [
      PlayerSnapshot(name: 'Maya', joinedAtRound: 0),
      PlayerSnapshot(name: 'Ari', joinedAtRound: 0),
    ],
    roundHistory: [
      [RoundScore(0, isCaller: true), RoundScore(37)],
    ],
    rules: ScoringRules(endScore: 200, callScore: 7),
  );

  setUp(() {
    SavedMatch.resetQueue();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('reopening offers the unfinished match', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await SavedMatch.save(snapshot);

    await tester.pumpWidget(const YanivScoreApp());
    await settle(tester);

    expect(find.text('MATCH IN PROGRESS'), findsOneWidget);
    expect(find.text('1 round'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('37'), findsOneWidget);
    expect(find.text('Continue this match?'), findsNothing);

    await tester.tap(find.text('CONTINUE'));
    await settle(tester);

    expect(find.text('SCOREBOARD'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Scoreboard), matching: find.text('37')),
      findsOneWidget,
    );
  });

  testWidgets('starting a new match can replace the paused one', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await SavedMatch.save(snapshot);

    await tester.pumpWidget(const YanivScoreApp());
    await settle(tester);

    final names = find.byType(TextField);
    await tester.enterText(names.at(0), 'Maya');
    await tester.enterText(names.at(1), 'Ari');
    await tester.tap(find.text('START NEW MATCH'));
    await settle(tester);

    expect(find.text('This replaces the paused match.'), findsOneWidget);
    await tester.tap(find.text('NO'));
    await settle(tester);

    expect(find.text('MATCH IN PROGRESS'), findsOneWidget);
    expect((await SavedMatch.load())?.roundHistory.length, 1);

    await tester.tap(find.text('START NEW MATCH'));
    await settle(tester);
    await tester.tap(find.text('YES'));
    await settle(tester);

    expect(find.text('SCOREBOARD'), findsOneWidget);
    expect((await SavedMatch.load())?.roundHistory, isEmpty);
  });

  testWidgets('a finished match fills names the next time the app opens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await SavedMatch.complete(
      names: const ['Maya', 'Ari'],
      rules: snapshot.rules,
    );

    await tester.pumpWidget(const YanivScoreApp());
    await settle(tester);

    expect(find.text('MATCH IN PROGRESS'), findsNothing);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Ari'), findsOneWidget);
    expect(find.text('200'), findsWidgets);
  });

  testWidgets('a live scoreboard is saved', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          players: [Player('Maya'), Player('Ari')],
          endScore: 200,
          callScore: 7,
          halvingRuleEnabled: true,
          winnerHalfPreviousScoreRule: true,
          asafPenaltyRuleEnabled: true,
          penaltyOnTieRuleEnabled: true,
          penaltyScore: 30,
          newPlayerJoinPenalty: 10,
        ),
      ),
    );
    await settle(tester);

    final saved = await SavedMatch.load();
    expect(saved?.players.map((player) => player.name).toList(), [
      'Maya',
      'Ari',
    ]);
    expect(saved?.roundHistory, isEmpty);
    expect(saved?.rules.endScore, 200);
  });

  testWidgets('a finished scoreboard forgets the match and remembers names', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          players: [Player('Maya'), Player('Ari')],
          endScore: 10,
          callScore: 5,
          halvingRuleEnabled: true,
          winnerHalfPreviousScoreRule: true,
          asafPenaltyRuleEnabled: true,
          penaltyOnTieRuleEnabled: true,
          penaltyScore: 30,
          newPlayerJoinPenalty: 10,
          initialRoundHistory: snapshot.roundHistory,
        ),
      ),
    );
    await settle(tester);

    expect(await SavedMatch.load(), isNull);
    final table = await SavedMatch.loadTable();
    expect(table?.names, ['Maya', 'Ari']);
    expect(find.textContaining('MATCH OVER'), findsOneWidget);

    await tester.tap(find.text('BACK TO HOME'));
    await settle(tester);
    expect(find.textContaining('MATCH OVER'), findsNothing);
    expect(await SavedMatch.load(), isNull);
  });

  testWidgets('pause leaves the match saved', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      players: [Player('Maya'), Player('Ari')],
                      endScore: 200,
                      callScore: 7,
                      halvingRuleEnabled: true,
                      winnerHalfPreviousScoreRule: true,
                      asafPenaltyRuleEnabled: true,
                      penaltyOnTieRuleEnabled: true,
                      penaltyScore: 30,
                      newPlayerJoinPenalty: 10,
                      initialRoundHistory: snapshot.roundHistory,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await settle(tester);
    await tester.tap(find.text('Pause'));
    await settle(tester);

    expect(find.text('open'), findsOneWidget);
    expect(
      (await SavedMatch.load())?.players.map((player) => player.name).toList(),
      ['Maya', 'Ari'],
    );
  });

  testWidgets('ending the match throws the save away', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      players: [Player('Maya'), Player('Ari')],
                      endScore: 200,
                      callScore: 7,
                      halvingRuleEnabled: true,
                      winnerHalfPreviousScoreRule: true,
                      asafPenaltyRuleEnabled: true,
                      penaltyOnTieRuleEnabled: true,
                      penaltyScore: 30,
                      newPlayerJoinPenalty: 10,
                      initialRoundHistory: snapshot.roundHistory,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await settle(tester);
    await tester.tap(find.text('End Match'));
    await settle(tester);
    expect(find.text('PAUSE OR QUIT?'), findsOneWidget);
    await tester.tap(find.text('QUIT'));
    await settle(tester);

    expect(find.text('open'), findsOneWidget);
    expect(await SavedMatch.load(), isNull);
  });

  testWidgets('pause from the back dialog keeps the match', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      players: [Player('Maya'), Player('Ari')],
                      endScore: 200,
                      callScore: 7,
                      halvingRuleEnabled: true,
                      winnerHalfPreviousScoreRule: true,
                      asafPenaltyRuleEnabled: true,
                      penaltyOnTieRuleEnabled: true,
                      penaltyScore: 30,
                      newPlayerJoinPenalty: 10,
                      initialRoundHistory: snapshot.roundHistory,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await settle(tester);
    await tester.tap(find.text('End Match'));
    await settle(tester);
    await tester.tap(find.text('PAUSE'));
    await settle(tester);

    expect(find.text('open'), findsOneWidget);
    expect(
      (await SavedMatch.load())?.players.map((player) => player.name).toList(),
      ['Maya', 'Ari'],
    );
  });
}
