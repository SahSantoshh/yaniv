import 'package:flutter/material.dart';
import 'package:yaniv/player.dart';

import 'game_history.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final int endScore;
  final bool halvingRuleEnabled;
  final bool winnerHalfPreviousScoreRule;

  const GameScreen({
    required this.players,
    required this.endScore,
    required this.halvingRuleEnabled,
    required this.winnerHalfPreviousScoreRule,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<List<String>> roundHistory = [];

  Widget _scoreDisplay(String scoreStr) {
    if (scoreStr.contains('~~')) {
      final parts = scoreStr.split(' ');
      final original = parts[0].replaceAll('~~', '');
      final halved = parts[1];
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: original,
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: ' $halved',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(scoreStr,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16));
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
          content: Text('There must be exactly one winner with score 0. Please adjust scores.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
        ),
      );
      return false; // Indicate failure
    }

    final winnerIndex = inputScores.indexOf(0);

    List<String> displayScores = [];

    // First calculate tentative totals without halving for display
    List<int> tentativeTotals = [];

    for (int i = 0; i < widget.players.length; i++) {
      int prevTotal =
      widget.players[i].totals.isEmpty ? 0 : widget.players[i].totals.last;
      tentativeTotals.add(prevTotal + inputScores[i]);
    }

    // Now apply halving rule based on new total if enabled
    for (int i = 0; i < widget.players.length; i++) {
      int prevTotal =
      widget.players[i].totals.isEmpty ? 0 : widget.players[i].totals.last;
      int rawRoundScore = inputScores[i];
      int newTotal = prevTotal + rawRoundScore;

      if (widget.halvingRuleEnabled && (newTotal == 62 || newTotal == 124)) {
        int halvedScore = ((newTotal) / 2).ceil() - prevTotal;
        widget.players[i].scores.add(halvedScore);
        displayScores.add('~~$rawRoundScore~~ $halvedScore');
      } else {
        widget.players[i].scores.add(rawRoundScore);
        displayScores.add(rawRoundScore.toString());
      }
    }

    // Update totals normally first (with scores possibly adjusted for halving)
    for (var player in widget.players) {
      int prevTotal = player.totals.isEmpty ? 0 : player.totals.last;
      int lastRoundScore = player.scores.last;
      player.totals.add(prevTotal + lastRoundScore);
    }

    // Apply winner halves previous total score rule if enabled
    if (widget.winnerHalfPreviousScoreRule) {
      var winner = widget.players[winnerIndex];
      int prevTotal = winner.totals.length > 1
          ? winner.totals[winner.totals.length - 2]
          : 0;
      int newTotal = (prevTotal / 2).ceil();
      winner.totals[winner.totals.length - 1] = newTotal;

      // Update roundHistory display for winner score (strike-through 0 to new score)
      displayScores[winnerIndex] = '~~0~~ $newTotal';
    }

    roundHistory.add(displayScores);

    setState(() {});
    _checkGameEnd();

    return true; // Indicate success
  }

  bool get gameOver =>
      widget.players.any((p) => p.totals.isNotEmpty && p.totals.last > widget.endScore);

  Player get winner => widget.players.reduce((a, b) =>
  (a.totals.isNotEmpty ? a.totals.last : 0) <
      (b.totals.isNotEmpty ? b.totals.last : 0)
      ? a
      : b);

  void _checkGameEnd() {
    if (gameOver) {
      // Save winner info in shared preferences
      GameHistory.addGameWinner(winner.name, winner.totals.last);

      Future.delayed(Duration.zero, () {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Game Over'),
            content: Text(
                '${winner.name} wins with the lowest score of ${winner.totals.last}!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Restart'),
              )
            ],
          ),
        );
      });
    }
  }

  void _showAddScoresDialog() {
    final controllers =
    List.generate(widget.players.length, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Enter Round Scores"),
        content: SingleChildScrollView(
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
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final scores =
              controllers.map((c) => int.tryParse(c.text) ?? 0).toList();
              bool success = await _addRound(scores);
              if (success) {
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
        content: Text('Are you sure you want to delete Round ${roundIndex + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                roundHistory.removeAt(roundIndex);
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

    // Temporary roundHistory to rebuild display strings correctly
    List<List<String>> newRoundHistory = [];

    for (int roundIndex = 0; roundIndex < roundHistory.length; roundIndex++) {
      // Parse original input scores for this round from roundHistory strings
      List<int> rawRoundScores = [];
      for (var scoreStr in roundHistory[roundIndex]) {
        if (scoreStr.contains('~~')) {
          // Format: "~~original~~ halved"
          var parts = scoreStr.split(' ');
          rawRoundScores.add(int.parse(parts[0].replaceAll('~~', '')));
        } else {
          rawRoundScores.add(int.parse(scoreStr));
        }
      }

      List<String> displayScores = [];
      List<int> adjustedRoundScores = [];

      // Calculate tentative totals and adjusted round scores applying halving rule
      for (int i = 0; i < widget.players.length; i++) {
        int prevTotal = widget.players[i].totals.isEmpty ? 0 : widget.players[i].totals.last;
        int rawScore = rawRoundScores[i];
        int newTotal = prevTotal + rawScore;

        if (widget.halvingRuleEnabled && (newTotal == 62 || newTotal == 124)) {
          // Calculate halved score for this round
          int halvedScore = ((newTotal) / 2).ceil() - prevTotal;
          adjustedRoundScores.add(halvedScore);
          displayScores.add('~~$rawScore~~ $halvedScore');
        } else {
          adjustedRoundScores.add(rawScore);
          displayScores.add(rawScore.toString());
        }
      }

      // Add adjusted round scores to players and update totals
      for (int i = 0; i < widget.players.length; i++) {
        var player = widget.players[i];
        int prevTotal = player.totals.isEmpty ? 0 : player.totals.last;
        player.scores.add(adjustedRoundScores[i]);
        player.totals.add(prevTotal + adjustedRoundScores[i]);
      }

      // Apply winner halves previous total rule if enabled
      if (widget.winnerHalfPreviousScoreRule) {
        int winnerIndex = adjustedRoundScores.indexOf(0);
        if (winnerIndex >= 0) {
          var winner = widget.players[winnerIndex];
          int prevTotal = winner.totals.length > 1 ? winner.totals[winner.totals.length - 2] : 0;
          int newTotal = (prevTotal / 2).ceil();

          winner.totals[winner.totals.length - 1] = newTotal;

          // Update display score for winner in this round with strikethrough and new total
          displayScores[winnerIndex] = '~~0~~ $newTotal';
        }
      }

      newRoundHistory.add(displayScores);
    }

    // Replace old roundHistory with recalculated display strings
    roundHistory
      ..clear()
      ..addAll(newRoundHistory);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totals = widget.players
        .map((p) => p.totals.isNotEmpty ? p.totals.last : 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Yaniv Game"),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Round")),
                  ...widget.players.map((p) => DataColumn(label: Text(p.name))),
                  DataColumn(label: Text('Actions')),  // New column for delete button
                ],
                rows: [
                  ...roundHistory.asMap().entries.map((entry) {
                    int roundIndex = entry.key;
                    List<String> scores = entry.value;

                    int winnerIndex = scores.indexWhere((s) =>
                    s == '0' ||
                        (s.contains('~~0~~') && widget.winnerHalfPreviousScoreRule));

                    return DataRow(
                      cells: [
                        DataCell(Text("${roundIndex + 1}")),
                        ...scores.asMap().entries.map((e) {
                          bool isWinner = e.key == winnerIndex;
                          return DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isWinner ? Colors.yellow.withAlpha(102) : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _scoreDisplay(e.value),
                            ),
                          );
                        }).toList(),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Round',
                            onPressed: () => _deleteRound(roundIndex),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  DataRow(
                    cells: [
                      DataCell(Text(
                        "Total",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                      ...totals.map((t) => DataCell(Text(
                        "$t",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ))),
                      DataCell(Text('')), // Empty cell for Actions column on total row
                    ],
                  )
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
              )
          ],
        ),
      ),
    );
  }
}
