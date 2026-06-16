import 'dart:math';
import 'package:flutter/material.dart';

/// A single glowing spark. Positions are normalized to the play field.
class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
    required this.size,
  }) : maxLife = life;

  double x, y, vx, vy;
  double life;
  final double maxLife;
  final double size;
  final Color color;

  bool get dead => life <= 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 1.4 * dt; // gravity
    vx *= 0.96;
    life -= dt;
  }

  double get t => (life / maxLife).clamp(0.0, 1.0);
}

/// Emits a burst of sparks at a point. [intensity] scales count/spread, used to
/// make 2-color combos feel chunkier and more satisfying.
List<Particle> burst({
  required double x,
  required double y,
  required List<Color> colors,
  required Random rng,
  double intensity = 1.0,
}) {
  final count = (16 * intensity).round();
  return List.generate(count, (_) {
    final angle = rng.nextDouble() * 2 * pi;
    final speed = (0.25 + rng.nextDouble() * 0.7) * intensity;
    return Particle(
      x: x,
      y: y,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed - 0.25,
      color: colors[rng.nextInt(colors.length)],
      life: 0.45 + rng.nextDouble() * 0.4,
      size: (2 + rng.nextDouble() * 3) * intensity,
    );
  });
}
