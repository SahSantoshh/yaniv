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
