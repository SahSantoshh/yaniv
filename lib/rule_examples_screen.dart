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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: const [
          _Intro(),
          _Section(
            title: 'Call score',
            body:
                'You can call only when your hand is at or below the call score.',
            tables: [
              _Table(
                columns: ['Case', 'Input', 'Result'],
                flex: [3, 4, 4],
                rows: [
                  ['At the limit', 'Call score 5, A calls 5', 'Round is saved'],
                  ['Below the limit', 'Call score 5, A calls 0', 'Round is saved'],
                  [
                    'Above the limit',
                    'Call score 5, A calls 6',
                    'Rejected. Round is not saved',
                  ],
                  ['Custom limit', 'Call score 7, A calls 7', 'Round is saved'],
                  [
                    'Above a custom limit',
                    'Call score 7, A calls 8',
                    'Rejected',
                  ],
                  ['Blank', 'Call score left blank', 'Treated as 5'],
                  ['Negative', 'Call score −1', 'Match does not start'],
                  ['Zero', 'Call score 0', 'Only a hand of 0 may call'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Successful call',
            body:
                'The caller has the lowest hand alone. They add 0. With winner half on, their previous total is halved. Everyone else adds their hand.',
            tables: [
              _Table(
                caption: 'A calls 3. B has 8. C has 10.',
                columns: ['Player', 'Hand', 'Adds'],
                rows: [
                  ['A, caller', '3', '0'],
                  ['B', '8', '8'],
                  ['C', '10', '10'],
                ],
              ),
              _Table(
                caption: 'A was 40 and calls 0. B was 20 and has 4.',
                columns: ['Player', 'Was', 'Hand', 'Becomes'],
                rows: [
                  ['A, caller', '40', '0', '20'],
                  ['B', '20', '4', '24'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Asaf',
            body:
                'Someone has a lower hand. The caller adds their hand plus 30. The lowest hand adds 0.',
            tables: [
              _Table(
                caption: 'A calls 5. B has 2. C has 9.',
                columns: ['Player', 'Hand', 'Adds'],
                rows: [
                  ['A, caller', '5', '35, penalty'],
                  ['B', '2', '0'],
                  ['C', '9', '9'],
                ],
              ),
              _Table(
                caption:
                    'A was 10 and calls 5. B was 40 and has 2. C was 20 and has 2. Both lowest hands are halved.',
                columns: ['Player', 'Was', 'Hand', 'Adds', 'Becomes'],
                flex: [3, 2, 2, 2, 2],
                rows: [
                  ['A, caller', '10', '5', '35', '45'],
                  ['B', '40', '2', '0', '20'],
                  ['C', '20', '2', '0', '10'],
                ],
              ),
              _Table(
                caption: 'Penalty set to 20. A calls 5. B has 1.',
                columns: ['Player', 'Hand', 'Adds'],
                rows: [
                  ['A, caller', '5', '25, penalty'],
                  ['B', '1', '0'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Tie penalty',
            body: 'On by default. An exact tie is a failed call.',
            tables: [
              _Table(
                caption: 'On. A calls 4. B has 4.',
                columns: ['Player', 'Hand', 'Adds'],
                rows: [
                  ['A, caller', '4', '34, penalty'],
                  ['B', '4', '0'],
                ],
              ),
              _Table(
                caption: 'Off. A calls 4. B has 4.',
                columns: ['Player', 'Hand', 'Adds'],
                rows: [
                  ['A, caller', '4', '0'],
                  ['B', '4', '4'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Caller and someone else both have 0',
            body:
                'A called 0 is never a penalty. With winner half on, only the caller is halved.',
            tables: [
              _Table(
                caption:
                    'Winner half on. A was 40, B was 20, C was 10. A calls 0, B has 0, C has 6.',
                columns: ['Player', 'Was', 'Hand', 'Becomes'],
                rows: [
                  ['A, caller', '40', '0', '20'],
                  ['B', '20', '0', '20'],
                  ['C', '10', '6', '16'],
                ],
              ),
              _Table(
                caption: 'Winner half off, tie penalty on. Both hands are 0.',
                columns: ['Player', 'Was', 'Hand', 'Becomes'],
                rows: [
                  ['A, caller', '40', '0', '40'],
                  ['B', '20', '0', '20'],
                ],
              ),
              _Table(
                caption: 'Winner half off, tie penalty off. Both hands are 0.',
                columns: ['Player', 'Hand', 'Adds'],
                rows: [
                  ['A, caller', '0', '0'],
                  ['B', '0', '0'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Asaf off',
            body:
                'The lowest hand is the caller. If several players share it, pick which of them called. Only that caller is halved.',
            tables: [
              _Table(
                caption:
                    'One lowest hand. A was 40 and has 2. B was 20 and has 8. C was 10 and has 9.',
                columns: ['Player', 'Was', 'Hand', 'Becomes'],
                rows: [
                  ['A, caller', '40', '2', '20'],
                  ['B', '20', '8', '28'],
                  ['C', '10', '9', '19'],
                ],
              ),
              _Table(
                caption:
                    'Shared lowest hand. A was 40 and has 4. B was 20 and has 4. C was 10 and has 9. A called.',
                columns: ['Player', 'Was', 'Hand', 'Becomes'],
                rows: [
                  ['A, caller', '40', '4', '20'],
                  ['B', '20', '4', '20'],
                  ['C', '10', '9', '19'],
                ],
              ),
              _Table(
                caption:
                    'A and B both have 0. C has 6. Previous totals 40, 20, 10. B is picked as the caller.',
                columns: ['Player', 'Was', 'Hand', 'Becomes'],
                rows: [
                  ['A', '40', '0', '40'],
                  ['B, caller', '20', '0', '10'],
                  ['C', '10', '6', '16'],
                ],
              ),
              _Table(
                columns: ['Case', 'Result'],
                flex: [2, 3],
                rows: [
                  ['No caller picked', 'Round is not saved'],
                  ['C is picked, and C is not lowest', 'Rejected'],
                  ['Lowest hand is 7, call score is 5', 'Round is not saved'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Halving',
            body:
                'A total that lands exactly on 124 or 62 is cut in half, rounded up. 31 is odd, so it is not a threshold.',
            tables: [
              _Table(
                columns: ['Case', 'Input', 'Result'],
                flex: [3, 4, 3],
                rows: [
                  ['Lands on 124', 'A was 120 and adds 4', '62'],
                  ['Same round, no hit', 'B was 10 and adds 1', '11'],
                  ['Lands on 62', 'A was 61 and adds 1', '31'],
                  ['Misses both', 'A was 100 and adds 10', '110'],
                  ['Halving off', 'A was 120 and adds 4', '124'],
                  ['Odd target', 'Target 125', 'No thresholds'],
                  ['Custom target 100', 'A was 90 and adds 10', '50'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Winner half',
            body:
                'A round winner’s previous total is cut in half, rounded up. A score of 0 that is not the winner is not halved.',
            tables: [
              _Table(
                columns: ['Case', 'Input', 'Result'],
                flex: [3, 4, 3],
                rows: [
                  ['Even total', 'Previous 40, round score 0', '20'],
                  ['Odd total', 'Previous 41, round score 0', '21'],
                  ['Already 0', 'Previous 0, round score 0', 'Stays 0'],
                  ['Not the winner', 'Round score 6', '6 is added'],
                  ['Winner half off', 'Previous 40, round score 0', 'Stays 40'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Joining',
            body: 'A new player starts from the highest total plus the join penalty.',
            tables: [
              _Table(
                caption:
                    'A was 40 and adds 3. B joins with 5. Join penalty 10. Winner half off.',
                columns: ['Player', 'Start', 'Hand', 'Becomes'],
                rows: [
                  ['A', '40', '3', '43'],
                  ['B, joining', '40 + 10', '5', '55'],
                ],
              ),
              _Table(
                caption:
                    'B joins and wins. Winner half on. B starts at 50, then that start is halved.',
                columns: ['Player', 'Becomes'],
                flex: [2, 1],
                rows: [
                  ['A', '43'],
                  ['B, joining', '25'],
                ],
              ),
              _Table(
                caption: 'Join penalty 0. A was 40 and adds 3. B adds 5.',
                columns: ['Player', 'Start', 'Hand', 'Becomes'],
                rows: [
                  ['A', '40', '3', '43'],
                  ['B, joining', '40', '5', '45'],
                ],
              ),
              _Table(
                columns: ['Case', 'Result'],
                flex: [2, 3],
                rows: [
                  ['Inactive on round 1', 'Shown as −, no total'],
                ],
              ),
            ],
          ),
          _Section(
            title: 'Target score',
            body:
                'Default is 124. The match ends only when a total goes above it.',
            tables: [
              _Table(
                columns: ['Case', 'Totals', 'Result'],
                flex: [3, 4, 4],
                rows: [
                  ['Above target', '125, target 124', 'Match over'],
                  ['On the target', '124, target 124', 'Match continues'],
                  ['Custom target', '101, target 100', 'Match over'],
                  ['No rounds', 'No totals yet', 'Match continues'],
                  ['Odd target', 'Target 125 on setup', 'Match does not start'],
                  ['Blank', 'Target left blank', 'Treated as 124'],
                ],
              ),
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

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final List<_Table> tables;

  const _Section({
    required this.title,
    required this.body,
    required this.tables,
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
          for (final table in tables) ...[
            const SizedBox(height: 12),
            table,
          ],
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final String? caption;
  final List<String> columns;
  final List<List<String>> rows;
  final List<int> flex;

  const _Table({
    this.caption,
    required this.columns,
    required this.rows,
    this.flex = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weights = flex.isEmpty
        ? List<int>.filled(columns.length, 1)
        : flex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption != null) ...[
          Text(
            caption!,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Table(
              columnWidths: {
                for (var i = 0; i < weights.length; i++)
                  i: FlexColumnWidth(weights[i].toDouble()),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  children: [
                    for (final column in columns)
                      _Cell(column, header: true),
                  ],
                ),
                for (var r = 0; r < rows.length; r++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: r.isOdd
                          ? colorScheme.primary.withValues(alpha: 0.03)
                          : Colors.white,
                    ),
                    children: [
                      for (var c = 0; c < rows[r].length; c++)
                        _Cell(rows[r][c], emphasize: c == 0),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool header;
  final bool emphasize;

  const _Cell(this.text, {this.header = false, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final penalty = text.contains('penalty');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: header ? 11 : 13,
          height: 1.25,
          fontWeight: header || emphasize || penalty
              ? FontWeight.w800
              : FontWeight.w500,
          letterSpacing: header ? 0.2 : 0,
          color: penalty
              ? Colors.redAccent
              : header
              ? colorScheme.primary
              : colorScheme.onSurface,
        ),
      ),
    );
  }
}
