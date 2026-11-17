import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaniv/game_share/game_snapshot.dart';
import 'package:yaniv/saved_match.dart';
import 'package:yaniv/scoring_rules.dart';

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

  test(
    'saves an unfinished match and loads the same players and scores',
    () async {
      await SavedMatch.save(snapshot);

      expect(await SavedMatch.load(), snapshot);
      expect(resumeMatchLine(snapshot), 'Maya 0 · Ari 37 · 1 round');
    },
  );

  test('no saved match loads as nothing', () async {
    expect(await SavedMatch.load(), isNull);
  });

  test('clearing the unfinished match forgets it', () async {
    await SavedMatch.save(snapshot);

    await SavedMatch.clear();

    expect(await SavedMatch.load(), isNull);
  });

  test('a broken save is ignored', () async {
    SharedPreferences.setMockInitialValues({'unfinished_match': 'not json'});

    expect(await SavedMatch.load(), isNull);
  });

  test('a finished match keeps the names and drops the scores', () async {
    await SavedMatch.save(snapshot);

    await SavedMatch.complete(
      names: const ['Maya', 'Ari', 'Sam'],
      rules: snapshot.rules,
    );

    expect(await SavedMatch.load(), isNull);
    final table = await SavedMatch.loadTable();
    expect(table?.names, ['Maya', 'Ari', 'Sam']);
    expect(table?.rules, snapshot.rules);
  });

  test('zero rounds reads as a score of 0', () {
    const fresh = GameSnapshot(
      players: [
        PlayerSnapshot(name: 'Maya', joinedAtRound: 0),
        PlayerSnapshot(name: 'Ari', joinedAtRound: 0),
      ],
      roundHistory: [],
      rules: ScoringRules(),
    );

    expect(resumeMatchLine(fresh), 'Maya 0 · Ari 0 · 0 rounds');
  });
}
