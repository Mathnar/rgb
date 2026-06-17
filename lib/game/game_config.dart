/// Tunable gameplay + layout constants. All vertical positions are normalized
/// (0 = top of the play field, 1 = bottom) so the game scales to any screen.
class GameConfig {
  static const int columns = 3;

  /// Tile height as a fraction of the play field height.
  static const double tileHeight = 0.14;

  /// Where the player is expected to hit (center of the hit zone).
  static const double hitLineY = 0.80;

  /// Half-height of the forgiving hit window around [hitLineY].
  static const double hitTolerance = 0.13;

  /// A tile is "missed" once its center passes this point unresolved.
  static const double missLineY = 0.97;

  /// Fall speed (fraction of field per second) at the very start.
  static const double startSpeed = 0.55;

  /// Added to speed for every point scored, capped by [maxSpeed].
  static const double speedPerPoint = 0.006;
  static const double maxSpeed = 1.9;

  /// Seconds between spawns at the start, shrinking toward [minSpawnInterval].
  static const double startSpawnInterval = 1.05;
  static const double minSpawnInterval = 0.34;
  static const double spawnAccelPerPoint = 0.012;

  /// Probability that a spawned tile is a 2-color combo.
  static const double comboChance = 0.30;

  static const int pointsSingle = 1;
  static const int pointsCombo = 3;
}
