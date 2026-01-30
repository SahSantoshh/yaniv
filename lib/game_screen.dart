import 'package:flutter/material.dart';
import 'package:yaniv/player.dart';

import 'game_history.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final int endScore;
  final bool halvingRuleEnabled;
  final bool winnerHalfPreviousScoreRule;

  const GameScreen({
    super.key,
    required this.players,
    required this.endScore,
    required this.halvingRuleEnabled,
    required this.winnerHalfPreviousScoreRule,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _forceEnd = false;
  final List<List<int>> _rawScoreHistory = [];
  final List<List<String>> roundHistory = [];

  Widget _scoreDisplay(String scoreStr) {
    if (scoreStr.contains('~~')) {
      final parts = scoreStr.split('~~');
      // Format usually: "Prefix ~~Strikethrough~~ Suffix"
      // e.g. "30 + 32 = ~~62~~ 31" -> ["30 + 32 = ", "62", " 31"]
      // e.g. "~~40~~ 20" -> ["", "40", " 20"]

      if (parts.length < 3) return Text(scoreStr);

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 13),
          children: [
            TextSpan(text: parts[0]), // Prefix
            TextSpan(
              text: parts[1], // Strikethrough part
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              ),
            ),
            TextSpan(
              text: parts[2], // Suffix
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Text(
        scoreStr,
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        textAlign: TextAlign.center,
      );
    }
  }

  /// Returns true if round added successfully, false if invalid (multiple winners)
  Future<bool> _addRound(List<int> inputScores) async {
    final winnersCount = inputScores.where((s) => s == 0).length;

    if (winnersCount != 1) {
      // Show error dialog, multiple winners found
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Invalid Scores'),
          content: Text(
            'There must be exactly one winner with score 0. Please adjust scores.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return false; // Indicate failure
    }

    _rawScoreHistory.add(inputScores);
    _recalculateTotals();

    return true; // Indicate success
  }

  bool get gameOver => widget.players.any(
    (p) => p.totals.isNotEmpty && p.totals.last > widget.endScore,
  );

  Player get winner => widget.players.reduce(
    (a, b) =>
        (a.totals.isNotEmpty ? a.totals.last : 0) <
            (b.totals.isNotEmpty ? b.totals.last : 0)
        ? a
        : b,
  );

  void _checkGameEnd() {
    if (gameOver) {
      final loser = widget.players.reduce(
        (a, b) =>
            (a.totals.isNotEmpty ? a.totals.last : 0) >
                (b.totals.isNotEmpty ? b.totals.last : 0)
            ? a
            : b,
      );

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
          builder: (context) => AlertDialog(
            title: Text('Game Over'),
            content: Text(
              '${winner.name} wins with the lowest score of ${winner.totals.last}!\n'
              'Loser: ${loser.name} with the highest score of ${loser.totals.last}.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Restart'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _showAddScoresDialog() {
    final controllers = List.generate(
      widget.players.length,
      (_) => TextEditingController(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Enter Round Scores"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.players.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: controllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.players[i].name,
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final scores = controllers
                  .map((c) => int.tryParse(c.text) ?? 0)
                  .toList();
              bool success = await _addRound(scores);
              if (success && mounted) {
                Navigator.pop(context);
              }
              // else keep dialog open to fix input
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteRound(int roundIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Round'),
        content: Text(
          'Are you sure you want to delete Round ${roundIndex + 1}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _rawScoreHistory.removeAt(roundIndex);
                _recalculateTotals();
              });
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _recalculateTotals() {
    // Clear all players' scores and totals
    for (var player in widget.players) {
      player.scores.clear();
      player.totals.clear();
    }

    List<List<String>> newRoundHistory = [];

    // Rebuild everything from raw history
    for (var rawScores in _rawScoreHistory) {
      List<String> roundDisplay = [];

      // We need to calculate what happens for EACH player based on their CURRENT total
      // BEFORE applying this round's score.

      List<int> actualScoresForThisRound =
          []; // The scores that actually get added to totals (after halving rules)

      // First pass: Calculate basic addition and standard halving (62/124)
      for (int i = 0; i < widget.players.length; i++) {
        Player player = widget.players[i];
        int prevTotal = player.totals.isEmpty ? 0 : player.totals.last;
        int rawScore = rawScores[i];
        int tentativeTotal = prevTotal + rawScore;

        String displayStr = "";
        int actualScore = rawScore;

        // Check standard halving rule
        if (widget.halvingRuleEnabled &&
            (tentativeTotal == 62 || tentativeTotal == 124)) {
          int halvedTotal = (tentativeTotal / 2).ceil();
          actualScore =
              halvedTotal -
              prevTotal; // The effective score added to reach halved total
          // Display: "30 + 32 = ~~62~~ 31"
          displayStr =
              "$prevTotal + $rawScore = ~~$tentativeTotal~~ $halvedTotal";
        } else {
          // Normal case
          // Display: "10 + 5 = 15"
          displayStr = "$prevTotal + $rawScore = $tentativeTotal";
        }

        actualScoresForThisRound.add(actualScore);
        roundDisplay.add(displayStr);
      }

      // Check for winner halving rule
      // If enabled, the winner of this round (score 0) might get their PREVIOUS total halved.
      if (widget.winnerHalfPreviousScoreRule) {
        // Find winner index in the RAW input for this round (whoever put 0)
        // logic: exactly one winner enforced by _addRound
        int winnerIndex = rawScores.indexOf(0);

        if (winnerIndex != -1) {
          Player winner = widget.players[winnerIndex];

          // Winner's total BEFORE this round
          int prevTotal = winner.totals.isEmpty ? 0 : winner.totals.last;

          // If they have a previous score to halve
          // Note: if prevTotal is 0, halving does nothing, but rule implies halving previous total score.

          // Logic: Winner score is 0. So tentative total is prevTotal.
          // New total becomes prevTotal / 2.

          int newTotal = (prevTotal / 2).ceil();

          // The "actual score" added this round is effectively negative to reduce the total
          // actualScore = newTotal - prevTotal.

          actualScoresForThisRound[winnerIndex] = newTotal - prevTotal;

          // Update display: "~~40~~ 20" (since +0 is implied)
          roundDisplay[winnerIndex] = "~~$prevTotal~~ $newTotal";
        }
      }

      // Apply the final calculated scores to player totals
      for (int i = 0; i < widget.players.length; i++) {
        widget.players[i].scores.add(actualScoresForThisRound[i]);
        int prevTotal = widget.players[i].totals.isEmpty
            ? 0
            : widget.players[i].totals.last;
        widget.players[i].totals.add(prevTotal + actualScoresForThisRound[i]);
      }

      newRoundHistory.add(roundDisplay);
    }

    roundHistory
      ..clear()
      ..addAll(newRoundHistory);

    setState(() {});
    _checkGameEnd();
  }

  @override
  Widget build(BuildContext context) {
    final totals = widget.players
        .map((p) => p.totals.isNotEmpty ? p.totals.last : 0)
        .toList();

    return PopScope(
      canPop: gameOver || _forceEnd, // Allow direct pop if game over or forced
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !gameOver) {
          final confirm = await _showEndGameDialog(context);
          if (confirm == true && mounted) {
            setState(() {
              _forceEnd = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          }
        }
      },

      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Yaniv Game"),
          actions: [
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: Text('End Game'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text("Round")),
                      ...widget.players.map(
                        (p) => DataColumn(label: Text(p.name)),
                      ),
                      DataColumn(
                        label: Text('Actions'),
                      ), // New column for delete button
                    ],
                    rows: [
                      ...roundHistory.asMap().entries.map((entry) {
                        int roundIndex = entry.key;
                        List<String> scores = entry.value;

                        // Let's refine winner search: The winner is the one who played 0.
                        // We don't have the raw scores here easily unless we look at _rawScoreHistory[roundIndex]
                        // Accessing raw history is cleaner.
                        int rawWinnerIndex = _rawScoreHistory[roundIndex]
                            .indexOf(0);

                        return DataRow(
                          cells: [
                            DataCell(Text("${roundIndex + 1}")),
                            ...scores.asMap().entries.map((e) {
                              bool isWinner = e.key == rawWinnerIndex;
                              return DataCell(
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isWinner
                                        ? Colors.yellow.withAlpha(102)
                                        : null,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _scoreDisplay(e.value),
                                ),
                              );
                            }),
                            DataCell(
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete Round',
                                onPressed: () => _deleteRound(roundIndex),
                              ),
                            ),
                          ],
                        );
                      }),
                      DataRow(
                        cells: [
                          DataCell(
                            Text(
                              "Total",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...totals.map(
                            (t) => DataCell(
                              Text(
                                "$t",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(''),
                          ), // Empty cell for Actions column on total row
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                if (!gameOver)
                  ElevatedButton(
                    onPressed: _showAddScoresDialog,
                    child: Text("Add Round Scores"),
                  ),
                if (gameOver)
                  Text(
                    "Game Over! Winner: ${winner.name}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showEndGameDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('End Game?'),
      content: Text('Are you sure you want to end the game?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('End Game'),
        ),
      ],
    ),
  );
}
