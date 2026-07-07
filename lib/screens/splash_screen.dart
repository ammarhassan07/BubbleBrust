import 'dart:async';
import 'package:flutter/material.dart';
import 'main_menu.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _strobeController;
  late Animation<double> _glowIntensity;
  double _loadingProgress = 0.0;
  Timer? _chargingTimer;

  @override
  void initState() {
    super.initState();

    // 1. High-Speed Commercial Strobe/Flashing Effect (600ms loops back & forth)
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    // Dynamic nonlinear pulsing intensity
    _glowIntensity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _strobeController, curve: Curves.easeInOut),
    );

    _startStaggeredCharging();
  }

  // 2. Video Jasa Staggered Loading System (Steps me speed change hogi)
  void _startStaggeredCharging() {
    const duration = Duration(milliseconds: 30);
    _chargingTimer = Timer.periodic(duration, (timer) {
      if (!mounted) return;

      setState(() {
        // Video style progression: Kahin slow, kahin achanak blast speed!
        if (_loadingProgress < 0.25) {
          _loadingProgress += 0.008; // Normal start
        } else if (_loadingProgress >= 0.25 && _loadingProgress < 0.45) {
          _loadingProgress += 0.002; // Stalls/holds like video loading
        } else if (_loadingProgress >= 0.45 && _loadingProgress < 0.85) {
          _loadingProgress += 0.035; // BLAST SPEED forward!
        } else if (_loadingProgress >= 0.85 && _loadingProgress < 1.0) {
          _loadingProgress += 0.012; // Smooth final landing
        } else {
          _loadingProgress = 1.0;
          _chargingTimer?.cancel();
          _executeScreenBlastTransition();
        }
      });
    });
  }

  void _executeScreenBlastTransition() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainMenu(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Fade out blast transition to match game entry style
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _strobeController.dispose();
    _chargingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040209),
      body: AnimatedBuilder(
        animation: _glowIntensity,
        builder: (context, child) {
          return Stack(
            children: [
              // BACKGROUND LAYER: Flashing neon ambient room glow matching video
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.3,
                    colors: [
                      const Color(0xFF1E0B36).withOpacity(0.15 + (_glowIntensity.value * 0.45)),
                      const Color(0xFF040209)
                    ],
                  ),
                ),
              ),

              // LIGHTNING AMBIENT STROBE EFFECT (Background borders dynamic flash)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF00F2FE).withOpacity(_glowIntensity.value * 0.03),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO: Dynamic neon scale-flashing node
                    Transform.scale(
                      scale: 0.96 + (_glowIntensity.value * 0.06),
                      child: Container(
                        width: 145,
                        height: 145,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F2FE).withOpacity(0.3 + (_glowIntensity.value * 0.5)),
                              blurRadius: 25 + (_glowIntensity.value * 25),
                              spreadRadius: 1 + (_glowIntensity.value * 4),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF007F).withOpacity(0.2 + (_glowIntensity.value * 0.3)),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF0D0A1C),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  color: const Color(0xFF00F2FE),
                                  size: 85,
                                  shadows: [
                                    Shadow(
                                        color: const Color(0xFFFF007F),
                                        blurRadius: 10 + (_glowIntensity.value * 15)
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // TEXT: Ultra flashing commercial typography
                    Text(
                      'BUBBLE BURST',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                              color: const Color(0xFF00F2FE).withOpacity(0.6 + (_glowIntensity.value * 0.4)),
                              blurRadius: 6 + (_glowIntensity.value * 12),
                              offset: const Offset(-1.5, 1.5)
                          ),
                          Shadow(
                              color: const Color(0xFFFF007F).withOpacity(0.5 + (_glowIntensity.value * 0.5)),
                              blurRadius: 4 + (_glowIntensity.value * 14),
                              offset: const Offset(1.5, -1.5)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'CONNECTING TO GAME CYCLES...',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00F2FE).withOpacity(0.4 + (_glowIntensity.value * 0.6)),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // PREMIUM CHARGING METRIC FOOTER (Video Jasa Look)
                    Container(
                      width: 240,
                      height: 8,
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF00F2FE).withOpacity(0.2 + (_glowIntensity.value * 0.3)),
                            width: 1.5
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF007F)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Live calculation label display
                    Text(
                      "${(_loadingProgress * 100).toInt()}% READY",
                      style: const TextStyle(
                          color: Color(0xFFFF007F),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}