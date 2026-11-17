import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaniv/game_share/game_snapshot.dart';
import 'package:yaniv/scoring_rules.dart';

class SavedTable {
  final List<String> names;
  final ScoringRules rules;

  const SavedTable({required this.names, required this.rules});
}

class SavedMatch {
  static const unfinishedKey = 'unfinished_match';
  static const tableKey = 'last_table';

  static Future<void> Function()? _last;

  /// Drops a save that a test left unfinished. The next save starts clean.
  @visibleForTesting
  static void resetQueue() {
    _last = null;
  }

  static Future<void> save(GameSnapshot snapshot) {
    return _sync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        unfinishedKey,
        jsonEncode(_snapshotToJson(snapshot)),
      );
    });
  }

  static Future<GameSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(unfinishedKey);
    if (raw == null) return null;
    return _snapshotFromJson(raw);
  }

  static Future<void> clear() {
    return _sync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(unfinishedKey);
    });
  }

  static Future<void> complete({
    required List<String> names,
    required ScoringRules rules,
  }) {
    return _sync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        tableKey,
        jsonEncode({'names': names, 'rules': _rulesToJson(rules)}),
      );
      await prefs.remove(unfinishedKey);
    });
  }

  static Future<SavedTable?> loadTable() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(tableKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final namesJson = json['names'];
      if (namesJson is! List) return null;
      final names = <String>[];
      for (final name in namesJson) {
        if (name is! String || name.trim().isEmpty) return null;
        names.add(name);
      }
      final rules = _rulesFromJson(json['rules']);
      if (rules == null) return null;
      return SavedTable(names: names, rules: rules);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _sync(Future<void> Function() action) async {
    final previous = _last;
    final gate = Completer<void>();
    _last = () => gate.future;
    if (previous != null) {
      try {
        await previous();
      } catch (_) {}
    }
    try {
      await action();
    } finally {
      if (!gate.isCompleted) gate.complete();
    }
  }
}

String resumeMatchLine(GameSnapshot snapshot) {
  final totals = matchTotals(snapshot);
  final scores = [
    for (var i = 0; i < snapshot.players.length; i++)
      '${snapshot.players[i].name} ${totals[i]}',
  ];
  final rounds = snapshot.roundHistory.length;
  final roundLabel = rounds == 1 ? '1 round' : '$rounds rounds';
  return '${scores.join(' · ')} · $roundLabel';
}

List<int> matchTotals(GameSnapshot snapshot) {
  final totals = List<int>.filled(snapshot.players.length, 0);
  final running = List.generate(snapshot.players.length, (_) => <int>[]);
  for (var r = 0; r < snapshot.roundHistory.length; r++) {
    final scored = scoreRound(
      rawScores: snapshot.roundHistory[r],
      prevTotals: [for (final history in running) List<int>.from(history)],
      joinedAtRound: [
        for (final player in snapshot.players) player.joinedAtRound,
      ],
      roundIndex: r,
      rules: snapshot.rules,
    );
    for (var i = 0; i < totals.length; i++) {
      if (r < snapshot.players[i].joinedAtRound) continue;
      running[i].add(scored.totals[i]);
      totals[i] = scored.totals[i];
    }
  }
  return totals;
}

Map<String, Object> _snapshotToJson(GameSnapshot snapshot) => {
  'players': [
    for (final player in snapshot.players)
      {'name': player.name, 'joinedAtRound': player.joinedAtRound},
  ],
  'rounds': [
    for (final round in snapshot.roundHistory)
      [for (final score in round) _scoreToJson(score)],
  ],
  'rules': _rulesToJson(snapshot.rules),
};

Map<String, Object> _scoreToJson(RoundScore score) => {
  'value': score.value,
  'penalty': score.penalty,
  'isPenalty': score.isPenalty,
  'isInactive': score.isInactive,
  'isCaller': score.isCaller,
  'skipWinnerHalf': score.skipWinnerHalf,
};

