import 'package:flutter/material.dart';

class RuleExamplesScreen extends StatelessWidget {
  const RuleExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('RULE EXAMPLES')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: const [
          _Intro(),
          _ExampleCard(
            title: 'Call score',
            body: 'Default is 5. A hand above that cannot call.',
            lines: [
              'A calls with 5 → round is saved',
              'A calls with 0 → round is saved',
              'A calls with 6 → rejected, round is not saved',
            ],
          ),
          _ExampleCard(
            title: 'Successful call',
            body: 'The caller has the lowest hand. They add 0. With winner half on, their total is halved.',
            lines: [
              'A calls 3, B has 8, C has 10 → A +0, B +8, C +10',
              'A was 40 and calls 0, B was 20 and has 4 → A 20, B 24',
            ],
          ),
          _ExampleCard(
            title: 'Asaf',
            body: 'Someone has a lower hand. The caller adds their hand plus 30. The lowest hand adds 0.',
            lines: [
              'A calls 5, B has 2, C has 9 → A +35, B +0, C +9',
              'A was 10 and calls 5, B was 40 and has 2, C was 20 and has 2 → A 45, B 20, C 10',
            ],
          ),
          _ExampleCard(
            title: 'Tie penalty',
            body: 'On by default. An exact tie is a failed call.',
            lines: [
              'On: A calls 4, B has 4 → A +34, B +0',
              'Off: A calls 4, B has 4 → A +0, B +4',
            ],
          ),
          _ExampleCard(
            title: 'Caller and someone else both have 0',
            body: 'A called 0 is never a penalty. With winner half on, only the caller is halved.',
            lines: [
              'Half on: A was 40, B was 20, C was 10. A calls 0, B has 0, C has 6 → A 20, B 20, C 16',
              'Half off, tie penalty on → A was 40 stays 40, B was 20 stays 20',
              'Half off, tie penalty off → both add 0',
            ],
          ),
          _ExampleCard(
            title: 'Asaf off',
            body: 'The lowest hand is the caller. If several players share it, pick which of them called. Only that caller is halved.',
            lines: [
              'A has 2, B has 8, C has 9 → A is the caller and is halved, B and C add their hands',
              'A was 40 and has 4, B was 20 and has 4, C was 10 and has 9. A called → A 20, B 20, C 19',
              'A and B both have 0 → the round waits until you pick the caller',
            ],
          ),
          _ExampleCard(
            title: 'Halving',
            body: 'A total that lands exactly on 124 or 62 is cut in half, rounded up.',
            lines: [
              'A was 120 and adds 4 → 62',
              'A was 61 and adds 1 → 31',
              'A was 100 and adds 10 → 110, no threshold hit',
              'Halving off: A was 120 and adds 4 → 124',
            ],
          ),
          _ExampleCard(
            title: 'Winner half',
            body: 'A round winner’s previous total is cut in half, rounded up.',
            lines: [
              'Previous 40, round score 0 → 20',
              'Previous 41, round score 0 → 21',
              'Previous 0, round score 0 → stays 0',
            ],
          ),
          _ExampleCard(
            title: 'Joining',
            body: 'A new player starts from the highest total plus 10.',
            lines: [
              'A was 40 and adds 3, B joins with 5 → A 43, B 55',
              'B joins and wins → B starts at 50, then halves to 25',
              'Join penalty 0, B adds 5 → B becomes 45',
            ],
          ),
          _ExampleCard(
            title: 'Target score',
            body: 'Default is 124. The match ends only when a total goes above it.',
            lines: [
              '125 → match over',
              '124 → match continues',
              'Target 100 and someone reaches 101 → match over',
              'No rounds yet → match continues',
            ],
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Examples use the defaults: target 124, call score 5, penalty 30, join penalty 10. Winner half and halving are on.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String body;
  final List<String> lines;

  const _ExampleCard({
    required this.title,
    required this.body,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: const TextStyle(height: 1.35)),
            ),
        ],
      ),
    );
  }
}
