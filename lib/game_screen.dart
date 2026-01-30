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

  Widget _scoreDisplay(String scoreStr) {
    bool isPenalty = false;
    if (scoreStr.startsWith("!!") && scoreStr.endsWith("!!")) {
      isPenalty = true;
      scoreStr = scoreStr.substring(2, scoreStr.length - 2);
    }

    TextStyle baseStyle = TextStyle(
      fontSize: 13,
      color: isPenalty ? Colors.red : Colors.black,
      fontWeight: isPenalty ? FontWeight.bold : FontWeight.normal,
    );

    if (scoreStr.contains('~~')) {
      final parts = scoreStr.split('~~');
      // Format usually: "Prefix ~~Strikethrough~~ Suffix"

      if (parts.length < 3) {
        return Text(scoreStr, style: baseStyle, textAlign: TextAlign.center);
      }

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: parts[0]), // Prefix
            TextSpan(
              text: parts[1], // Strikethrough part
              style: baseStyle.copyWith(
                decoration: TextDecoration.lineThrough,
                color: isPenalty ? Colors.red : Colors.grey,
              ),
            ),
            TextSpan(
              text: parts[2], // Suffix
              style: baseStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Text(scoreStr, style: baseStyle, textAlign: TextAlign.center);
    }
  }

  /// Returns true if round added successfully, false if invalid (multiple winners)
  Future<bool> _addRound(List<RoundScore> inputScores) async {
    // Validation removed to support multiple winners/Asaf rule
    if (inputScores.every((s) => s.value > 0) &&
        !widget.asafPenaltyRuleEnabled) {
      // Optional: Warning if NO winner in manual mode?
      // For now, we trust the user input or the Asaf dialog logic.
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
    int? selectedCallerIndex;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                widget.asafPenaltyRuleEnabled
                    ? "Enter Hand Totals"
                    : "Enter Round Scores",
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      if (widget.asafPenaltyRuleEnabled) ...[
                        Text(
                          "Who Called Yaniv?",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: List.generate(widget.players.length, (i) {
                            return ChoiceChip(
                              label: Text(widget.players[i].name),
                              selected: selectedCallerIndex == i,
                              onSelected: (bool selected) {
                                setStateDialog(() {
                                  selectedCallerIndex = selected ? i : null;
                                  errorMessage = null;
                                });
                              },
                            );
                          }),
                        ),
                        Divider(),
                        Text(
                          "Hand Scores",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      ...List.generate(widget.players.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextField(
                            controller: controllers[i],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: widget.asafPenaltyRuleEnabled
                                  ? "${widget.players[i].name}'s Hand"
                                  : widget.players[i].name,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        );
                      }),
                    ],
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
                    if (widget.asafPenaltyRuleEnabled) {
                      if (selectedCallerIndex == null) {
                        setStateDialog(() {
                          errorMessage = "Please select who called Yaniv.";
                        });
                        return;
                      }

                      List<int> handTotals = controllers
                          .map((c) => int.tryParse(c.text) ?? 0)
                          .toList();

                      int callerHand = handTotals[selectedCallerIndex!];
                      // Note: if list is empty reduce fails, but players > 0 assured by setup
                      int minHand = handTotals.reduce((a, b) => a < b ? a : b);

                      bool isAsaf = false;
                      // Check if anyone underecut (strictly lower)
                      if (handTotals.any((s) => s < callerHand)) {
                        isAsaf = true;
                      }
                      // Check tie
                      else if (handTotals.where((s) => s == callerHand).length >
                          1) {
                        if (widget.penaltyOnTieRuleEnabled) {
                          isAsaf = true;
                        } else {
                          isAsaf = false;
                        }
                      }

                      List<RoundScore> finalScores = [];
                      for (int i = 0; i < widget.players.length; i++) {
                        int hand = handTotals[i];

                        if (i == selectedCallerIndex) {
                          if (isAsaf) {
                            finalScores.add(
                              RoundScore(
                                hand + widget.penaltyScore,
                                isPenalty: true,
                              ),
                            );
                          } else {
                            finalScores.add(RoundScore(0));
                          }
                        } else {
                          if (isAsaf) {
                            // If Asaf, winner(s) with min score get 0
                            if (hand == minHand) {
                              finalScores.add(RoundScore(0));
                            } else {
                              finalScores.add(RoundScore(hand));
                            }
                          } else {
                            // Normal win for caller.
                            // Handle Shared Win case (Tie check)
                            if (!widget.penaltyOnTieRuleEnabled &&
                                hand == callerHand) {
                              finalScores.add(RoundScore(0));
                            } else {
                              finalScores.add(RoundScore(hand));
                            }
                          }
                        }
                      }

                      bool success = await _addRound(finalScores);
                      if (success && mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      // Manual Mode
                      final scores = controllers
                          .map((c) => RoundScore(int.tryParse(c.text) ?? 0))
                          .toList();
                      bool success = await _addRound(scores);
                      if (success && mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
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
        int rawScore = rawScores[i].value; // Access .value
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

        // Wrap penalty in markers
        if (rawScores[i].isPenalty) {
          displayStr = "!!$displayStr!!";
        }

        actualScoresForThisRound.add(actualScore);
        roundDisplay.add(displayStr);
      }

      // Check for winner halving rule
      // If enabled, the winner of this round (score 0) might get their PREVIOUS total halved.
      if (widget.winnerHalfPreviousScoreRule) {
        // Find ALL winners (score 0)
        List<int> winnerIndices = [];
        for (int i = 0; i < rawScores.length; i++) {
          if (rawScores[i].value == 0) winnerIndices.add(i); // Access .value
        }

        for (int winnerIndex in winnerIndices) {
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
            child: SizedBox(
              width: double.infinity,
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

                          // Find ALL winners (score 0) to highlight them
                          final Set<int> winnerIndices = {};
                          final rawScores = _rawScoreHistory[roundIndex];
                          for (int i = 0; i < rawScores.length; i++) {
                            if (rawScores[i].value == 0) {
                              winnerIndices.add(i);
                            }
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text("${roundIndex + 1}")),
                              ...scores.asMap().entries.map((e) {
                                bool isWinner = winnerIndices.contains(e.key);
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
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
