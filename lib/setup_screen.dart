import 'package:flutter/material.dart';
import 'package:yaniv/player.dart';

import 'game_history_screen.dart';
import 'game_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  SetupScreenState createState() => SetupScreenState();
}

class SetupScreenState extends State<SetupScreen> {
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(elevation: 2,
        title: Text("Yaniv Score Setup"),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View Game History',
            onPressed: () {
              Focus.of(context).unfocus();
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("Players", style: TextStyle(fontSize: 18)),
              SizedBox(height: 16,),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _playerControllers.length,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
              ElevatedButton(

                style: ElevatedButton.styleFrom(
                  side: BorderSide(color: Colors.deepPurple),
                  elevation: 0
                ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                child: ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(50),
                      fixedSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _startGame, child: Text("Start Game")),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
