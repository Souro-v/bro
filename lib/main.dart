import 'package:flutter/material.dart';

import 'screens/assistant_screen.dart';

void main() {
  runApp(const HeyBroApp());
}

class HeyBroApp extends StatelessWidget {
  const HeyBroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hey Bro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
      ),
      home: const AssistantScreen(),
    );
  }
}