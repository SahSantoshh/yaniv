import 'package:flutter/material.dart';
import 'player.dart';
import 'game_screen.dart';

class RoundHistoryList extends StatelessWidget {
  final List<Player> players;
  final List<List<RoundScore>> rawScoreHistory;
  final List<List<String>> roundHistory;
  final Function(int) onDeleteRound;

  const RoundHistoryList({
    super.key,
    required this.players,
    required this.rawScoreHistory,
    required this.roundHistory,
    required this.onDeleteRound,
  });

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
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF673AB7),
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(scoreStr, style: baseStyle, textAlign: TextAlign.center);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (roundHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              "NO ROUNDS PLAYED",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: colorScheme.primary.withValues(alpha: 0.2),
                fontSize: 12,
              ),
            ),
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
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Text(
                "${reversedIndex + 1}",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(players.length, (i) {
                final isWinner =
                    rawScoreHistory[reversedIndex][i].value == 0 &&
                    !rawScoreHistory[reversedIndex][i].isInactive;
                final isCaller = rawScoreHistory[reversedIndex][i].isCaller;

                if (rawScoreHistory[reversedIndex][i].isInactive) {
                  return const Text(
                    "-",
                    style: TextStyle(
                      color: Colors.black12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          "${rawScoreHistory[reversedIndex][i].value}",
                          style: TextStyle(
                            fontWeight: isWinner
                                ? FontWeight.w900
                                : FontWeight.w600,
                            fontSize: 18,
                            color: isWinner
                                ? const Color(0xFFFF8F00)
                                : Colors.black87,
                          ),
                        ),
                        if (isCaller)
                          Positioned(
                            top: -4,
                            right: -10,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF673AB7),
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                "Y",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isWinner)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8F00),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                );
              }),
            ),
            trailing: const Icon(
              Icons.expand_more_rounded,
              color: Colors.black26,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const Divider(height: 24),
                    ...List.generate(
                      players.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      players[i].name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            rawScoreHistory[reversedIndex][i]
                                                .isInactive
                                            ? Colors.black12
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                  if (rawScoreHistory[reversedIndex][i]
                                      .isCaller)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF673AB7,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "CALLER",
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF673AB7),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _scoreDisplay(displayScores[i], Colors.black87),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => onDeleteRound(reversedIndex),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text(
                        "DELETE ROUND",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
