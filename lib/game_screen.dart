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

  Widget _scoreDisplay(String scoreStr, Color baseTextColor) {
    bool isPenalty = false;
    if (scoreStr.startsWith("!!") && scoreStr.endsWith("!!")) {
      isPenalty = true;
      scoreStr = scoreStr.substring(2, scoreStr.length - 2);
    }

    TextStyle baseStyle = TextStyle(
      fontSize: 14,
      color: isPenalty ? Colors.redAccent : baseTextColor,
      fontWeight: isPenalty ? FontWeight.bold : FontWeight.w500,
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
                color: baseTextColor.withValues(alpha: 0.4),
                fontWeight: FontWeight.normal,
              ),
            ),
            TextSpan(
              text: parts[2],
              style: baseStyle.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF673AB7)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Center(child: Text('🏆 MATCH OVER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
                ),
                const SizedBox(height: 24),
                Text(winner.name.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF311B92))),
                const Text('WINS THE MATCH!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 16),
                Text('Score: ${winner.totals.last} pts', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('BACK TO HOME'),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }
  }

  void _showAddScoresDialog() {
    final controllers = List.generate(widget.players.length, (_) => TextEditingController());
    final focusNodes = List.generate(widget.players.length, (_) => FocusNode());
    int? selectedCallerIndex;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(widget.asafPenaltyRuleEnabled ? "ROUND RESULTS" : "ENTER SCORES", 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (widget.asafPenaltyRuleEnabled) ...[
                  const Text("WHO CALLED YANIV?", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(widget.players.length, (i) => ChoiceChip(
                      label: Text(widget.players[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      selected: selectedCallerIndex == i,
                      onSelected: (selected) => setStateDialog(() => selectedCallerIndex = selected ? i : null),
                      selectedColor: const Color(0xFF673AB7).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF673AB7),
                    )),
                  ),
                  const Divider(height: 32),
                ],
                const Text("HAND TOTALS", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 12),
                ...List.generate(widget.players.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: controllers[i],
                    focusNode: focusNodes[i],
                    keyboardType: TextInputType.number,
                    textInputAction: i == widget.players.length - 1 ? TextInputAction.done : TextInputAction.next,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: widget.players[i].name,
                      hintText: "0",
                      prefixIcon: const Icon(Icons.calculate_outlined),
                    ),
                    onSubmitted: (_) {
                      if (i < widget.players.length - 1) {
                        focusNodes[i + 1].requestFocus();
                      }
                    },
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                for (var node in focusNodes) { node.dispose(); }
                Navigator.pop(context);
              },
              child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black38)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (widget.asafPenaltyRuleEnabled && selectedCallerIndex == null) {
                  setStateDialog(() => errorMessage = "Please select the caller");
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
                if (mounted) {
                  for (var node in focusNodes) { node.dispose(); }
                  Navigator.pop(context);
                }
              },
              child: const Text("SAVE ROUND"),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("DELETE ROUND?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Discard all scores from round ${index + 1}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("KEEP IT")),
          TextButton(
            onPressed: () {
              setState(() {
                _rawScoreHistory.removeAt(index);
                _recalculateTotals();
              });
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text("SCOREBOARD"),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildStandings(),
            Expanded(child: _buildHistoryList()),
          ],
        ),
        floatingActionButton: !gameOver ? FloatingActionButton.extended(
          onPressed: _showAddScoresDialog,
          backgroundColor: const Color(0xFF673AB7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text("ADD ROUND", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ) : null,
      ),
    );
  }

  Widget _buildStandings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, const Color(0xFF311B92)],
        ),
      ),
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
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLeading ? Colors.amber : (isDanger ? Colors.redAccent : Colors.white24),
                          width: 2.5,
                        ),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          p.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                    if (isLeading)
                      const Positioned(top: -12, child: Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(p.name.toUpperCase(), 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white70, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(
                  "$total",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDanger ? Colors.redAccent : (isLeading ? Colors.amber : Colors.white),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (roundHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 64, color: colorScheme.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text("NO ROUNDS PLAYED", style: TextStyle(
              fontWeight: FontWeight.w800, 
              letterSpacing: 1, 
              color: colorScheme.primary.withValues(alpha: 0.2),
              fontSize: 12,
            )),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 8),
      itemCount: roundHistory.length,
      itemBuilder: (context, index) {
        final reversedIndex = roundHistory.length - 1 - index;
        final displayScores = roundHistory[reversedIndex];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Text("${reversedIndex + 1}", style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w900)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.players.length, (i) {
                final isWinner = _rawScoreHistory[reversedIndex][i].value == 0;
                return Column(
                  children: [
                    Text(
                      "${_rawScoreHistory[reversedIndex][i].value}",
                      style: TextStyle(
                        fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 18,
                        color: isWinner ? const Color(0xFFFF8F00) : Colors.black87,
                      ),
                    ),
                    if (isWinner) 
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFFF8F00), shape: BoxShape.circle)),
                  ],
                );
              }),
            ),
            trailing: const Icon(Icons.expand_more_rounded, color: Colors.black26),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const Divider(height: 24),
                    ...List.generate(widget.players.length, (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.players[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                          _scoreDisplay(displayScores[i], Colors.black87),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _deleteRound(reversedIndex),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text("DELETE ROUND", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withValues(alpha: 0.7)),
                    ),
                  ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('END MATCH?', style: TextStyle(fontWeight: FontWeight.w900)),
      content: const Text('All current scores will be lost. Ready to quit?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('STAY')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('QUIT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
