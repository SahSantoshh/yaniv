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
  final List<FocusNode> _playerFocusNodes = [];
  final TextEditingController _endScoreController = TextEditingController(text: '124');
  bool halvingRuleEnabled = true;
  bool winnerHalfPreviousScoreRule = true;

  bool asafPenaltyRuleEnabled = false;
  bool penaltyOnTieRuleEnabled = true;
  final TextEditingController _penaltyScoreController = TextEditingController(text: '30');

  @override
  void dispose() {
    for (var node in _playerFocusNodes) {
      node.dispose();
    }
    _endScoreController.dispose();
    _penaltyScoreController.dispose();
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayerField() {
    final focusNode = FocusNode();
    setState(() {
      _playerControllers.add(TextEditingController());
      _playerFocusNodes.add(focusNode);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  void _removePlayerField(int index) {
    setState(() {
      _playerControllers[index].dispose();
      _playerFocusNodes[index].dispose();
      _playerControllers.removeAt(index);
      _playerFocusNodes.removeAt(index);
    });
  }

  void _startGame() {
    final players = _playerControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => Player(c.text.trim()))
        .toList();

    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least 2 players to start")),
      );
      return;
    }

    final endScore = int.tryParse(_endScoreController.text) ?? 124;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          players: players,
          endScore: endScore,
          halvingRuleEnabled: halvingRuleEnabled,
          winnerHalfPreviousScoreRule: winnerHalfPreviousScoreRule,
          asafPenaltyRuleEnabled: asafPenaltyRuleEnabled,
          penaltyOnTieRuleEnabled: penaltyOnTieRuleEnabled,
          penaltyScore: int.tryParse(_penaltyScoreController.text) ?? 30,
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
        title: const Text("Yaniv Setup", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle("Players"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...List.generate(_playerControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _playerControllers[i],
                                focusNode: _playerFocusNodes[i],
                                decoration: InputDecoration(
                                  hintText: "Player ${i + 1} Name",
                                  prefixIcon: const Icon(Icons.person),
                                ),
                              ),
                            ),
                            if (_playerControllers.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                onPressed: () => _removePlayerField(i),
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addPlayerField,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Player"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Game Rules"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _endScoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "End Score (Limit)",
                        prefixIcon: Icon(Icons.outlined_flag),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      "Halving Rule",
                      "Score halves if total hits 62 or 124",
                      halvingRuleEnabled,
                      (val) => setState(() => halvingRuleEnabled = val),
                    ),
                    _buildSwitchTile(
                      "Winner's Bonus",
                      "Winner halves their previous total score",
                      winnerHalfPreviousScoreRule,
                      (val) => setState(() => winnerHalfPreviousScoreRule = val),
                    ),
                    _buildSwitchTile(
                      "Asaf Penalty",
                      "Enable penalty for unsuccessful calls",
                      asafPenaltyRuleEnabled,
                      (val) => setState(() => asafPenaltyRuleEnabled = val),
                    ),
                    if (asafPenaltyRuleEnabled) ...[
                      const Divider(),
                      _buildSwitchTile(
                        "Tie Penalty",
                        "Penalize caller even on a tie",
                        penaltyOnTieRuleEnabled,
                        (val) => setState(() => penaltyOnTieRuleEnabled = val),
                      ),
                      TextField(
                        controller: _penaltyScoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Penalty Points",
                          prefixIcon: Icon(Icons.warning_amber),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text("START GAME", style: TextStyle(fontSize: 18, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
