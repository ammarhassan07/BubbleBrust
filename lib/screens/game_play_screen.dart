import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/bubble_game.dart';
import '../game/helpers/grid_manager.dart';
import '../game/helpers/collision_system.dart';
import '../game/components/particle.dart';
import '../game/helpers/audio_manager.dart';

class GamePlayScreen extends StatefulWidget {
  final int startingLevel;
  const GamePlayScreen({super.key, this.startingLevel = 1});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> with TickerProviderStateMixin {
  late GridManager gridManager;
  late CollisionSystem collisionSystem;
  late Ticker _ticker;

  final double bubbleRadius = 24.0;
  final List<Color> masterColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];

  Offset? touchPosition;
  late Offset projectilePos;
  Offset? projectileVelocity;
  late Color projectileColor;
  late Color nextProjectileColor;
  double projectileSpeed = 16.0;

  int score = 0;
  int highScore = 0;
  bool isGameOverTriggered = false;
  late int currentLevel;
  List<BubbleParticle> particles = [];

  int shotCounter = 0;
  double levelTimerValue = 1.0;
  double totalLevelTimeInSeconds = 60.0;
  double remainingTimeInSeconds = 60.0;

  int availableSwaps = 3;
  int shieldLives = 1;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.startingLevel;
    AudioManager().stopBGM();
    _loadHighScoreAndSettings();
    _startNewLevel(initLoad: true);

