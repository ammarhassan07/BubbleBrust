import 'package:bubble_burst/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BubbleShooterApp());
}

class BubbleShooterApp extends StatelessWidget {
  const BubbleShooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Shooter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SplashScreen(), // Swapped to MainMenu
    );
  }
}