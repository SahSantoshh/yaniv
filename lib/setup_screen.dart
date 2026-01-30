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
        SnackBar(
          content: const Text("Add at least 2 players to start"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("YANIV"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(context, "PLAYERS", Icons.people_alt_rounded),
            const SizedBox(height: 12),
            ...List.generate(_playerControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _playerControllers[i],
                        focusNode: _playerFocusNodes[i],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Player ${i + 1}",
                          prefixIcon: Icon(Icons.person_outline_rounded, color: colorScheme.primary),
                        ),
                      ),
                    ),
                    if (_playerControllers.length > 2) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removePlayerField(i),
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addPlayerField,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add another player"),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, "GAME SETTINGS", Icons.settings_suggest_rounded),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _endScoreController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: "Score Limit",
                        prefixIcon: Icon(Icons.outlined_flag_rounded),
                        suffixText: "pts",
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFancySwitch(
                      context,
                      "Halving Rule",
                      "Score halves at 62 or 124",
                      Icons.auto_awesome_rounded,
                      halvingRuleEnabled,
                      (val) => setState(() => halvingRuleEnabled = val),
                    ),
                    const Divider(height: 32),
                    _buildFancySwitch(
                      context,
                      "Winner's Bonus",
                      "Winner halves previous total",
                      Icons.workspace_premium_rounded,
                      winnerHalfPreviousScoreRule,
                      (val) => setState(() => winnerHalfPreviousScoreRule = val),
                    ),
                    const Divider(height: 32),
                    _buildFancySwitch(
                      context,
                      "Asaf Penalties",
                      "Penalty for failed Yaniv calls",
                      Icons.gavel_rounded,
                      asafPenaltyRuleEnabled,
                      (val) => setState(() => asafPenaltyRuleEnabled = val),
                    ),
                    if (asafPenaltyRuleEnabled) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          children: [
                            _buildFancySwitch(
                              context,
                              "Tie Penalty",
                              "Penalty on exact tie",
                              Icons.equalizer_rounded,
                              penaltyOnTieRuleEnabled,
                              (val) => setState(() => penaltyOnTieRuleEnabled = val),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _penaltyScoreController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Penalty Points",
                                prefixIcon: Icon(Icons.warning_amber_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text("START MATCH"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFancySwitch(BuildContext context, String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
