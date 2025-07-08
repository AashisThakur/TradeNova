// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/option_chain_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '5paisa Option Chain Viewer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OptionChainPage(),
    );
  }
}
