import 'dart:math';
import 'package:flutter/material.dart';
import 'grid_manager.dart';

class CollisionSystem {
  final GridManager gridManager;
  CollisionSystem({required this.gridManager});

  // Check if a projectile is touching any existing bubble on the grid
  bool checkCollision(Offset projectilePos, double radius) {
    for (int r = 0; r < gridManager.rows; r++) {
      for (int c = 0; c < gridManager.cols; c++) {
        if (gridManager.grid[r][c] != null) {
          Offset targetPos = gridManager.getBubbleCenter(r, c);
          if ((projectilePos - targetPos).distance <= radius * 2 - 2) {
            return true;
          }
        }
      }
    }
    // Also collide if it reaches the absolute top ceiling
    if (projectilePos.dy <= radius) return true;
    return false;
  }

  // BFS Algorithm to find and clear matching connected colors
  void processPop(int startRow, int startCol, Color targetColor) {
    List<Point<int>> matches = [];
    List<Point<int>> queue = [Point(startRow, startCol)];
    Set<String> visited = {"$startRow,$startCol"};

    while (queue.isNotEmpty) {
      Point<int> current = queue.removeAt(0);
      matches.add(current);

      for (var neighbor in gridManager.getNeighbors(current.x, current.y)) {
        String key = "${neighbor.x},${neighbor.y}";
        if (!visited.contains(key) && gridManager.grid[neighbor.x][neighbor.y] == targetColor) {
          visited.add(key);
          queue.add(neighbor);
        }
      }
    }

    // Classic Rule: Only clear if 3 or more bubbles match
    if (matches.length >= 3) {
      for (var point in matches) {
        gridManager.grid[point.x][point.y] = null;
      }
      dropOrphans();
    }
  }

  // Scan from top down to drop hanging unattached bubbles
  void dropOrphans() {
    Set<String> connectedToCeiling = {};
    List<Point<int>> queue = [];

    // Start with all top row bubbles
    for (int c = 0; c < gridManager.cols; c++) {
      if (gridManager.grid[0][c] != null) {
        queue.add(Point(0, c));
        connectedToCeiling.add("0,$c");
      }
    }

    // Traverse downward
    while (queue.isNotEmpty) {
      Point<int> current = queue.removeAt(0);
      for (var neighbor in gridManager.getNeighbors(current.x, current.y)) {
        String key = "${neighbor.x},${neighbor.y}";
        if (!connectedToCeiling.contains(key) && gridManager.grid[neighbor.x][neighbor.y] != null) {
          connectedToCeiling.add(key);
          queue.add(neighbor);
        }
      }
    }

    // Wipe any bubble not connected to the ceiling root
    for (int r = 0; r < gridManager.rows; r++) {
      for (int c = 0; c < gridManager.cols; c++) {
        if (gridManager.grid[r][c] != null && !connectedToCeiling.contains("$r,$c")) {
          gridManager.grid[r][c] = null; // Drop bubble
        }
      }
    }
  }
}