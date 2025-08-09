import 'package:flutter/material.dart';
import 'game_history.dart';

class GameHistoryScreen extends StatelessWidget {
  const GameHistoryScreen({Key? key}) : super(key: key);

  String formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: GameHistory.getGameHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No game history yet.'));
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return ListTile(
                title: Text(entry['winner']),
                subtitle: Text('Score: ${entry['score']}'),
                trailing: Text(formatDate(entry['date'])),
              );
            },
          );
        },
      ),
    );
  }
}
