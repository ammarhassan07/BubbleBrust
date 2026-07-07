import 'package:flutter/material.dart';

class BubbleParticle {
  Offset position;
  Offset velocity;
  Color color;
  double radius;
  double opacity = 1.0;
  double maxLifetime = 1.0; // Seconds to live
  double currentLifetime = 0.0;

  BubbleParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
  });

  // Returns false when particle should be destroyed
  bool update(double dt) {
    position += velocity;
    // Add a tiny bit of gravity simulation to make shards drop
    velocity = Offset(velocity.dx, velocity.dy + 0.15);
    currentLifetime += dt;
    opacity = (1.0 - (currentLifetime / maxLifetime)).clamp(0.0, 1.0);
    return currentLifetime < maxLifetime;
  }
}