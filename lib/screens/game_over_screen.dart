import 'package:flutter/material.dart';
import 'game_play_screen.dart';
import 'main_menu.dart';

class GameOverScreen extends StatelessWidget {
  final bool isWin;
  final int score;

  const GameOverScreen({super.key, required this.isWin, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isWin ? 'VICTORY!' : 'GAME OVER',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isWin ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Final Score: $score',
              style: const TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainMenu()),
                    );
                  },
                  child: const Text('Menu'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const GamePlayScreen()),
                    );
                  },
                  child: const Text('Play Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}