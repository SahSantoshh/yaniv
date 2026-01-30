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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("YANIV"),
            centerTitle: true,
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(context, "PLAYERS", Icons.people_alt_rounded),
                const SizedBox(height: 16),
                ...List.generate(_playerControllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${i + 1}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _playerControllers[i],
                              focusNode: _playerFocusNodes[i],
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: "Enter name...",
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              ),
                            ),
                          ),
                          if (_playerControllers.length > 2)
                            IconButton(
                              onPressed: () => _removePlayerField(i),
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: Colors.redAccent),
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _addPlayerField,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          "ADD NEW PLAYER",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                _buildSectionHeader(context, "MATCH SETTINGS", Icons.tune_rounded),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TARGET SCORE",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _endScoreController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 42, letterSpacing: -2),
                              decoration: const InputDecoration(
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                suffixText: "PTS",
                                suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black26),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['100', '124', '150', '200'].map((val) {
                            final isSelected = _endScoreController.text == val;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(val),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) setState(() => _endScoreController.text = val);
                                },
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : colorScheme.primary,
                                ),
                                selectedColor: colorScheme.primary,
                                backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                showCheckmark: false,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 48),
                      Text(
                        "ACTIVE RULES",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFancySwitch(
                        context,
                        "Halving Logic",
                        "Total halves at exactly 62 or 124",
                        Icons.auto_awesome_rounded,
                        halvingRuleEnabled,
                        (val) => setState(() => halvingRuleEnabled = val),
                      ),
                      const SizedBox(height: 16),
                      _buildFancySwitch(
                        context,
                        "Winner Bonus",
                        "Round winner halves their previous score",
                        Icons.workspace_premium_rounded,
                        winnerHalfPreviousScoreRule,
                        (val) => setState(() => winnerHalfPreviousScoreRule = val),
                      ),
                      const SizedBox(height: 16),
                      _buildFancySwitch(
                        context,
                        "Asaf Penalties",
                        "Penalty points for failed Yaniv calls",
                        Icons.gavel_rounded,
                        asafPenaltyRuleEnabled,
                        (val) => setState(() => asafPenaltyRuleEnabled = val),
                      ),
                      if (asafPenaltyRuleEnabled) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFancySwitch(
                                context,
                                "Tie Penalty",
                                "Penalize even on an exact tie",
                                Icons.equalizer_rounded,
                                penaltyOnTieRuleEnabled,
                                (val) => setState(() => penaltyOnTieRuleEnabled = val),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _penaltyScoreController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: "Penalty Points",
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.warning_amber_rounded, size: 20, color: colorScheme.primary),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 22),
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 12,
            shadowColor: colorScheme.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("START NEW MATCH", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              SizedBox(width: 12),
              Icon(Icons.play_arrow_rounded, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: colorScheme.primary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFancySwitch(BuildContext context, String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value ? colorScheme.primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: value ? colorScheme.primary : Colors.black26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: value ? Colors.black87 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: value ? Colors.black54 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
