class RoundScore {
  final int value;
  final bool isPenalty;
  final bool isInactive;
  final bool isCaller;

  /// Another player also scored 0 on a called round. They add 0, but they
  /// are not the round winner, so the winner-half rule does not apply.
  final bool skipWinnerHalf;

  /// Points added on top of the hand, such as an Asaf penalty. The hand is
  /// [value] minus [penalty].
  final int penalty;

  const RoundScore(
    this.value, {
    this.penalty = 0,
    this.isPenalty = false,
    this.isInactive = false,
    this.isCaller = false,
    this.skipWinnerHalf = false,
  });
}

class ScoringRules {
  final int endScore;
  final int callScore;
  final bool halvingRuleEnabled;
  final bool winnerHalfPreviousScoreRule;
  final bool asafPenaltyRuleEnabled;
  final bool penaltyOnTieRuleEnabled;
  final int penaltyScore;
  final int newPlayerJoinPenalty;

  const ScoringRules({
    this.endScore = 124,
    this.callScore = 5,
    this.halvingRuleEnabled = true,
    this.winnerHalfPreviousScoreRule = true,
    this.asafPenaltyRuleEnabled = true,
    this.penaltyOnTieRuleEnabled = true,
    this.penaltyScore = 30,
    this.newPlayerJoinPenalty = 10,
  });
}

/// Null when the hand may call. Otherwise the reason it cannot.
String? callScoreError(int callerHand, int callScore) {
  if (callerHand > callScore) {
    return 'Yaniv can only be called at $callScore or below';
  }
  return null;
}

/// Blank or non-numeric text uses the default of 5.
int parseCallScore(String text) => int.tryParse(text.trim()) ?? 5;

/// Null when the setup value can start a match.
String? callScoreSetupError(String text) {
  final parsed = int.tryParse(text.trim());
  if (parsed != null && parsed < 0) return 'Call score cannot be negative';
  return null;
}

/// Blank or non-numeric text uses the default of 124.
int parseTargetScore(String text) => int.tryParse(text.trim()) ?? 124;

/// Null when the target can start a match. Odd targets are rejected.
String? targetScoreError(int endScore) {
  if (endScore % 2 != 0) return 'Target Score must be an even number';
  return null;
}

/// A match ends only after a played total goes above [endScore].
bool matchIsOver({required List<List<int>> totals, required int endScore}) {
  return totals.any(
    (playerTotals) => playerTotals.isNotEmpty && playerTotals.last > endScore,
  );
}

List<int> halvingThresholds(int endScore) {
  final thresholds = <int>[];
  var current = endScore;
  while (current > 0 && current % 2 == 0) {
    thresholds.add(current);
    current = current ~/ 2;
  }
  return thresholds;
}

/// A round needs a chosen caller when Asaf is on, and when Asaf is off
/// but more than one player shares the lowest hand.
bool roundNeedsCaller({
  required List<int> hands,
  required bool asafPenaltyRuleEnabled,
}) {
  if (asafPenaltyRuleEnabled) return true;
  if (hands.isEmpty) return false;
  final minHand = hands.reduce((a, b) => a < b ? a : b);
  return hands.where((hand) => hand == minHand).length > 1;
}

/// Null when the round can be saved.
String? validateRound({
  required List<int> hands,
  required int? callerIndex,
  required ScoringRules rules,
}) {
  final needsCaller = roundNeedsCaller(
    hands: hands,
    asafPenaltyRuleEnabled: rules.asafPenaltyRuleEnabled,
  );
  if (needsCaller && callerIndex == null) return 'Please select the caller';

  if (!rules.asafPenaltyRuleEnabled) {
    final minHand = hands.reduce((a, b) => a < b ? a : b);
    final callError = callScoreError(minHand, rules.callScore);
    if (callError != null) return callError;
    if (needsCaller && hands[callerIndex!] != minHand) {
      return minHand == 0
          ? 'The caller must have 0'
          : 'The caller must have the lowest hand';
    }
    return null;
  }

  if (callerIndex != null) {
    return callScoreError(hands[callerIndex], rules.callScore);
  }
  return null;
}

