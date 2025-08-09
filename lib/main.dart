import 'package:flutter/material.dart';
import 'package:yaniv/setup_screen.dart';

void main() {
  runApp(YanivScoreApp());
}

class YanivScoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yaniv Score Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SetupScreen(),
    );
  }
}
