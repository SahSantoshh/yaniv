import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/scoring_rules.dart';

void main() {
  const rules = ScoringRules();

  group('call score', () {
    test('default allows a hand of 5', () {
      expect(callScoreError(5, rules.callScore), isNull);
    });

    test('rejects a hand above the call score', () {
      expect(callScoreError(6, 5), 'Yaniv can only be called at 5 or below');
    });

    test('custom call score allows that exact hand', () {
      expect(callScoreError(7, 7), isNull);
      expect(callScoreError(8, 7), isNotNull);
    });

    test('empty-equivalent hand of 0 may call', () {
      expect(callScoreError(0, 5), isNull);
    });

    test('blank call score uses 5', () {
      expect(parseCallScore(''), 5);
      expect(parseCallScore('   '), 5);
      expect(callScoreSetupError(''), isNull);
    });

    test('negative call score is rejected before the match starts', () {
      expect(callScoreSetupError('-1'), 'Call score cannot be negative');
      expect(callScoreSetupError('5'), isNull);
      expect(callScoreSetupError('0'), isNull);
    });
  });

  group('asaf and ties', () {
    test('successful call scores 0 and others keep their hands', () {
      final scores = resolveHands(
        hands: [3, 8, 10],
        callerIndex: 0,
        rules: rules,
      );

      expect(scores[0], const RoundScore(0, isCaller: true));
      expect(scores[1].value, 8);
      expect(scores[2].value, 10);
    });

    test('two players share the lowest hand and both are halved', () {
      final scores = resolveHands(
        hands: [5, 2, 2],
        callerIndex: 0,
        rules: rules,
      );

      expect(scores[0].value, 35);
      expect(scores[0].isPenalty, isTrue);
      expect(scores[1], const RoundScore(0));
      expect(scores[2], const RoundScore(0));

      final scored = scoreRound(
        rawScores: scores,
        prevTotals: [
          [10],
          [40],
          [20],
        ],
        joinedAtRound: [0, 0, 0],
        roundIndex: 1,
        rules: rules,
      );

      expect(scored.totals, [45, 20, 10]);
      expect(scored.display[0], '!!10 + 5 + 30 = 45!!');
    });

    test('custom penalty is added to the caller hand', () {
      final scores = resolveHands(
        hands: [5, 1],
        callerIndex: 0,
        rules: const ScoringRules(penaltyScore: 20),
      );

      expect(scores[0].value, 25);
      expect(scores[0].isPenalty, isTrue);
      expect(scores[1], const RoundScore(0));
    });

    test('lower hand is asaf: caller takes penalty, lowest scores 0', () {
      final scores = resolveHands(
        hands: [5, 2, 9],
        callerIndex: 0,
        rules: rules,
      );

      expect(scores[0].value, 35);
      expect(scores[0].isPenalty, isTrue);
      expect(scores[1], const RoundScore(0));
      expect(scores[2].value, 9);
    });

    test('tie penalty on: matching hand penalizes the caller', () {
      final scores = resolveHands(hands: [4, 4], callerIndex: 0, rules: rules);

      expect(scores[0].value, 34);
      expect(scores[0].isPenalty, isTrue);
      expect(scores[1], const RoundScore(0));
    });

    test('tie penalty off: caller scores 0 and the tie keeps its hand', () {
      final scores = resolveHands(
        hands: [4, 4],
        callerIndex: 0,
        rules: const ScoringRules(penaltyOnTieRuleEnabled: false),
      );

      expect(scores[0], const RoundScore(0, isCaller: true));
      expect(scores[1].value, 4);
    });

    test('asaf off: a tie for lowest halves only the caller', () {
      const off = ScoringRules(asafPenaltyRuleEnabled: false);

      expect(
        validateRound(hands: [4, 4, 9], callerIndex: null, rules: off),
        'Please select the caller',
      );
      expect(
        validateRound(hands: [4, 4, 9], callerIndex: 2, rules: off),
        'The caller must have the lowest hand',
      );

      final scores = resolveHands(hands: [4, 4, 9], callerIndex: 0, rules: off);
      expect(scores[0], const RoundScore(0, isCaller: true));
      expect(scores[1], const RoundScore(0, skipWinnerHalf: true));
      expect(scores[2].value, 9);

      final scored = scoreRound(
        rawScores: scores,
        prevTotals: [
          [40],
          [20],
          [10],
        ],
        joinedAtRound: [0, 0, 0],
        roundIndex: 1,
        rules: off,
      );

      expect(scored.totals, [20, 20, 19]);
    });

    test('asaf off: the single lowest hand is the caller', () {
      final scores = resolveHands(
        hands: [2, 8, 9],
        callerIndex: null,
        rules: const ScoringRules(asafPenaltyRuleEnabled: false),
      );

      expect(scores[0], const RoundScore(0, isCaller: true));
      expect(scores[1].value, 8);
      expect(scores[2].value, 9);

      final scored = scoreRound(
        rawScores: scores,
        prevTotals: [
          [40],
          [20],
          [10],
        ],
        joinedAtRound: [0, 0, 0],
        roundIndex: 1,
        rules: const ScoringRules(asafPenaltyRuleEnabled: false),
      );

      expect(scored.totals, [20, 28, 19]);
    });

    test('asaf off: two zeros cannot be saved until a caller is chosen', () {
      const off = ScoringRules(asafPenaltyRuleEnabled: false);

      expect(
        validateRound(hands: [0, 0, 6], callerIndex: null, rules: off),
        'Please select the caller',
      );
      expect(
        validateRound(hands: [0, 0, 6], callerIndex: 2, rules: off),
        'The caller must have 0',
      );
      expect(
        validateRound(hands: [0, 0, 6], callerIndex: 1, rules: off),
        isNull,
      );

      final scores = resolveHands(hands: [0, 0, 6], callerIndex: 1, rules: off);
      final scored = scoreRound(
        rawScores: scores,
        prevTotals: [
          [40],
          [20],
          [10],
        ],
        joinedAtRound: [0, 0, 0],
        roundIndex: 1,
        rules: off,
      );

      expect(scored.totals, [40, 10, 16]);
    });

    test('asaf off: a lowest hand above the call score is rejected', () {
      expect(
        validateRound(
          hands: [7, 9],
          callerIndex: null,
          rules: const ScoringRules(asafPenaltyRuleEnabled: false),
        ),
        'Yaniv can only be called at 5 or below',
      );
    });
  });

  group('caller and another player both have 0', () {
    test('half rule on: no penalty, only the caller is halved', () {
      final scores = resolveHands(
        hands: [0, 0, 6],
        callerIndex: 0,
        rules: rules,
      );

      expect(scores[0], const RoundScore(0, isCaller: true));
      expect(scores[0].isPenalty, isFalse);
      expect(scores[1], const RoundScore(0, skipWinnerHalf: true));
      expect(scores[2].value, 6);

      final scored = scoreRound(
        rawScores: scores,
        prevTotals: [
          [40],
          [20],
          [10],
        ],
        joinedAtRound: [0, 0, 0],
        roundIndex: 1,
        rules: rules,
      );

      expect(scored.totals, [20, 20, 16]);
      expect(scored.display[0], '40 + 0 = ~~40~~ 20');
      expect(scored.display[1], '20 + 0 = 20');
      expect(scored.display[2], '10 + 6 = 16');
    });

    test('half rule off: a called 0 adds 0, even if tie penalty is on', () {
      final scores = resolveHands(
        hands: [0, 0],
        callerIndex: 0,
        rules: const ScoringRules(winnerHalfPreviousScoreRule: false),
      );

      expect(scores[0], const RoundScore(0, isCaller: true));
      expect(scores[0].isPenalty, isFalse);
      expect(scores[1], const RoundScore(0));

      final scored = scoreRound(
        rawScores: scores,
        prevTotals: [
          [40],
          [20],
        ],
        joinedAtRound: [0, 0],
        roundIndex: 1,
        rules: const ScoringRules(winnerHalfPreviousScoreRule: false),
      );

      expect(scored.totals, [40, 20]);
    });

    test('half rule off and tie penalty off: both add 0', () {
      final scores = resolveHands(
        hands: [0, 0],
        callerIndex: 0,
        rules: const ScoringRules(
          winnerHalfPreviousScoreRule: false,
          penaltyOnTieRuleEnabled: false,
        ),
      );

      expect(scores[0], const RoundScore(0, isCaller: true));
      expect(scores[1].value, 0);
      expect(scores[1].skipWinnerHalf, isFalse);
    });

    test('a lone 0 still halves the caller', () {
      final scores = resolveHands(hands: [0, 4], callerIndex: 0, rules: rules);
      final scored = scoreRound(
        rawScores: scores,
        prevTotals: [
          [40],
          [20],
        ],
        joinedAtRound: [0, 0],
        roundIndex: 1,
        rules: rules,
      );

      expect(scored.totals, [20, 24]);
    });
  });

  group('other rules', () {
    test('halving cuts a total that lands on a threshold', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(4), const RoundScore(1)],
        prevTotals: [
          [120],
          [10],
        ],
        joinedAtRound: [0, 0],
        roundIndex: 1,
        rules: const ScoringRules(winnerHalfPreviousScoreRule: false),
      );

      expect(scored.totals[0], 62);
      expect(scored.display[0], '120 + 4 = ~~124~~ 62');
    });

    test('halving off keeps the full total', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(4)],
        prevTotals: [
          [120],
        ],
        joinedAtRound: [0],
        roundIndex: 1,
        rules: const ScoringRules(
          halvingRuleEnabled: false,
          winnerHalfPreviousScoreRule: false,
        ),
      );

      expect(scored.totals, [124]);
    });

    test('odd target has no halving threshold', () {
      expect(halvingThresholds(125), isEmpty);
      expect(halvingThresholds(124), [124, 62]);
    });

    test('landing on 62 halves to 31', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(1)],
        prevTotals: [
          [61],
        ],
        joinedAtRound: [0],
        roundIndex: 1,
        rules: const ScoringRules(winnerHalfPreviousScoreRule: false),
      );

      expect(scored.totals, [31]);
    });

    test('a total that misses every threshold is kept', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(10)],
        prevTotals: [
          [100],
        ],
        joinedAtRound: [0],
        roundIndex: 1,
        rules: const ScoringRules(winnerHalfPreviousScoreRule: false),
      );

      expect(scored.totals, [110]);
    });

    test('target 100 halves at 100 and 50', () {
      expect(halvingThresholds(100), [100, 50]);

      final scored = scoreRound(
        rawScores: [const RoundScore(10)],
        prevTotals: [
          [90],
        ],
        joinedAtRound: [0],
        roundIndex: 1,
        rules: const ScoringRules(
          endScore: 100,
          winnerHalfPreviousScoreRule: false,
        ),
      );

      expect(scored.totals, [50]);
    });

    test('odd previous total rounds the winner half up', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(0)],
        prevTotals: [
          [41],
        ],
        joinedAtRound: [0],
        roundIndex: 1,
        rules: rules,
      );

      expect(scored.totals, [21]);
    });

    test('a winner already on 0 stays on 0', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(0)],
        prevTotals: [
          [0],
        ],
        joinedAtRound: [0],
        roundIndex: 1,
        rules: rules,
      );

      expect(scored.totals, [0]);
    });

    test('joiner starts from the highest total plus the join penalty', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(2), const RoundScore(0, isInactive: true)],
        prevTotals: [
          [40],
          [],
        ],
        joinedAtRound: [0, 1],
        roundIndex: 0,
        rules: rules,
      );

      // Round 0 is not a join. Inactive player stays out.
      expect(scored.display[1], '-');

      final joined = scoreRound(
        rawScores: [const RoundScore(3), const RoundScore(5)],
        prevTotals: [
          [40],
          [],
        ],
        joinedAtRound: [0, 1],
        roundIndex: 1,
        rules: const ScoringRules(winnerHalfPreviousScoreRule: false),
      );

      expect(joined.totals[1], 55);
      expect(joined.display[1], '40 + 10 + 5 = 55');
    });

    test('a joiner who wins halves the starting total', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(3), const RoundScore(0)],
        prevTotals: [
          [40],
          [],
        ],
        joinedAtRound: [0, 1],
        roundIndex: 1,
        rules: rules,
      );

      expect(scored.totals, [43, 25]);
      expect(scored.display[1], '40 + 10 + 0 = ~~50~~ 25');
    });

    test('a join penalty of 0 starts from the highest total', () {
      final scored = scoreRound(
        rawScores: [const RoundScore(3), const RoundScore(5)],
        prevTotals: [
          [40],
          [],
        ],
        joinedAtRound: [0, 1],
        roundIndex: 1,
        rules: const ScoringRules(
          winnerHalfPreviousScoreRule: false,
          newPlayerJoinPenalty: 0,
        ),
      );

      expect(scored.totals, [43, 45]);
      expect(scored.display[1], '40 + 0 + 5 = 45');
    });
  });

  group('target score', () {
    test('a total above 124 ends the match', () {
      expect(
        matchIsOver(
          totals: [
            [125],
            [40],
          ],
          endScore: 124,
        ),
        isTrue,
      );
    });

    test('a total equal to 124 continues', () {
      expect(
        matchIsOver(
          totals: [
            [124],
          ],
          endScore: 124,
        ),
        isFalse,
      );
    });

    test('a custom target of 100 ends at 101', () {
      expect(
        matchIsOver(
          totals: [
            [101],
          ],
          endScore: 100,
        ),
        isTrue,
      );
    });

    test('no rounds yet continues', () {
      expect(matchIsOver(totals: [[], []], endScore: 124), isFalse);
    });

    test('an odd target is rejected and a blank target is 124', () {
      expect(parseTargetScore(''), 124);
      expect(targetScoreError(124), isNull);
      expect(targetScoreError(125), 'Target Score must be an even number');
    });
  });
}
