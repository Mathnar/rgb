import 'package:flutter_test/flutter_test.dart';
import 'package:rgb/game/game_config.dart';
import 'package:rgb/game/game_engine.dart';
import 'package:rgb/game/tile.dart';

void main() {
  GameEngine playing() => GameEngine()..start();

  Tile place(GameEngine e, TileKind kind) {
    final t = Tile(kind: kind, y: GameConfig.hitLineY);
    e.tiles
      ..clear()
      ..add(t);
    return t;
  }

  test('single color in the hit zone resolves with one press', () {
    final e = playing();
    place(e, TileKind.red);
    expect(e.handlePress(0), PressResult.hit);
    expect(e.score, 1);
  });

  test('wrong column in the hit zone ends the game', () {
    final e = playing();
    place(e, TileKind.red);
    expect(e.handlePress(1), PressResult.wrong);
    expect(e.state, GameState.gameOver);
  });

  test('combo needs both columns held; first press is not a mistake', () {
    final e = playing();
    place(e, TileKind.yellow); // requires {0,1}
    expect(e.handlePress(0), PressResult.none); // partial, no penalty
    expect(e.state, GameState.playing);
    expect(e.handlePress(1), PressResult.combo); // completes
    expect(e.score, GameConfig.pointsCombo);
  });

  test('holding one column while tapping another resolves both tiles', () {
    final e = playing();
    e.tiles
      ..clear()
      ..add(Tile(kind: TileKind.red, y: GameConfig.hitLineY))
      ..add(Tile(kind: TileKind.blue, y: GameConfig.hitLineY));
    expect(e.handlePress(0), PressResult.hit); // red, still holding 0
    expect(e.handlePress(2), PressResult.hit); // blue resolves, 0 still held
    expect(e.state, GameState.playing);
    expect(e.score, 2);
  });

  test('idle tap with empty hit zone is forgiven', () {
    final e = playing();
    e.tiles.clear();
    expect(e.handlePress(0), PressResult.none);
    expect(e.state, GameState.playing);
  });

  test('a tile falling past the miss line ends the game', () {
    final e = playing();
    final t = place(e, TileKind.green);
    t.y = GameConfig.missLineY + 0.01;
    e.update(0.016);
    expect(e.state, GameState.gameOver);
  });
}
