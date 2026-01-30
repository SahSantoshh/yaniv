import 'package:flutter/material.dart';
import 'package:yaniv/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(YanivScoreApp());
}

class YanivScoreApp extends StatelessWidget {
  const YanivScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yaniv Score Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SetupScreen(),
    );
  }
}
