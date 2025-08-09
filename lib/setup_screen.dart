import 'package:flutter/material.dart';
import 'package:yaniv/player.dart';

import 'game_history_screen.dart';
import 'game_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<TextEditingController> _playerControllers = [];
  final TextEditingController _endScoreController = TextEditingController(
    text: '124',
  );
  bool halvingRuleEnabled = true;
  bool winnerHalfPreviousScoreRule = true;

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
          winnerHalfPreviousScoreRule: winnerHalfPreviousScoreRule,
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
      appBar: AppBar(
        title: Text("Yaniv Score Setup"),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View Game History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GameHistoryScreen()),
              );
            },
          ),
        ],
      ),
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
                Expanded(
                  child: Text("Enable Halving Rule (if total hits 62 or 124)"),
                ),
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
            Row(
              children: [
                Expanded(child: Text("Winner halves previous total score")),
                Switch(
                  value: winnerHalfPreviousScoreRule,
                  onChanged: (val) {
                    setState(() {
                      winnerHalfPreviousScoreRule = val;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _startGame, child: Text("Start Game")),
          ],
        ),
      ),
    );
  }
}