/// Turn entered hand totals into the round scores that get stored.
///
/// When Asaf is off, the lowest hand is the caller. If several players share
/// that hand, [callerIndex] says which of them called. Only that caller is halved.
List<RoundScore> resolveHands({
  required List<int> hands,
  required int? callerIndex,
  required ScoringRules rules,
}) {
  if (!rules.asafPenaltyRuleEnabled) {
    return _resolveWithoutAsaf(hands, callerIndex, rules);
  }

  if (callerIndex == null) {
    final minHand = hands.reduce((a, b) => a < b ? a : b);
    return [for (final hand in hands) RoundScore(hand == minHand ? 0 : hand)];
  }

  final callerHand = hands[callerIndex];
  final othersAlsoZero =
      callerHand == 0 && hands.where((hand) => hand == 0).length > 1;

  // A called 0 is never a penalty, even when someone else also has 0.
  // With the winner-half rule, only the caller is halved.
  if (othersAlsoZero) {
    return _calledZeroTie(
      hands,
      callerIndex,
      rules.winnerHalfPreviousScoreRule,
    );
  }

  final minHand = hands.reduce((a, b) => a < b ? a : b);
  final isAsaf =
      hands.any((hand) => hand < callerHand) ||
      (rules.penaltyOnTieRuleEnabled &&
          hands.where((hand) => hand == callerHand).length > 1);

  return [
    for (var i = 0; i < hands.length; i++)
      if (i == callerIndex)
        isAsaf
            ? RoundScore(
                hands[i] + rules.penaltyScore,
                penalty: rules.penaltyScore,
                isPenalty: true,
                isCaller: true,
              )
            : const RoundScore(0, isCaller: true)
      else
        (isAsaf && hands[i] == minHand)
            ? const RoundScore(0)
            : RoundScore(hands[i]),
  ];
}

List<RoundScore> _resolveWithoutAsaf(
  List<int> hands,
  int? callerIndex,
  ScoringRules rules,
) {
  final minHand = hands.reduce((a, b) => a < b ? a : b);
  final lowestCount = hands.where((hand) => hand == minHand).length;
  if (lowestCount == 1) {
    return [
      for (final hand in hands)
        hand == minHand
            ? const RoundScore(0, isCaller: true)
            : RoundScore(hand),
    ];
  }

  if (callerIndex == null) {
    return [
      for (final hand in hands)
        hand == minHand
            ? const RoundScore(0, skipWinnerHalf: true)
            : RoundScore(hand),
    ];
  }

  return _calledLowestTie(
    hands,
    callerIndex,
    minHand,
    rules.winnerHalfPreviousScoreRule,
  );
}

List<RoundScore> _calledZeroTie(
  List<int> hands,
  int callerIndex,
  bool winnerHalf,
) {
  return _calledLowestTie(hands, callerIndex, 0, winnerHalf);
}

List<RoundScore> _calledLowestTie(
  List<int> hands,
  int callerIndex,
  int lowestHand,
  bool winnerHalf,
) {
  return [
    for (var i = 0; i < hands.length; i++)
      if (i == callerIndex)
        const RoundScore(0, isCaller: true)
      else if (hands[i] == lowestHand)
        winnerHalf
            ? const RoundScore(0, skipWinnerHalf: true)
            : const RoundScore(0)
      else
        RoundScore(hands[i]),
  ];
}

class ScoredRound {
  final List<int> deltas;
  final List<int> totals;
  final List<String> display;

  const ScoredRound({
    required this.deltas,
    required this.totals,
    required this.display,
  });
}

