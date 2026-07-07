import 'dart:math';
import 'package:flutter/material.dart';

class GridManager {
  final int rows = 12;
  final int cols = 8;
  final double bubbleRadius;
  final double rowHeight;
  late List<List<Color?>> grid;

  GridManager({required this.bubbleRadius})
      : rowHeight = bubbleRadius * sqrt(3) {
    _initGrid();
  }

  void _initGrid() {
    // Standard rainbow colors for bubbles
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
    Random random = Random();

    // Fill the top 5 rows with random colored bubbles, leave the rest empty
    grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        if (r < 5) {
          return colors[random.nextInt(colors.length)];
        }
        return null;
      });
    });
  }

  // Get pixel center coordinate for a grid position (row, col)
  Offset getBubbleCenter(int row, int col) {
    double x = col * (bubbleRadius * 2) + bubbleRadius;
    // Shift odd rows right by the radius to create the hexagonal nesting effect
    if (row % 2 != 0) {
      x += bubbleRadius;
    }
    double y = row * rowHeight + bubbleRadius;
    return Offset(x, y);
  }

  // Find closest grid position for a floating pixel coordinate
  Point<int> getClosestGridPosition(Offset position) {
    int closestRow = 0;
    int closestCol = 0;
    double minDistance = double.infinity;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        Offset center = getBubbleCenter(r, c);
        double dist = (position - center).distance;
        if (dist < minDistance) {
          minDistance = dist;
          closestRow = r;
          closestCol = c;
        }
      }
    }
    return Point(closestRow, closestCol);
  }

  // Returns valid neighboring cells in a hexagonal grid (up to 6 neighbors)
  List<Point<int>> getNeighbors(int row, int col) {
    List<Point<int>> neighbors = [];
    List<Point<int>> offsets = row % 2 == 0
        ? const [Point(-1, -1), Point(-1, 0), Point(0, -1), Point(0, 1), Point(1, -1), Point(1, 0)]
        : const [Point(-1, 0), Point(-1, 1), Point(0, -1), Point(0, 1), Point(1, 0), Point(1, 1)];

    for (var offset in offsets) {
      int nr = row + offset.x;
      int nc = col + offset.y;
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        // Corrected from .push() to .add()
        neighbors.add(Point(nr, nc));
      }
    }
    return neighbors;
  }
}