Map<String, Object> _rulesToJson(ScoringRules rules) => {
  'endScore': rules.endScore,
  'callScore': rules.callScore,
  'halvingRuleEnabled': rules.halvingRuleEnabled,
  'winnerHalfPreviousScoreRule': rules.winnerHalfPreviousScoreRule,
  'asafPenaltyRuleEnabled': rules.asafPenaltyRuleEnabled,
  'penaltyOnTieRuleEnabled': rules.penaltyOnTieRuleEnabled,
  'penaltyScore': rules.penaltyScore,
  'newPlayerJoinPenalty': rules.newPlayerJoinPenalty,
};

GameSnapshot? _snapshotFromJson(String raw) {
  try {
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    final playersJson = json['players'];
    final roundsJson = json['rounds'];
    if (playersJson is! List || playersJson.length < 2 || roundsJson is! List) {
      return null;
    }
    final players = <PlayerSnapshot>[];
    for (final player in playersJson) {
      if (player is! Map) return null;
      final name = player['name'];
      final joinedAtRound = player['joinedAtRound'];
      if (name is! String || name.trim().isEmpty || joinedAtRound is! int) {
        return null;
      }
      players.add(PlayerSnapshot(name: name, joinedAtRound: joinedAtRound));
    }
    final rounds = <List<RoundScore>>[];
    for (final round in roundsJson) {
      if (round is! List || round.length != players.length) return null;
      final scores = <RoundScore>[];
      for (final score in round) {
        final parsed = _scoreFromJson(score);
        if (parsed == null) return null;
        scores.add(parsed);
      }
      rounds.add(scores);
    }
    final rules = _rulesFromJson(json['rules']);
    if (rules == null) return null;
    return GameSnapshot(players: players, roundHistory: rounds, rules: rules);
  } catch (_) {
    return null;
  }
}

RoundScore? _scoreFromJson(Object? json) {
  if (json is! Map) return null;
  final value = json['value'];
  final penalty = json['penalty'];
  final isPenalty = json['isPenalty'];
  final isInactive = json['isInactive'];
  final isCaller = json['isCaller'];
  final skipWinnerHalf = json['skipWinnerHalf'];
  if (value is! int ||
      penalty is! int ||
      isPenalty is! bool ||
      isInactive is! bool ||
      isCaller is! bool ||
      skipWinnerHalf is! bool) {
    return null;
  }
  return RoundScore(
    value,
    penalty: penalty,
    isPenalty: isPenalty,
    isInactive: isInactive,
    isCaller: isCaller,
    skipWinnerHalf: skipWinnerHalf,
  );
}

ScoringRules? _rulesFromJson(Object? json) {
  if (json is! Map) return null;
  final endScore = json['endScore'];
  final callScore = json['callScore'];
  final halvingRuleEnabled = json['halvingRuleEnabled'];
  final winnerHalfPreviousScoreRule = json['winnerHalfPreviousScoreRule'];
  final asafPenaltyRuleEnabled = json['asafPenaltyRuleEnabled'];
  final penaltyOnTieRuleEnabled = json['penaltyOnTieRuleEnabled'];
  final penaltyScore = json['penaltyScore'];
  final newPlayerJoinPenalty = json['newPlayerJoinPenalty'];
  if (endScore is! int ||
      callScore is! int ||
      halvingRuleEnabled is! bool ||
      winnerHalfPreviousScoreRule is! bool ||
      asafPenaltyRuleEnabled is! bool ||
      penaltyOnTieRuleEnabled is! bool ||
      penaltyScore is! int ||
      newPlayerJoinPenalty is! int) {
    return null;
  }
  return ScoringRules(
    endScore: endScore,
    callScore: callScore,
    halvingRuleEnabled: halvingRuleEnabled,
    winnerHalfPreviousScoreRule: winnerHalfPreviousScoreRule,
    asafPenaltyRuleEnabled: asafPenaltyRuleEnabled,
    penaltyOnTieRuleEnabled: penaltyOnTieRuleEnabled,
    penaltyScore: penaltyScore,
    newPlayerJoinPenalty: newPlayerJoinPenalty,
  );
}
