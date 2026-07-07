import 'dart:math';
import 'package:flutter/material.dart';
import 'helpers/grid_manager.dart';
import 'helpers/collision_system.dart';

class BubbleGame extends CustomPainter {
  final GridManager gridManager;
  final CollisionSystem collisionSystem;
  final Offset? touchPosition;
  final Offset projectilePos;
  final Offset? projectileVelocity;
  final Color projectileColor;
  final Color nextProjectileColor;
  final List<dynamic> particles;

  BubbleGame({
    required this.gridManager,
    required this.collisionSystem,
    required this.touchPosition,
    required this.projectilePos,
    required this.projectileVelocity,
    required this.projectileColor,
    required this.nextProjectileColor,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double gameWidth = gridManager.bubbleRadius * 2 * gridManager.cols;
    Offset cannonCenter = Offset(gameWidth / 2, (gridManager.rowHeight * gridManager.rows) + 55);

    double angle = -pi / 2;
    if (touchPosition != null) {
      Offset direction = touchPosition! - cannonCenter;
      if (direction.dy < 0) {
        angle = atan2(direction.dy, direction.dx);
      }
    }

    // 1. LASER PATH GUIDELINE — drawn FIRST so it appears BEHIND bubbles
    if (touchPosition != null && projectileVelocity == null) {
      final laserPaint = Paint()
        ..color = projectileColor.withOpacity(0.55)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      double dashLength = 12.0;
      double spaceLength = 10.0;

      // Wall-bounce ray march: tracks current position + direction
      double rayX = cannonCenter.dx;
      double rayY = cannonCenter.dy;
      double dirX = cos(angle);
      double dirY = sin(angle);

      // Advance past the cannon barrel so line starts cleanly
      double startOffset = 45.0;
      rayX += dirX * startOffset;
      rayY += dirY * startOffset;

      double totalDashBudget = dashLength * 22 + spaceLength * 21; // max ray length
      double distTravelled = 0.0;
      bool inDash = true;
      double segRemain = dashLength;

      double curX = rayX;
      double curY = rayY;

      bool hitBubble = false;
      Offset hitPoint = Offset.zero;

      while (distTravelled < totalDashBudget) {
        // ── Check if current ray tip is inside any existing grid bubble ──
        bool bubbleCollision = false;
        for (int r = 0; r < gridManager.rows && !bubbleCollision; r++) {
          for (int c = 0; c < gridManager.cols && !bubbleCollision; c++) {
            if (gridManager.grid[r][c] != null) {
              Offset bc = gridManager.getBubbleCenter(r, c);
              double dx = curX - bc.dx;
              double dy = curY - bc.dy;
              double collisionDist = gridManager.bubbleRadius * 1.85;
              if (dx * dx + dy * dy <= collisionDist * collisionDist) {
                hitBubble = true;
                hitPoint = Offset(curX, curY);
                bubbleCollision = true;
              }
            }
          }
        }
        if (bubbleCollision) break;

        // How far until we hit a wall or the top?
        double tLeft   = dirX < 0 ? (gridManager.bubbleRadius - curX) / dirX : double.infinity;
        double tRight  = dirX > 0 ? (gameWidth - gridManager.bubbleRadius - curX) / dirX : double.infinity;
        double tTop    = dirY < 0 ? (gridManager.bubbleRadius - curY) / dirY : double.infinity;
        double tWall   = [tLeft, tRight].reduce(min);
        double tBounce = min(tWall, tTop);

        double stepDist = min(segRemain, min(tBounce, totalDashBudget - distTravelled));

        double nextX = curX + dirX * stepDist;
        double nextY = curY + dirY * stepDist;

        if (inDash) {
          canvas.drawLine(Offset(curX, curY), Offset(nextX, nextY), laserPaint);
        }

        distTravelled += stepDist;
        segRemain -= stepDist;

        // Hit the top ceiling — stop
        if (stepDist >= tTop - 0.01 && tTop <= tWall) break;

        // Hit a side wall — reflect horizontal direction
        if (stepDist >= tWall - 0.01 && tWall < tTop) {
          dirX = -dirX;
          // Clamp to wall boundary
          curX = dirX > 0 ? gridManager.bubbleRadius : gameWidth - gridManager.bubbleRadius;
          curY = nextY;
        } else {
          curX = nextX;
          curY = nextY;
        }

        if (segRemain <= 0.01) {
          // Toggle dash/space
          inDash = !inDash;
          segRemain = inDash ? dashLength : spaceLength;
        }
      }

      // Draw a small impact glow dot where the ray hit a bubble
      if (hitBubble) {
        final impactPaint = Paint()
          ..color = projectileColor.withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(hitPoint, 6.0, impactPaint);
        final impactCorePaint = Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(hitPoint, 3.0, impactCorePaint);
      }
    }

    // 2. GLOSSY BUBBLES GRID RENDERING — drawn AFTER laser so bubbles appear on top
    for (int r = 0; r < gridManager.rows; r++) {
      for (int c = 0; c < gridManager.cols; c++) {
        Color? bubbleColor = gridManager.grid[r][c];
        if (bubbleColor != null) {
          Offset center = gridManager.getBubbleCenter(r, c);

          final shadowPaint = Paint()
            ..color = bubbleColor.withOpacity(0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawCircle(center, gridManager.bubbleRadius + 1, shadowPaint);

          final bubblePaint = Paint()
            ..color = bubbleColor
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, gridManager.bubbleRadius - 1, bubblePaint);

          final highlightPaint = Paint()
            ..color = Colors.white.withOpacity(0.38)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(
            Offset(center.dx - gridManager.bubbleRadius * 0.32, center.dy - gridManager.bubbleRadius * 0.32),
            gridManager.bubbleRadius * 0.22,
            highlightPaint,
          );
        }
      }
    }

    // 3. DRAW ROTATING CANNON MECHANICAL WEAPON
    canvas.save();
    canvas.translate(cannonCenter.dx, cannonCenter.dy);
    canvas.rotate(angle + pi / 2);

    final barrelPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final barrelStrokePaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Rect barrelRect = Rect.fromLTWH(-16, -42, 32, 42);
    canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(8)), barrelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(8)), barrelStrokePaint);

    final corePaint = Paint()
      ..color = projectileColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(-4, -34, 8, 24), corePaint);

    canvas.restore();

    // 4. METALLIC BASE POD WHEEL
    final housingPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final housingNeonPaint = Paint()
      ..color = const Color(0xFF00F2FE).withOpacity(0.3)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(cannonCenter, 34, housingPaint);
    canvas.drawCircle(cannonCenter, 34, housingNeonPaint);

    // 5. PROJECTILE BALL
    Offset currentBallPos = projectileVelocity == null ? cannonCenter : projectilePos;

    final projectilePaint = Paint()
      ..color = projectileColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(currentBallPos, gridManager.bubbleRadius - 0.5, projectilePaint);

    final projHighlight = Paint()..color = Colors.white.withOpacity(0.42);
    canvas.drawCircle(
      Offset(currentBallPos.dx - gridManager.bubbleRadius * 0.3, currentBallPos.dy - gridManager.bubbleRadius * 0.3),
      gridManager.bubbleRadius * 0.22,
      projHighlight,
    );

    // 6. POP PARTICLES
    for (var particle in particles) {
      final particlePaint = Paint()
        ..color = particle.color.withOpacity(particle.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particle.position, particle.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}