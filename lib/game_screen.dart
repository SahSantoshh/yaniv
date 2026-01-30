import 'package:flutter/material.dart';
import 'package:yaniv/player.dart';
import 'game_history.dart';

class RoundScore {
  final int value;
  final bool isPenalty;

  const RoundScore(this.value, {this.isPenalty = false});
}

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final int endScore;
  final bool halvingRuleEnabled;
  final bool winnerHalfPreviousScoreRule;
  final bool asafPenaltyRuleEnabled;
  final bool penaltyOnTieRuleEnabled;
  final int penaltyScore;

  const GameScreen({
    super.key,
    required this.players,
    required this.endScore,
    required this.halvingRuleEnabled,
    required this.winnerHalfPreviousScoreRule,
    required this.asafPenaltyRuleEnabled,
    required this.penaltyOnTieRuleEnabled,
    required this.penaltyScore,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _forceEnd = false;
  final List<List<RoundScore>> _rawScoreHistory = [];
  final List<List<String>> roundHistory = [];

  bool get gameOver => widget.players.any(
    (p) => p.totals.isNotEmpty && p.totals.last > widget.endScore,
  );

  Player get currentWinner => widget.players.reduce(
    (a, b) => (a.totals.isNotEmpty ? a.totals.last : 0) <
            (b.totals.isNotEmpty ? b.totals.last : 0)
        ? a
        : b,
  );

  Widget _scoreDisplay(String scoreStr) {
    bool isPenalty = false;
    if (scoreStr.startsWith("!!") && scoreStr.endsWith("!!")) {
      isPenalty = true;
      scoreStr = scoreStr.substring(2, scoreStr.length - 2);
    }

    TextStyle baseStyle = TextStyle(
      fontSize: 14,
      color: isPenalty ? Colors.redAccent : Colors.white70,
      fontWeight: isPenalty ? FontWeight.bold : FontWeight.normal,
    );

    if (scoreStr.contains('~~')) {
      final parts = scoreStr.split('~~');
      if (parts.length < 3) return Text(scoreStr, style: baseStyle);

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: parts[0]),
            TextSpan(
              text: parts[1],
              style: baseStyle.copyWith(
                decoration: TextDecoration.lineThrough,
                color: Colors.white38,
              ),
            ),
            TextSpan(
              text: parts[2],
              style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
          ],
        ),
      );
    } else {
      return Text(scoreStr, style: baseStyle, textAlign: TextAlign.center);
    }
  }

  Future<void> _addRound(List<RoundScore> inputScores) async {
    setState(() {
      _rawScoreHistory.add(inputScores);
      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    for (var player in widget.players) {
      player.scores.clear();
      player.totals.clear();
    }

    List<List<String>> newRoundHistory = [];

    for (var rawScores in _rawScoreHistory) {
      List<String> roundDisplay = [];
      List<int> actualScoresForThisRound = [];

      for (int i = 0; i < widget.players.length; i++) {
        Player player = widget.players[i];
        int prevTotal = player.totals.isEmpty ? 0 : player.totals.last;
        int rawScore = rawScores[i].value;
        int tentativeTotal = prevTotal + rawScore;

        String displayStr = "";
        int actualScore = rawScore;

        if (widget.halvingRuleEnabled && (tentativeTotal == 62 || tentativeTotal == 124)) {
          int halvedTotal = (tentativeTotal / 2).ceil();
          actualScore = halvedTotal - prevTotal;
          displayStr = "$prevTotal + $rawScore = ~~$tentativeTotal~~ $halvedTotal";
        } else {
          displayStr = "$prevTotal + $rawScore = $tentativeTotal";
        }

        if (rawScores[i].isPenalty) displayStr = "!!$displayStr!!";

        actualScoresForThisRound.add(actualScore);
        roundDisplay.add(displayStr);
      }

      if (widget.winnerHalfPreviousScoreRule) {
        List<int> winnerIndices = [];
        for (int i = 0; i < rawScores.length; i++) {
          if (rawScores[i].value == 0) winnerIndices.add(i);
        }

        for (int winnerIndex in winnerIndices) {
          Player winner = widget.players[winnerIndex];
          int prevTotal = winner.totals.isEmpty ? 0 : winner.totals.last;
          int newTotal = (prevTotal / 2).ceil();
          actualScoresForThisRound[winnerIndex] = newTotal - prevTotal;
          roundDisplay[winnerIndex] = "~~$prevTotal~~ $newTotal";
        }
      }

      for (int i = 0; i < widget.players.length; i++) {
        widget.players[i].scores.add(actualScoresForThisRound[i]);
        int prevTotal = widget.players[i].totals.isEmpty ? 0 : widget.players[i].totals.last;
        widget.players[i].totals.add(prevTotal + actualScoresForThisRound[i]);
      }
      newRoundHistory.add(roundDisplay);
    }

    roundHistory.clear();
    roundHistory.addAll(newRoundHistory);
    _checkGameEnd();
  }

  void _checkGameEnd() {
    if (gameOver) {
      final winner = currentWinner;
      final loser = widget.players.reduce((a, b) => 
        (a.totals.last) > (b.totals.last) ? a : b);

      GameHistory.addGameResult(
        winnerName: winner.name,
        winnerScore: winner.totals.last,
        loserName: loser.name,
        loserScore: loser.totals.last,
      );

      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🏆 Game Over'),
            content: Text(
              '${winner.name} wins with ${winner.totals.last} points!\n\n'
              'Hard luck to ${loser.name} (${loser.totals.last} pts).',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Back to Setup'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _showAddScoresDialog() {
    final controllers = List.generate(widget.players.length, (_) => TextEditingController());
    int? selectedCallerIndex;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(widget.asafPenaltyRuleEnabled ? "Round Totals" : "Enter Scores"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                if (widget.asafPenaltyRuleEnabled) ...[
                  const Text("Who called Yaniv?", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(widget.players.length, (i) => ChoiceChip(
                      label: Text(widget.players[i].name),
                      selected: selectedCallerIndex == i,
                      onSelected: (selected) => setStateDialog(() => selectedCallerIndex = selected ? i : null),
                    )),
                  ),
                  const Divider(height: 24),
                ],
                ...List.generate(widget.players.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: controllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.players[i].name,
                      hintText: "Enter hand score",
                    ),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (widget.asafPenaltyRuleEnabled && selectedCallerIndex == null) {
                  setStateDialog(() => errorMessage = "Select who called Yaniv");
                  return;
                }

                List<int> handTotals = controllers.map((c) => int.tryParse(c.text) ?? 0).toList();
                List<RoundScore> finalScores = [];

                if (widget.asafPenaltyRuleEnabled) {
                  int callerHand = handTotals[selectedCallerIndex!];
                  int minHand = handTotals.reduce((a, b) => a < b ? a : b);
                  bool isAsaf = handTotals.any((s) => s < callerHand) || 
                               (widget.penaltyOnTieRuleEnabled && handTotals.where((s) => s == callerHand).length > 1);

                  for (int i = 0; i < widget.players.length; i++) {
                    if (i == selectedCallerIndex) {
                      finalScores.add(isAsaf ? RoundScore(handTotals[i] + widget.penaltyScore, isPenalty: true) : const RoundScore(0));
                    } else {
                      finalScores.add((isAsaf && handTotals[i] == minHand) ? const RoundScore(0) : RoundScore(handTotals[i]));
                    }
                  }
                } else {
                  finalScores = handTotals.map((s) => RoundScore(s)).toList();
                }

                await _addRound(finalScores);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRound(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Round?"),
        content: Text("Delete all scores from round ${index + 1}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _rawScoreHistory.removeAt(index);
                _recalculateTotals();
              });
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: gameOver || _forceEnd,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !gameOver) {
          final confirm = await _showEndGameDialog(context);
          if (confirm == true && mounted) {
            setState(() => _forceEnd = true);
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Live Scoreboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => Navigator.maybePop(context),
            )
          ],
        ),
        body: Column(
          children: [
            _buildStandings(),
            const Divider(height: 1),
            Expanded(child: _buildHistoryList()),
          ],
        ),
        floatingActionButton: !gameOver ? FloatingActionButton.extended(
          onPressed: _showAddScoresDialog,
          label: const Text("ADD ROUND"),
          icon: const Icon(Icons.add),
          backgroundColor: theme.colorScheme.primary,
        ) : null,
      ),
    );
  }

  Widget _buildStandings() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.players.map((p) {
          int total = p.totals.isNotEmpty ? p.totals.last : 0;
          bool isLeading = p == currentWinner && p.totals.isNotEmpty;
          bool isDanger = total > widget.endScore * 0.8;

          return Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLeading ? Colors.amberAccent : (isDanger ? Colors.redAccent : Colors.white24),
                          width: 3,
                        ),
                        color: Colors.white10,
                      ),
                      child: Center(
                        child: Text(
                          p.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (isLeading)
                      const Positioned(top: -5, right: -5, child: Icon(Icons.emoji_events, color: Colors.amberAccent, size: 24)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  "$total",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDanger ? Colors.redAccent : (isLeading ? Colors.amberAccent : Colors.white),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (roundHistory.isEmpty) {
      return const Center(child: Text("No rounds played yet", style: TextStyle(color: Colors.white38)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: roundHistory.length,
      itemBuilder: (context, index) {
        final reversedIndex = roundHistory.length - 1 - index;
        final displayScores = roundHistory[reversedIndex];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white10,
              radius: 15,
              child: Text("${reversedIndex + 1}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.players.length, (i) {
                final isWinner = _rawScoreHistory[reversedIndex][i].value == 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: isWinner ? BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ) : null,
                  child: Text(
                    "${_rawScoreHistory[reversedIndex][i].value}",
                    style: TextStyle(
                      fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                      color: isWinner ? Colors.amberAccent : Colors.white70,
                    ),
                  ),
                );
              }),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: () => _deleteRound(reversedIndex),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: List.generate(widget.players.length, (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.players[i].name, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                        _scoreDisplay(displayScores[i]),
                      ],
                    ),
                  )),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

Future<bool?> _showEndGameDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('End Game?'),
      content: const Text('Are you sure you want to end the game? Progressive scores will be lost.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep Playing')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('End Game'),
        ),
      ],
    ),
  );
}
