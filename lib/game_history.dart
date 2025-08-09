import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameHistory {
  static const String _key = 'game_winners';

  /// Save a winner with current date
  static Future<void> addGameWinner(String winnerName, int winnerScore) async {
    final prefs = await SharedPreferences.getInstance();

    final historyJson = prefs.getString(_key);
    List<dynamic> history = historyJson == null ? [] : jsonDecode(historyJson);

    history.add({
      'date': DateTime.now().toIso8601String(),
      'winner': winnerName,
      'score': winnerScore,
    });

    await prefs.setString(_key, jsonEncode(history));
  }

  /// Get the entire game history list
  static Future<List<Map<String, dynamic>>> getGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_key);
    if (historyJson == null) return [];
    final List<dynamic> history = jsonDecode(historyJson);
    return history.cast<Map<String, dynamic>>();
  }
}
