import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yaniv/ad_helper.dart';
import 'package:yaniv/player.dart';
import 'package:yaniv/round_history_widget.dart';
import 'package:yaniv/scoreboard_widget.dart';

import 'game_history.dart';
import 'rule_examples_screen.dart';
import 'scoring_rules.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final int endScore;
  final int callScore;
  final bool halvingRuleEnabled;
  final bool winnerHalfPreviousScoreRule;
  final bool asafPenaltyRuleEnabled;
  final bool penaltyOnTieRuleEnabled;
  final int penaltyScore;
  final int newPlayerJoinPenalty;

  const GameScreen({
    super.key,
    required this.players,
    required this.endScore,
    required this.callScore,
    required this.halvingRuleEnabled,
    required this.winnerHalfPreviousScoreRule,
    required this.asafPenaltyRuleEnabled,
    required this.penaltyOnTieRuleEnabled,
    required this.penaltyScore,
    required this.newPlayerJoinPenalty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _forceEnd = false;
  late List<Player> _players;
  final List<List<RoundScore>> _rawScoreHistory = [];
  final List<List<String>> roundHistory = [];

  BannerAd? _bannerAd;
  final Map<int, BannerAd> _inlineAds = {};
  InterstitialAd? _interstitialAd;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.players);

    _loadMainBanner();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (!AdHelper.supportsAds) return;

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialGameplayId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: ${err.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void _loadMainBanner() {
    if (!AdHelper.supportsAds) return;

    BannerAd(
      adUnitId: AdHelper.bannerAnchoredId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  void _loadInlineAd(int index) {
    if (_inlineAds.containsKey(index)) return;
    if (!AdHelper.supportsAds) return;

    BannerAd(
      adUnitId: AdHelper.bannerInlineId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _inlineAds[index] = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load an inline banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _bannerAd?.dispose();
    for (var ad in _inlineAds.values) {
      ad.dispose();
    }
    _interstitialAd?.dispose();
    super.dispose();
  }

  bool get gameOver => matchIsOver(
    totals: [for (final player in _players) player.totals],
    endScore: widget.endScore,
  );

  Player get currentWinner {
    // Only players who have actually played rounds can be "Leading"
    final participants = _players.where((p) => p.totals.isNotEmpty).toList();
    if (participants.isEmpty) return _players.first;

    return participants.reduce((a, b) => a.totals.last < b.totals.last ? a : b);
  }

  Future<void> _addRound(List<RoundScore> inputScores) async {
    setState(() {
      _rawScoreHistory.add(inputScores);
      _recalculateTotals();

      // Load an inline ad every 2 rounds
      if (_rawScoreHistory.length % 2 == 0) {
        _loadInlineAd(_rawScoreHistory.length ~/ 2);
      }
    });

    // Show interstitial ad after 10 seconds of adding each round
    // Reset existing timer to prevent multiple ads triggering too close together
    _adTimer?.cancel();
    _adTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !gameOver) {
        _showInterstitialAd();
      }
    });
  }

  ScoringRules get _rules => ScoringRules(
    endScore: widget.endScore,
    callScore: widget.callScore,
    halvingRuleEnabled: widget.halvingRuleEnabled,
    winnerHalfPreviousScoreRule: widget.winnerHalfPreviousScoreRule,
    asafPenaltyRuleEnabled: widget.asafPenaltyRuleEnabled,
    penaltyOnTieRuleEnabled: widget.penaltyOnTieRuleEnabled,
    penaltyScore: widget.penaltyScore,
    newPlayerJoinPenalty: widget.newPlayerJoinPenalty,
  );

  void _recalculateTotals() {
    for (var player in _players) {
      player.scores.clear();
      player.totals.clear();
    }

    List<List<String>> newRoundHistory = [];

    for (int r = 0; r < _rawScoreHistory.length; r++) {
      final scored = scoreRound(
        rawScores: _rawScoreHistory[r],
        prevTotals: [
          for (final player in _players) List<int>.from(player.totals),
        ],
        joinedAtRound: [for (final player in _players) player.joinedAtRound],
        roundIndex: r,
        rules: _rules,
      );

      for (int i = 0; i < _players.length; i++) {
        if (r < _players[i].joinedAtRound) continue;
        _players[i].scores.add(scored.deltas[i]);
        _players[i].totals.add(scored.totals[i]);
      }
      newRoundHistory.add(scored.display);
    }

    roundHistory.clear();
    roundHistory.addAll(newRoundHistory);
    _checkGameEnd();
  }

  void _checkGameEnd() {
    if (gameOver) {
      _showInterstitialAd();
      final winner = currentWinner;
      final loser = _players.reduce(
        (a, b) => (a.totals.last) > (b.totals.last) ? a : b,
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
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: const Center(
              child: Text(
                '🏆 MATCH OVER',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
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
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 64,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  winner.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF311B92),
                  ),
                ),
                const Text(
                  'WINS THE MATCH!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Score: ${winner.totals.last} pts',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(dialogContext);
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
    final activePlayers = _players
        .where((p) => p.joinedAtRound <= _rawScoreHistory.length)
        .toList();

    final controllers = List.generate(
      activePlayers.length,
      (_) => TextEditingController(),
    );
    final focusNodes = List.generate(activePlayers.length, (_) => FocusNode());
    int? selectedCallerIndex;
    String? errorMessage;
    var forceAskCaller = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setStateDialog) {
          final colorScheme = Theme.of(context).colorScheme;
          final enteredHands = <int>[
            for (final controller in controllers)
              if (controller.text.trim().isNotEmpty &&
                  int.tryParse(controller.text.trim()) != null)
                int.parse(controller.text.trim()),
          ];
          final showCaller =
              widget.asafPenaltyRuleEnabled ||
              forceAskCaller ||
              roundNeedsCaller(
                hands: enteredHands,
                asafPenaltyRuleEnabled: false,
              );

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_chart_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "ROUND RESULTS",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (showCaller) ...[
                            Text(
                              "WHO CALLED YANIV?",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: activePlayers.length,
                                itemBuilder: (context, i) {
                                  final isSelected = selectedCallerIndex == i;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: InkWell(
                                      onTap: () => setStateDialog(
                                        () => selectedCallerIndex = i,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 70,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.primary.withValues(
                                                  alpha: 0.05,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? colorScheme.primary
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              activePlayers[i].name[0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: isSelected
                                                    ? Colors.white
                                                    : colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              activePlayers[i].name,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            "SCORES",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: colorScheme.primary.withValues(alpha: 0.5),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(activePlayers.length, (i) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      activePlayers[i].name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      activePlayers[i].name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller: controllers[i],
                                      focusNode: focusNodes[i],
                                      keyboardType: TextInputType.number,
                                      textInputAction:
                                          i < activePlayers.length - 1
                                          ? TextInputAction.next
                                          : TextInputAction.done,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "0",
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                        fillColor: colorScheme.primary
                                            .withValues(alpha: 0.03),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      onChanged: (_) => setStateDialog(() {}),
                                      onSubmitted: (_) {
                                        if (i < activePlayers.length - 1) {
                                          focusNodes[i + 1].requestFocus();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              for (var node in focusNodes) {
                                node.dispose();
                              }
                              Navigator.pop(statefulContext);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              List<int> activeHandTotals = controllers
                                  .map((c) => int.tryParse(c.text) ?? 0)
                                  .toList();
                              final roundError = validateRound(
                                hands: activeHandTotals,
                                callerIndex: selectedCallerIndex,
                                rules: _rules,
                              );
                              if (roundError != null) {
                                setStateDialog(() {
                                  errorMessage = roundError;
                                  forceAskCaller = roundNeedsCaller(
                                    hands: activeHandTotals,
                                    asafPenaltyRuleEnabled:
                                        widget.asafPenaltyRuleEnabled,
                                  );
                                });
                                return;
                              }
                              List<RoundScore> finalScores = [];
                              int activeIdx = 0;
                              final activeFinalScores = resolveHands(
                                hands: activeHandTotals,
                                callerIndex:
                                    roundNeedsCaller(
                                      hands: activeHandTotals,
                                      asafPenaltyRuleEnabled:
                                          widget.asafPenaltyRuleEnabled,
                                    )
                                    ? selectedCallerIndex
                                    : null,
                                rules: _rules,
                              );

                              for (var p in _players) {
                                if (p.joinedAtRound <=
                                    _rawScoreHistory.length) {
                                  finalScores.add(
                                    activeFinalScores[activeIdx++],
                                  );
                                } else {
                                  finalScores.add(
                                    const RoundScore(0, isInactive: true),
                                  );
                                }
                              }
                              await _addRound(finalScores);
                              if (statefulContext.mounted) {
                                for (var node in focusNodes) {
                                  node.dispose();
                                }
                                Navigator.pop(statefulContext);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "SAVE ROUND",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteRound(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "DELETE ROUND?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text("Discard all scores from round ${index + 1}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("KEEP IT"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _rawScoreHistory.removeAt(index);
                _recalculateTotals();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text(
              "DELETE",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManagePlayersDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "MANAGE PLAYERS",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final player = _players.removeAt(oldIndex);
                        _players.insert(newIndex, player);

                        // Reorder scores in history
                        for (var round in _rawScoreHistory) {
                          final score = round.removeAt(oldIndex);
                          round.insert(newIndex, score);
                        }
                        _recalculateTotals();
                      });
                      setStateDialog(() {});
                    },
                    children: List.generate(_players.length, (i) {
                      final player = _players[i];
                      return ListTile(
                        key: ValueKey(player),
                        leading: const Icon(Icons.drag_handle_rounded),
                        title: TextField(
                          controller: TextEditingController(text: player.name),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Player Name",
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() => player.name = val.trim());
                            }
                          },
                        ),
                        subtitle: Text(
                          player.joinedAtRound > 0
                              ? "Joined at Round ${player.joinedAtRound + 1}"
                              : "Starting Player",
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Text(
                          "${player.totals.isNotEmpty ? player.totals.last : 0} pts",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF673AB7),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "New players start with the current highest score + joining penalty.",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () =>
                      _showAddPlayerDialog(statefulContext, setStateDialog),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF673AB7).withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          size: 20,
                          color: Color(0xFF673AB7),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "ADD NEW PLAYER",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF673AB7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "DONE",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, StateSetter setStateDialog) {
    final controller = TextEditingController();
    final currentMax = _players.isEmpty
        ? 0
        : _players
              .map((pl) => pl.totals.isEmpty ? 0 : pl.totals.last)
              .reduce((a, b) => a > b ? a : b);
    final projectedScore = currentMax + widget.newPlayerJoinPenalty;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ADD NEW PLAYER",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              "Starting Score: $projectedScore pts ($currentMax + ${widget.newPlayerJoinPenalty} penalty)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter name",
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              _executeAddPlayer(val.trim(), setStateDialog);
              Navigator.pop(c);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _executeAddPlayer(controller.text.trim(), setStateDialog);
                Navigator.pop(c);
              }
            },
            child: const Text("ADD PLAYER"),
          ),
        ],
      ),
    );
  }

  void _executeAddPlayer(String name, StateSetter setStateDialog) {
    setState(() {
      final newPlayer = Player(name, joinedAtRound: _rawScoreHistory.length);
      _players.add(newPlayer);
      // Pad existing history with inactive scores
      for (var round in _rawScoreHistory) {
        round.add(const RoundScore(0, isInactive: true));
      }
      _recalculateTotals();
    });
    setStateDialog(() {});
  }

  void _showRulesInfo() {
    final thresholds = halvingThresholds(widget.endScore);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text(
            "ACTIVE MATCH RULES",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleInfoRow(
              context,
              Icons.outlined_flag_rounded,
              "Target Score",
              "${widget.endScore} PTS",
            ),
            const SizedBox(height: 16),
            _buildRuleInfoRow(
              context,
              Icons.front_hand_rounded,
              "Call Score",
              "${widget.callScore} PTS",
            ),
            const Divider(height: 32),
            _buildRuleInfoRow(
              context,
              Icons.auto_awesome_rounded,
              "Halving Logic",
              widget.halvingRuleEnabled
                  ? "ON (${thresholds.join(', ')})"
                  : "OFF",
            ),
            const SizedBox(height: 16),
            _buildRuleInfoRow(
              context,
              Icons.workspace_premium_rounded,
              "Winner Bonus",
              widget.winnerHalfPreviousScoreRule
                  ? "ON (Winner halves previous score)"
                  : "OFF",
            ),
            const SizedBox(height: 16),
            _buildRuleInfoRow(
              context,
              Icons.gavel_rounded,
              "Asaf Penalty",
              widget.asafPenaltyRuleEnabled
                  ? "ON (${widget.penaltyScore} PTS)"
                  : "OFF",
            ),
            const SizedBox(height: 16),
            _buildRuleInfoRow(
              context,
              Icons.person_add_rounded,
              "Joining Penalty",
              "${widget.newPlayerJoinPenalty} PTS",
            ),
            if (widget.asafPenaltyRuleEnabled) ...[
              const SizedBox(height: 16),
              _buildRuleInfoRow(
                context,
                Icons.equalizer_rounded,
                "Tie Penalty",
                widget.penaltyOnTieRuleEnabled ? "YES (Penalize on tie)" : "NO",
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RuleExamplesScreen()),
              );
            },
            child: const Text(
              "EXAMPLES",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "GOT IT",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandings() {
    return Scoreboard(
      players: _players,
      currentWinner: currentWinner,
      targetScore: widget.endScore,
      newPlayerJoinPenalty: widget.newPlayerJoinPenalty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: gameOver || _forceEnd,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !gameOver) {
          final confirm = await _showEndGameDialog(context);
          if (confirm == true && context.mounted) {
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
              icon: const Icon(Icons.people_outline_rounded),
              onPressed: _showManagePlayersDialog,
              tooltip: "Manage Players",
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: _showRulesInfo,
              tooltip: "Match Rules",
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        bottomNavigationBar: _bannerAd != null
            ? ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              )
            : null,
        body: Column(
          children: [
            _buildStandings(),
            Expanded(
              child: RoundHistoryList(
                players: _players,
                rawScoreHistory: _rawScoreHistory,
                roundHistory: roundHistory,
                onDeleteRound: _deleteRound,
                inlineAds: _inlineAds,
              ),
            ),
          ],
        ),
        floatingActionButton: !gameOver
            ? FloatingActionButton.extended(
                onPressed: _showAddScoresDialog,
                backgroundColor: const Color(0xFF673AB7),
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  "ADD ROUND",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

Future<bool?> _showEndGameDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'END MATCH?',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: const Text('All current scores will be lost. Ready to quit?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('STAY'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(
            'QUIT',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
