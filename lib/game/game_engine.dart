import 'dart:math';
import 'package:flutter/foundation.dart';
import 'game_config.dart';
import 'particle.dart';
import 'tile.dart';

enum GameState { ready, playing, gameOver }

enum PressResult { none, hit, combo, wrong }

/// Pure-ish game model. Owns tiles, particles, score and the failure rules.
/// Extends [ChangeNotifier] so the painter can repaint each frame and the HUD
/// can rebuild on score changes.
class GameEngine extends ChangeNotifier {
  GameEngine({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  final List<Tile> tiles = [];
  final List<Particle> particles = [];

  GameState state = GameState.ready;
  int score = 0;
  int combo = 0; // consecutive combo streak, for flair
  double shake = 0; // decaying screen-shake amount (0..1)

  double _spawnTimer = 0;

  /// Set of columns currently held down (for combo completion checks).
  final Set<int> _held = {};

  // Effect hooks wired up by the screen (audio, haptics, etc.).
  void Function(PressResult result)? onResult;
  VoidCallback? onGameOver;

  double get speed =>
      min(GameConfig.maxSpeed, GameConfig.startSpeed + score * GameConfig.speedPerPoint);

  double get _spawnInterval => max(
        GameConfig.minSpawnInterval,
        GameConfig.startSpawnInterval - score * GameConfig.spawnAccelPerPoint,
      );

  void start() {
    tiles.clear();
    particles.clear();
    _held.clear();
    score = 0;
    combo = 0;
    shake = 0;
    _spawnTimer = 0;
    state = GameState.playing;
    _spawn(); // first tile immediately
    notifyListeners();
  }

  void reset() {
    state = GameState.ready;
    notifyListeners();
  }

  /// Bring the player back after a rewarded ad: clear any tile at or below the
  /// hit zone (so they don't instantly die again) and resume.
  void revive() {
    tiles.removeWhere((t) => t.y > GameConfig.hitLineY - GameConfig.hitTolerance);
    _held.clear();
    shake = 0;
    state = GameState.playing;
    notifyListeners();
  }

  TileKind _randomKind() {
    if (_rng.nextDouble() < GameConfig.comboChance) {
      return [TileKind.yellow, TileKind.cyan, TileKind.magenta][_rng.nextInt(3)];
    }
    return [TileKind.red, TileKind.green, TileKind.blue][_rng.nextInt(3)];
  }

  void _spawn() => tiles.add(Tile(kind: _randomKind(), y: -GameConfig.tileHeight));

  /// Advance the simulation by [dt] seconds.
  void update(double dt) {
    // Always animate particles + shake so death effects keep playing.
    for (final p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.dead);
    if (shake > 0) shake = max(0, shake - dt * 3.5);

    if (state == GameState.playing) {
      _spawnTimer += dt;
      if (_spawnTimer >= _spawnInterval) {
        _spawnTimer = 0;
        _spawn();
      }

      final v = speed;
      for (final tile in tiles) {
        if (tile.resolved) continue;
        tile.y += v * dt;
        if (tile.y > GameConfig.missLineY) {
          _fail();
          break;
        }
      }
      tiles.removeWhere((t) => t.resolved);
    }

    notifyListeners();
  }

  bool _inHitZone(Tile t) =>
      (t.y - GameConfig.hitLineY).abs() <= GameConfig.hitTolerance;

  /// Called on each new pointer-down. [column] is the freshly pressed lane.
  PressResult handlePress(int column) {
    if (state != GameState.playing) return PressResult.none;
    _held.add(column);

    final candidates = tiles
        .where((t) => !t.resolved && _inHitZone(t))
        .toList()
      ..sort((a, b) => b.y.compareTo(a.y)); // lowest (most urgent) first

    if (candidates.isEmpty) {
      // Forgiving: idle taps with nothing in the zone do nothing.
      return PressResult.none;
    }

    // Is the pressed column relevant to anything in the zone?
    final relevant =
        candidates.where((t) => t.kind.required.contains(column)).toList();
    if (relevant.isEmpty) {
      _fail();
      return PressResult.wrong;
    }

    // Take the most urgent tile needing this column; complete it if all of its
    // required columns are currently held.
    final target = relevant.first;
    if (target.kind.required.every(_held.contains)) {
      return _resolve(target);
    }
    // Partial combo press — wait for the other column. No penalty.
    return PressResult.none;
  }

  void releaseColumn(int column) => _held.remove(column);

  PressResult _resolve(Tile tile) {
    tile.resolved = true;
    final isCombo = tile.kind.isCombo;
    score += isCombo ? GameConfig.pointsCombo : GameConfig.pointsSingle;
    combo = isCombo ? combo + 1 : 0;

    final cx = _tileCenterX(tile);
    final colors = isCombo
        ? [tile.kind.color, ...tile.kind.required.map(_columnColor)]
        : [tile.kind.color];
    particles.addAll(burst(
      x: cx,
      y: GameConfig.hitLineY,
      colors: colors,
      rng: _rng,
      intensity: isCombo ? 1.9 : 1.0,
    ));
    if (isCombo) shake = min(1.0, shake + 0.6);

    final result = isCombo ? PressResult.combo : PressResult.hit;
    onResult?.call(result);
    notifyListeners();
    return result;
  }

  void _fail() {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    shake = 1.0;
    onResult?.call(PressResult.wrong);
    onGameOver?.call();
    notifyListeners();
  }

  double _tileCenterX(Tile tile) {
    final left = tile.kind.spanLeft;
    final right = tile.kind.spanRight;
    final colW = 1.0 / GameConfig.columns;
    return (left + right + 1) / 2 * colW;
  }

  static const _colColors = [TileKind.red, TileKind.green, TileKind.blue];
  Color _columnColor(int c) => _colColors[c].color;
}
