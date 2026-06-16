import 'package:flutter/material.dart';
import '../theme.dart';

/// The 6 playable tile types: 3 primaries + 3 two-color combos.
enum TileKind { red, green, blue, yellow, cyan, magenta }

extension TileKindData on TileKind {
  /// Columns that must be pressed. 0 = Red, 1 = Green, 2 = Blue.
  Set<int> get required {
    switch (this) {
      case TileKind.red:
        return {0};
      case TileKind.green:
        return {1};
      case TileKind.blue:
        return {2};
      case TileKind.yellow:
        return {0, 1};
      case TileKind.cyan:
        return {1, 2};
      case TileKind.magenta:
        return {0, 2};
    }
  }

  bool get isCombo => required.length > 1;

  Color get color {
    switch (this) {
      case TileKind.red:
        return RgbColors.red;
      case TileKind.green:
        return RgbColors.green;
      case TileKind.blue:
        return RgbColors.blue;
      case TileKind.yellow:
        return RgbColors.yellow;
      case TileKind.cyan:
        return RgbColors.cyan;
      case TileKind.magenta:
        return RgbColors.magenta;
    }
  }

  /// Left-most and right-most column the tile visually spans.
  int get spanLeft => required.reduce((a, b) => a < b ? a : b);
  int get spanRight => required.reduce((a, b) => a > b ? a : b);
}

class Tile {
  Tile({required this.kind, this.y = -0.1});
  final TileKind kind;

  /// Normalized vertical center (0 top .. 1 bottom).
  double y;

  bool resolved = false;
}
