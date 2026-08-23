import 'package:flutter/material.dart';

import 'player.dart';

class Scoreboard extends StatelessWidget {
  final List<Player> players;
  final Player currentWinner;
  final int targetScore;
  final int newPlayerJoinPenalty;

  const Scoreboard({
    super.key,
    required this.players,
    required this.currentWinner,
    required this.targetScore,
    required this.newPlayerJoinPenalty,
  });

  @override
  Widget build(BuildContext context) {
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
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, const Color(0xFF311B92)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((p) {
          int total = 0;
          bool hasPlayed = p.totals.isNotEmpty;

          if (hasPlayed) {
            total = p.totals.last;
          } else if (p.joinedAtRound > 0) {
            // Show projected starting score for mid-game joiners
            int currentMax = players.isEmpty
                ? 0
                : players
                      .map((pl) => pl.totals.isEmpty ? 0 : pl.totals.last)
                      .reduce((a, b) => a > b ? a : b);
            total = currentMax + newPlayerJoinPenalty;
          }

          bool isLeading = hasPlayed && p == currentWinner;
          bool isDanger = total > targetScore * 0.8;

          return Expanded(
            child: Tooltip(
              message: p.name,
              triggerMode: TooltipTriggerMode.longPress,
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
                            color: isLeading
                                ? Colors.amber
                                : (isDanger
                                      ? Colors.redAccent
                                      : Colors.white24),
                            width: 2.5,
                          ),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            p.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isLeading)
                        const Positioned(
                          top: -12,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    p.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$total",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDanger
                          ? Colors.redAccent
                          : (isLeading ? Colors.amber : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
