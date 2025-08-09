import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameHistory {
  static const String _key = 'game_results';

  /// Save game result with winner and loser info
  static Future<void> addGameResult({
    required String winnerName,
    required int winnerScore,
    required String loserName,
    required int loserScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final historyJson = prefs.getString(_key);
    List<dynamic> history = historyJson == null ? [] : jsonDecode(historyJson);

    history.add({
      'date': DateTime.now().toIso8601String(),
      'winner': winnerName,
      'winnerScore': winnerScore,
      'loser': loserName,
      'loserScore': loserScore,
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