/// Apply one round on top of each player's running total.
///
/// [prevTotals] is empty for a player who has not played yet.
/// [joinedAtRound] is the first round index that player participates in.
ScoredRound scoreRound({
  required List<RoundScore> rawScores,
  required List<List<int>> prevTotals,
  required List<int> joinedAtRound,
  required int roundIndex,
  required ScoringRules rules,
}) {
  final thresholds = halvingThresholds(rules.endScore);
  var currentMaxTotal = 0;
  for (final totals in prevTotals) {
    if (totals.isNotEmpty && totals.last > currentMaxTotal) {
      currentMaxTotal = totals.last;
    }
  }

  final deltas = <int>[];
  final display = <String>[];

  for (var i = 0; i < rawScores.length; i++) {
    if (roundIndex < joinedAtRound[i] || rawScores[i].isInactive) {
      deltas.add(0);
      display.add('-');
      continue;
    }

    final isJoining = roundIndex > 0 && joinedAtRound[i] == roundIndex;
    final prevTotal = isJoining
        ? currentMaxTotal + rules.newPlayerJoinPenalty
        : (prevTotals[i].isEmpty ? 0 : prevTotals[i].last);

    final rawScore = rawScores[i].value;
    final hand = rawScore - rawScores[i].penalty;
    final penalty = rawScores[i].penalty;
    final tentativeTotal = prevTotal + rawScore;
    var actualScore = rawScore;
    int? replacedTotal;
    var finalTotal = tentativeTotal;

    if (rules.halvingRuleEnabled && thresholds.contains(tentativeTotal)) {
      final halvedTotal = (tentativeTotal / 2).ceil();
      actualScore = halvedTotal - prevTotal;
      replacedTotal = tentativeTotal;
      finalTotal = halvedTotal;
    }

    deltas.add(actualScore);
    display.add(
      _roundLine(
        previous: prevTotal,
        hand: hand,
        penalty: penalty,
        finalTotal: finalTotal,
        replacedTotal: replacedTotal,
        joinBase: isJoining ? currentMaxTotal : null,
        joinPenalty: isJoining ? rules.newPlayerJoinPenalty : null,
        isPenalty: rawScores[i].isPenalty,
      ),
    );
  }

  if (rules.winnerHalfPreviousScoreRule) {
    for (var i = 0; i < rawScores.length; i++) {
      if (roundIndex < joinedAtRound[i] ||
          rawScores[i].isInactive ||
          rawScores[i].value != 0 ||
          rawScores[i].skipWinnerHalf) {
        continue;
      }

      final isJoining = roundIndex > 0 && joinedAtRound[i] == roundIndex;
      final prevTotal = isJoining
          ? currentMaxTotal + rules.newPlayerJoinPenalty
          : (prevTotals[i].isEmpty ? 0 : prevTotals[i].last);
      final newTotal = (prevTotal / 2).ceil();
      deltas[i] = newTotal - prevTotal;
      display[i] = _roundLine(
        previous: prevTotal,
        hand: 0,
        penalty: 0,
        finalTotal: newTotal,
        replacedTotal: prevTotal,
        joinBase: isJoining ? currentMaxTotal : null,
        joinPenalty: isJoining ? rules.newPlayerJoinPenalty : null,
        isPenalty: false,
      );
    }
  }

  final totals = <int>[];
  for (var i = 0; i < rawScores.length; i++) {
    if (roundIndex < joinedAtRound[i]) {
      totals.add(prevTotals[i].isEmpty ? 0 : prevTotals[i].last);
      continue;
    }
    final isJoining = roundIndex > 0 && joinedAtRound[i] == roundIndex;
    final prevTotal = isJoining
        ? currentMaxTotal + rules.newPlayerJoinPenalty
        : (prevTotals[i].isEmpty ? 0 : prevTotals[i].last);
    totals.add(prevTotal + deltas[i]);
  }

  return ScoredRound(deltas: deltas, totals: totals, display: display);
}

String _roundLine({
  required int previous,
  required int hand,
  required int penalty,
  required int finalTotal,
  required int? replacedTotal,
  required int? joinBase,
  required int? joinPenalty,
  required bool isPenalty,
}) {
  final parts = <String>[];
  if (joinBase != null && joinPenalty != null) {
    parts.add('$joinBase');
    parts.add('$joinPenalty');
  } else {
    parts.add('$previous');
  }
  parts.add('$hand');
  if (penalty != 0) parts.add('$penalty');

  final sum = parts.join(' + ');
  final line = replacedTotal == null
      ? '$sum = $finalTotal'
      : '$sum = ~~$replacedTotal~~ $finalTotal';
  return isPenalty ? '!!$line!!' : line;
}
