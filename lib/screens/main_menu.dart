import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_selection_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  int totalHighScore = 0;
  late AnimationController _backgroundController;
  late AnimationController _logoController;

  // Custom floating bubble particles for the main menu background
  final List<MenuBubbleParticle> _menuBubbles = List.generate(15, (i) => MenuBubbleParticle());

  @override
  void initState() {
    super.initState();
    _loadHighScore();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalHighScore = prefs.getInt('highScore') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B071E),
      body: Stack(
        children: [
          // BACKGROUND: Vibrant Space Space-Neon Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0C20),
                  Color(0xFF150A21),
                  Color(0xFF0A0518),
                ],
              ),
            ),
          ),

          // RUNTIME LAYER: Floating Bubble Particles matching the game concept
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: MenuBubblePainter(
                  bubbles: _menuBubbles,
                  progress: _backgroundController.value,
                ),
              );
            },
          ),

          // INTERFACE CONTENT LAYER
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. NEON PULSING BUBBLE SHAPE LOGO CONTAINER
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      double scale = 1.0 + (_logoController.value * 0.06);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF007F).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icon/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF161129),
                                  child: const Icon(
                                      Icons.blur_circular_rounded,
                                      color: Color(0xFF00F2FE),
                                      size: 80
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 35),

                  // 2. EYE-CATCHING NEON GLOW TYPOGRAPHY
                  const Text(
                    'BUBBLE BURST',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: Color(0xFF00F2FE), blurRadius: 10, offset: Offset(-2, 0)),
                        Shadow(color: Color(0xFFFF007F), blurRadius: 15, offset: Offset(2, 0)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'POP & BLAST CHAMPIONSHIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00F2FE),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 3. ARCADE STYLE HIGH SCORE DECAL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1538).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFF007F).withOpacity(0.4),
                          width: 1.5
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'HIGH SCORE: $totalHighScore',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // 4. VIBRANT GRADIENT CAPSULE PLAY BUTTON
                  Container(
                    width: 230,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F2FE), Color(0xFFFF007F)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF007F).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
                        ).then((_) => _loadHighScore());
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 4),
                          Text(
                            'PLAY NOW',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5
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
        ],
      ),
    );
  }
}

class MenuBubbleParticle {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double speed = 0.05 + Random().nextDouble() * 0.07;
  double radius = 6.0 + Random().nextDouble() * 14.0;
  Color color = Random().nextBool() ? const Color(0xFF00F2FE) : const Color(0xFFFF007F);
}

class MenuBubblePainter extends CustomPainter {
  final List<MenuBubbleParticle> bubbles;
  final double progress;

  MenuBubblePainter({required this.bubbles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var b in bubbles) {
      double currentY = (b.y * size.height - (progress * b.speed * size.height)) % size.height;
      double currentX = b.x * size.width;

      final paint = Paint()
        ..color = b.color.withOpacity(0.12)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = b.color.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(currentX, currentY), b.radius, paint);
      canvas.drawCircle(Offset(currentX, currentY), b.radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MenuBubblePainter oldDelegate) => true;
}