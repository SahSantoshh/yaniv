import 'package:flutter/material.dart';

void main() {
  runApp(YanivScoreApp());
}

class YanivScoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yaniv Score Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SetupScreen(),
    );
  }
}

class Player {
  String name;
  List<int> scores = [];
  Player(this.name);
  int get totalScore => scores.fold(0, (a, b) => a + b);
}

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<TextEditingController> _playerControllers = [];
  final TextEditingController _endScoreController =
  TextEditingController(text: '124');
  bool halvingRuleEnabled = true;

  void _addPlayerField() {
    setState(() {
      _playerControllers.add(TextEditingController());
    });
  }

  void _startGame() {
    final players = _playerControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => Player(c.text.trim()))
        .toList();

    if (players.isEmpty) return;

    final endScore = int.tryParse(_endScoreController.text) ?? 124;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          players: players,
          endScore: endScore,
          halvingRuleEnabled: halvingRuleEnabled,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _addPlayerField();
    _addPlayerField();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yaniv Score Setup")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Players", style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: _playerControllers.length,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: _playerControllers[i],
                      decoration: InputDecoration(
                        labelText: "Player ${i + 1} Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addPlayerField,
              child: Text("Add Player"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _endScoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "End Score",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text("Enable Halving Rule (62 & 124)")),
                Switch(
                  value: halvingRuleEnabled,
                  onChanged: (val) {
                    setState(() {
                      halvingRuleEnabled = val;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startGame,
              child: Text("Start Game"),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final int endScore;
  final bool halvingRuleEnabled;

  GameScreen({
    required this.players,
    required this.endScore,
    required this.halvingRuleEnabled,
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

  void _addRound(List<int> inputScores) {
    final minScore = inputScores.reduce((a, b) => a < b ? a : b);
    final winnerIndex = inputScores.indexOf(minScore);

    List<String> displayScores = [];

    for (int i = 0; i < widget.players.length; i++) {
      int score;
      if (i == winnerIndex) {
        score = 0;
      } else {
        score = inputScores[i];
      }

      if (widget.halvingRuleEnabled && (score == 62 || score == 124)) {
        int halved = (score / 2).floor();
        widget.players[i].scores.add(halved);
        displayScores.add('~~$score~~ $halved');
      } else {
        widget.players[i].scores.add(score);
        displayScores.add(score.toString());
      }
    }

    roundHistory.add(displayScores);

    setState(() {});

    _checkGameEnd();
  }

  bool get gameOver =>
      widget.players.any((p) => p.totalScore > widget.endScore);

  Player get winner =>
      widget.players.reduce((a, b) => a.totalScore < b.totalScore ? a : b);

  void _checkGameEnd() {
    if (gameOver) {
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Game Over'),
            content:
            Text('${winner.name} wins with the lowest score of ${winner.totalScore}!'),
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
            onPressed: () {
              final scores = controllers
                  .map((c) => int.tryParse(c.text) ?? 0)
                  .toList();
              _addRound(scores);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = widget.players.map((p) => p.totalScore).toList();

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
                ],
                rows: [
                  ...roundHistory.asMap().entries.map((entry) {
                    int roundIndex = entry.key;
                    List<String> scores = entry.value;
                    int winnerIndex = scores.indexOf('0');

                    return DataRow(
                      cells: [
                        DataCell(Text("${roundIndex + 1}")),
                        ...scores.asMap().entries.map((e) {
                          bool isWinner = e.key == winnerIndex;
                          return DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isWinner
                                    ? Colors.yellow.withOpacity(0.4)
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _scoreDisplay(e.value),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }),
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
