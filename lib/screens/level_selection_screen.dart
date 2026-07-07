import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_play_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int highestUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevel();
  }

  Future<void> _loadUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highestUnlockedLevel = prefs.getInt('highestUnlockedLevel') ?? 1;
    });
  }

  // Helper method to determine color scheme and difficulty text dynamically
  Map<String, dynamic> _getLevelDifficultyMetadata(int level) {
    if (level <= 5) {
      return {
        'label': 'EASY',
        'color': const Color(0xFF00FF87), // Radiant Neon Green
        'glow': const Color(0xFF00FF87).withValues(alpha: 0.3),
      };
    } else if (level <= 15) {
      return {
        'label': 'MEDIUM',
        'color': const Color(0xFF00F2FE), // Electric Cyan
        'glow': const Color(0xFF00F2FE).withValues(alpha: 0.3),
      };
    } else if (level <= 30) {
      return {
        'label': 'HARD',
        'color': const Color(0xFFFF9F43), // Vivid Orange
        'glow': const Color(0xFFFF9F43).withValues(alpha: 0.3),
      };
    } else {
      return {
        'label': 'EXPERT',
        'color': const Color(0xFFFF4757), // Intense Crimson Red
        'glow': const Color(0xFFFF4757).withValues(alpha: 0.3),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CAMPAIGN LEVELS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F2FE)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060913), Color(0xFF0F2027), Color(0xFF132A36)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
            child: GridView.builder(
              itemCount: 50,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Dropped to 3 columns to allow beautiful layout space for numbers + difficulty text labels!
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                int levelNum = index + 1;
                bool isUnlocked = levelNum <= highestUnlockedLevel;
                var meta = _getLevelDifficultyMetadata(levelNum);

                return GestureDetector(
                  onTap: () {
                    if (isUnlocked) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GamePlayScreen(startingLevel: levelNum),
                        ),
                      ).then((_) => _loadUnlockedLevel());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('SECTOR $levelNum IS LOCKED! Complete previous zones first.'),
                          backgroundColor: Colors.redAccent,
                          duration: const Duration(milliseconds: 1000),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(0xFF1E272C).withValues(alpha: 0.75)
                          : Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUnlocked ? (meta['color'] as Color) : Colors.white10,
                        width: isUnlocked ? 2.5 : 1.5,
                      ),
                      boxShadow: isUnlocked
                          ? [
                        BoxShadow(
                          color: (meta['glow'] as Color),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        // Glassmorphic sheen effect accent corner
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? (meta['color'] as Color).withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                          ),
                        ),

                        // Core Tile Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isUnlocked) ...[
                                Text(
                                  '$levelNum',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Beautiful difficulty pill badge under the number
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (meta['color'] as Color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    meta['label'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: (meta['color'] as Color),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Icon(Icons.lock_rounded, color: Colors.white24, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'LOCKED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white24,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}