    _ticker = createTicker((elapsed) {
      _updateGameStep();
    });
    _ticker.start();
  }

  Future<void> _loadHighScoreAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScoreIfNeeded() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void _startNewLevel({bool initLoad = false}) {
    gridManager = GridManager(bubbleRadius: bubbleRadius);
    collisionSystem = CollisionSystem(gridManager: gridManager);

    int rowsToFill = 3 + (currentLevel ~/ 10);
    if (rowsToFill > 6) rowsToFill = 6;

    bool isHardStage = currentLevel % 5 == 0;
    if (isHardStage) {
      rowsToFill = (rowsToFill + 1).clamp(3, 7);
    }

    totalLevelTimeInSeconds = 60.0 + ((currentLevel - 1) * 5.0);
    remainingTimeInSeconds = totalLevelTimeInSeconds;
    levelTimerValue = 1.0;
    availableSwaps = 3;
    if (initLoad) shieldLives = 1;

    int activeColorCount = (3 + (currentLevel ~/ 12)).clamp(3, masterColors.length);
    List<Color> availableColors = masterColors.sublist(0, activeColorCount);

    final randomSeed = Random(currentLevel * 313);

    for (int r = 0; r < rowsToFill; r++) {
      for (int c = 0; c < gridManager.cols; c++) {
        double holeChance = 0.15 - (currentLevel * 0.002).clamp(0.0, 0.10);
        if (currentLevel > 2 && randomSeed.nextDouble() < holeChance && !isHardStage) {
          gridManager.grid[r][c] = null;
          continue;
        }
        gridManager.grid[r][c] = availableColors[randomSeed.nextInt(availableColors.length)];
      }
    }

    double baseSpeedModifier = 1.0 + (currentLevel * 0.01);
    projectileSpeed = 16.0 * baseSpeedModifier;
    shotCounter = 0;

    List<Color> currentLivingColors = _getRemainingColorsOnScreen();
    if (initLoad) {
      projectileColor = currentLivingColors.isNotEmpty ? currentLivingColors[Random().nextInt(currentLivingColors.length)] : masterColors.first;
    }
    nextProjectileColor = currentLivingColors.isNotEmpty ? currentLivingColors[Random().nextInt(currentLivingColors.length)] : masterColors.first;

    _generateNewProjectile();
    setState(() {
      isGameOverTriggered = false;
    });
  }

  List<Color> _getRemainingColorsOnScreen() {
    Set<Color> presentColors = {};
    for (int r = 0; r < gridManager.rows; r++) {
      for (int c = 0; c < gridManager.cols; c++) {
        Color? color = gridManager.grid[r][c];
        if (color != null) presentColors.add(color);
      }
    }
    return presentColors.toList();
  }

  // FIXED: Adjusted cannon height closer to the bottom to squeeze empty gap
  void _generateNewProjectile() {
    double gameWidth = bubbleRadius * 2 * gridManager.cols;
    projectilePos = Offset(gameWidth / 2, (gridManager.rowHeight * gridManager.rows) + 55);
    projectileVelocity = null;
  }

  void _executeManualSwapPowerUp() {
    if (projectileVelocity != null || isGameOverTriggered || availableSwaps <= 0) return;
    setState(() {
      Color temp = projectileColor;
      projectileColor = nextProjectileColor;
      nextProjectileColor = temp;
      availableSwaps--;
    });
    AudioManager().playPopSFX();
  }

  void _advanceGridDownward() {
    for (int r = gridManager.rows - 1; r > 0; r--) {
      for (int c = 0; c < gridManager.cols; c++) {
        gridManager.grid[r][c] = gridManager.grid[r - 1][c];
      }
    }
    List<Color> activePool = _getRemainingColorsOnScreen();
    if (activePool.isEmpty) activePool = masterColors.sublist(0, 3);
    for (int c = 0; c < gridManager.cols; c++) {
      gridManager.grid[0][c] = Random().nextBool() ? activePool[Random().nextInt(activePool.length)] : null;
    }
    AudioManager().playPopSFX();
  }

  void _updateGameStep() {
    if (isGameOverTriggered) return;

    if (particles.isNotEmpty) {
      setState(() {
        particles.removeWhere((p) => !p.update(0.016));
      });
    }

    setState(() {
      remainingTimeInSeconds -= 0.016;
      levelTimerValue = (remainingTimeInSeconds / totalLevelTimeInSeconds).clamp(0.0, 1.0);
      if (remainingTimeInSeconds <= 0.0) {
        _handleDefeatCondition();
        return;
      }
    });

    if (projectileVelocity == null) return;

    setState(() {
      projectilePos += projectileVelocity!;
      double maxRightEdge = bubbleRadius * 2 * gridManager.cols;

      if (projectilePos.dx <= bubbleRadius) {
        projectilePos = Offset(bubbleRadius, projectilePos.dy);
        projectileVelocity = Offset(-projectileVelocity!.dx, projectileVelocity!.dy);
      } else if (projectilePos.dx >= maxRightEdge - bubbleRadius) {
        projectilePos = Offset(maxRightEdge - bubbleRadius, projectilePos.dy);
        projectileVelocity = Offset(-projectileVelocity!.dx, projectileVelocity!.dy);
      }

      if (projectilePos.dy <= bubbleRadius) {
        projectileVelocity = null;
        _snapToGridAndProcess(projectilePos);
        return;
      }

      if (collisionSystem.checkCollision(projectilePos, bubbleRadius)) {
        _snapToGridAndProcess(projectilePos);
      }
    });
  }

  void _snapToGridAndProcess(Offset position) {
    Point<int> gridPos = gridManager.getClosestGridPosition(position);

    if (gridManager.grid[gridPos.x][gridPos.y] == null) {
      gridManager.grid[gridPos.x][gridPos.y] = projectileColor;
      AudioManager().playPopSFX();

      List<Point<int>> trackedBoard = [];
      for (int r = 0; r < gridManager.rows; r++) {
        for (int c = 0; c < gridManager.cols; c++) {
          if (gridManager.grid[r][c] != null) trackedBoard.add(Point(r, c));
        }
      }

      collisionSystem.processPop(gridPos.x, gridPos.y, projectileColor);

      int poppedCount = 0;
      for (var target in trackedBoard) {
        if (gridManager.grid[target.x][target.y] == null) {
          poppedCount++;
          _spawnExplosion(gridManager.getBubbleCenter(target.x, target.y), projectileColor);
        }
      }

      if (poppedCount > 0) {
        score += poppedCount * 10;
        _saveHighScoreIfNeeded();
      }

      shotCounter++;
      if (shotCounter >= 5) {
        shotCounter = 0;
        _advanceGridDownward();
      }
    }

    _checkGameEndStates();

    if (!isGameOverTriggered) {
      List<Color> dynamicPool = _getRemainingColorsOnScreen();
      if (dynamicPool.isNotEmpty) {
        if (!dynamicPool.contains(nextProjectileColor)) {
          nextProjectileColor = dynamicPool[Random().nextInt(dynamicPool.length)];
        }
        projectileColor = nextProjectileColor;
        nextProjectileColor = dynamicPool[Random().nextInt(dynamicPool.length)];
      }
      _generateNewProjectile();
    }
  }

  int _countRemainingBubbles() {
    int count = 0;
    for (var row in gridManager.grid) {
      for (var cell in row) {
        if (cell != null) count++;
      }
    }
    return count;
  }

  Future<void> _unlockNextLevel() async {
    final prefs = await SharedPreferences.getInstance();
    int highest = prefs.getInt('highestUnlockedLevel') ?? 1;
    if (currentLevel >= highest) {
      await prefs.setInt('highestUnlockedLevel', currentLevel + 1);
    }
  }

  void _checkGameEndStates() {
    int remaining = _countRemainingBubbles();
    if (remaining == 0 && shotCounter > 0) {
      _ticker.stop();
      isGameOverTriggered = true;
      _unlockNextLevel();
      _showEndGameDialog(isWin: true);
      return;
    }

    int dangerThresholdRow = gridManager.rows - 2;
    for (int c = 0; c < gridManager.cols; c++) {
      if (gridManager.grid[dangerThresholdRow][c] != null) {
        _handleDefeatCondition();
        return;
      }
    }
  }

  void _handleDefeatCondition() {
    if (shieldLives > 0) {
      setState(() {
        shieldLives--;
        for (int r = gridManager.rows - 3; r < gridManager.rows; r++) {
          for (int c = 0; c < gridManager.cols; c++) {
            gridManager.grid[r][c] = null;
          }
        }
        remainingTimeInSeconds = (remainingTimeInSeconds + 20.0).clamp(20.0, totalLevelTimeInSeconds);
      });
      return;
    }
    remainingTimeInSeconds = 0.0;
    levelTimerValue = 0.0;
    isGameOverTriggered = true;
    _ticker.stop();
    _showEndGameDialog(isWin: false);
  }

  void _spawnExplosion(Offset center, Color color) {
    int particleCount = 12;
    Random rand = Random();
    for (int i = 0; i < particleCount; i++) {
      double angle = (i * 2 * pi) / particleCount + (rand.nextDouble() * 0.4);
      double speed = 2.5 + rand.nextDouble() * 3.5;
      particles.add(BubbleParticle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        radius: 2.5 + rand.nextDouble() * 3.0,
      ));
    }
  }

  void _showEndGameDialog({required bool isWin}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isWin
                  ? [const Color(0xFF0F2027), const Color(0xFF1A3A2A), const Color(0xFF0B1A10)]
                  : [const Color(0xFF1A0A1A), const Color(0xFF2D0B1A), const Color(0xFF0F0614)],
            ),
            border: Border.all(
              color: isWin ? const Color(0xFFFFD700).withOpacity(0.6) : const Color(0xFFFF3366).withOpacity(0.6),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isWin ? const Color(0xFFFFD700).withOpacity(0.25) : const Color(0xFFFF3366).withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon badge ──
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isWin
                          ? [const Color(0xFFFFD700), const Color(0xFFFF8C00), const Color(0xFF7B3F00)]
                          : [const Color(0xFFFF3366), const Color(0xFFB0003A), const Color(0xFF3A001A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isWin ? const Color(0xFFFFD700).withOpacity(0.55) : const Color(0xFFFF3366).withOpacity(0.55),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isWin ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Title ──
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isWin
                        ? [const Color(0xFFFFD700), const Color(0xFFFFF176), const Color(0xFFFF8C00)]
                        : [const Color(0xFFFF3366), const Color(0xFFFF80AB), const Color(0xFFD500F9)],
                  ).createShader(bounds),
                  child: Text(
                    isWin ? '🏆 VICTORY!' : '💀 GAME OVER',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Subtitle ──
                Text(
                  isWin ? 'Incredible! All bubbles cleared!' : 'Better luck next time, hero!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Score chip ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: isWin ? const Color(0xFFFFD700).withOpacity(0.35) : const Color(0xFFFF3366).withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: isWin ? const Color(0xFFFFD700) : const Color(0xFFFF80AB), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'SCORE  $score',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isWin ? const Color(0xFFFFD700) : const Color(0xFFFF80AB),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Primary action button ──
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // close dialog only
                    setState(() {
                      if (isWin) {
                        currentLevel++; // advance to next level
                      }
                      particles.clear();
                      isGameOverTriggered = false;
                    });
                    _startNewLevel();
                    if (!_ticker.isActive) _ticker.start();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isWin
                            ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
                            : [const Color(0xFFFF3366), const Color(0xFFD500F9)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isWin ? const Color(0xFFFFD700).withOpacity(0.4) : const Color(0xFFFF3366).withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isWin ? Icons.arrow_forward_rounded : Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isWin ? 'NEXT LEVEL' : 'TRY AGAIN',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Secondary QUIT button ──
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // close dialog
                    Navigator.of(context).pop(); // exit game screen
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.exit_to_app_rounded, color: Colors.white54, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'QUIT TO MENU',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white54,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fireProjectile(Offset target) {
    if (projectileVelocity != null || isGameOverTriggered || touchPosition == null) return;
    double gameWidth = bubbleRadius * 2 * gridManager.cols;
    Offset baseCannon = Offset(gameWidth / 2, (gridManager.rowHeight * gridManager.rows) + 55);
    Offset direction = target - baseCannon;
    double distance = direction.distance;
    if (direction.dy >= 0) return;
    projectileVelocity = Offset((direction.dx / distance) * projectileSpeed, (direction.dy / distance) * projectileSpeed);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double gameWidth = bubbleRadius * 2 * gridManager.cols;

    int minutes = remainingTimeInSeconds ~/ 60;
    int seconds = (remainingTimeInSeconds % 60).toInt();
    String timeString = "$minutes:${seconds.toString().padLeft(2, '0')}s";

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: SafeArea(
        child: Column(
          children: [
            // FIXED: Added bottom border with a crisp 2.5 width layout matching your request
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              width: gameWidth,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1525), Color(0xFF0F1A2A), Color(0xFF0D1525)],
                ),
                border: const Border(bottom: BorderSide(color: Color(0xFF00F2FE), width: 2.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F2FE).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Color(0xFF00F2FE), size: 14),
                        const SizedBox(width: 4),
                        Text('$score', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF00F2FE))),
                      ],
                    ),
                  ),
                  // Timer pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F2FE).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded, color: Color(0xFF00F2FE), size: 14),
                        const SizedBox(width: 4),
                        Text(timeString, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF00F2FE))),
                      ],
                    ),
                  ),
                  // Best pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text('$highScore', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFFD700))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: gameWidth,
              height: 3,
              child: LinearProgressIndicator(
                value: levelTimerValue,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F2FE)),
              ),
            ),

            // FIXED: Wrapped container inside Expanded so canvas fills the screen dynamically, removing gap
            Expanded(
              child: Center(
                child: Container(
                  width: gameWidth,
                  color: const Color(0xFF060913),
                  child: GestureDetector(
                    onPanUpdate: (details) => setState(() => touchPosition = details.localPosition),
                    onPanEnd: (details) {
                      if (touchPosition != null) {
                        _fireProjectile(touchPosition!);
                        touchPosition = null;
                      }
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: BubbleGame(
                        gridManager: gridManager,
                        collisionSystem: collisionSystem,
                        touchPosition: touchPosition,
                        projectilePos: projectilePos,
                        projectileVelocity: projectileVelocity,
                        projectileColor: projectileColor,
                        nextProjectileColor: nextProjectileColor,
                        particles: particles,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // INTERACTIVE POWER-UP CONTROLS PANEL
            Container(
              width: gameWidth,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0E1420), Color(0xFF0C101B)],
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.18), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: shieldLives > 0 ? const Color(0xFFFF007F).withOpacity(0.1) : Colors.white10,
                          shape: BoxShape.circle,
                          border: Border.all(color: shieldLives > 0 ? const Color(0xFFFF007F) : Colors.white30, width: 1.5),
                        ),
                        child: Icon(Icons.gpp_good_rounded, color: shieldLives > 0 ? const Color(0xFFFF007F) : Colors.white30, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text("SHIELD: ${shieldLives > 0 ? 'READY' : 'USED'}", style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  GestureDetector(
                    onTap: _executeManualSwapPowerUp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.6), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(color: nextProjectileColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("SWAP COLOR", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                              Text("Charges: $availableSwaps left", style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 9)),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.cached_rounded, color: Color(0xFF00F2FE), size: 18),
                        ],
                      ),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F2FE).withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00F2FE), width: 1.5),
                        ),
                        child: Text("${5 - shotCounter}", style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 14, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 4),
                      const Text("NEXT DROP", style: TextStyle(color: Color(0xFF00F2FE), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}