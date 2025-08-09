import 'package:flutter/material.dart';

void main() => runApp(YanivScoreApp());

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
  int score = 0;
  Player(this.name);
}

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<Player> players = [];
  final TextEditingController nameController = TextEditingController();
  int endScore = 124;

  void _addPlayer(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      players.add(Player(name.trim()));
    });
    nameController.clear();
  }

  void _startGame() {
    if (players.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreTrackerScreen(players: players, endScore: endScore),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Game')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Player name'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _addPlayer(nameController.text),
                  child: Text('Add'),
                )
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text('End score: '),
                Expanded(
                  child: Slider(
                    value: endScore.toDouble(),
                    min: 50,
                    max: 200,
                    divisions: 150,
                    label: endScore.toString(),
                    onChanged: (val) => setState(() => endScore = val.toInt()),
                  ),
                ),
                Text(endScore.toString())
              ],
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(players[index].name),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _startGame,
              child: Text('Start Game'),
            )
          ],
        ),
      ),
    );
  }
}

class ScoreTrackerScreen extends StatefulWidget {
  final List<Player> players;
  final int endScore;

  ScoreTrackerScreen({required this.players, required this.endScore});

  @override
  _ScoreTrackerScreenState createState() => _ScoreTrackerScreenState();
}

class _ScoreTrackerScreenState extends State<ScoreTrackerScreen> {
  void _addPoints(Player player, int points) {
    setState(() {
      player.score += points;
      if (player.score == 62 || player.score == 124) {
        player.score = (player.score / 2).floor();
      }
    });
    _checkGameEnd();
  }

  void _checkGameEnd() {
    for (var p in widget.players) {
      if (p.score > widget.endScore) {
        _showWinnerDialog();
        break;
      }
    }
  }

  void _showWinnerDialog() {
    Player winner = widget.players.reduce((a, b) => a.score < b.score ? a : b);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Game Over'),
        content: Text('${winner.name} wins with the lowest score of ${winner.score}!'),
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
  }

  void _showAddPointsDialog(Player player) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add points for ${player.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Enter points'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final points = int.tryParse(controller.text) ?? 0;
              _addPoints(player, points);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yaniv Score Tracker')),
      body: ListView.builder(
        itemCount: widget.players.length,
        itemBuilder: (context, index) {
          var player = widget.players[index];
          return ListTile(
            title: Text(player.name),
            subtitle: Text('Score: ${player.score}'),
            trailing: IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showAddPointsDialog(player),
            ),
          );
        },
      ),
    );
  }
}
