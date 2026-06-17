import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'game_config.dart';
import 'game_engine.dart';
import 'tile.dart';

/// Draws the falling-tiles play field with neon glow + particles.
class GamePainter extends CustomPainter {
  GamePainter(this.engine) : super(repaint: engine);
  final GameEngine engine;

  static final Random _rng = Random();
  static const _colColors = [RgbColors.red, RgbColors.green, RgbColors.blue];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (engine.shake > 0) {
      final mag = engine.shake * 10;
      canvas.translate(
        (_rng.nextDouble() - 0.5) * mag,
        (_rng.nextDouble() - 0.5) * mag,
      );
    }

    final colW = size.width / GameConfig.columns;

    _paintColumns(canvas, size, colW);
    _paintHitLine(canvas, size, colW);
    _paintTiles(canvas, size, colW);
    _paintParticles(canvas, size);

    canvas.restore();
  }

  void _paintColumns(Canvas canvas, Size size, double colW) {
    final sep = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (var c = 0; c < GameConfig.columns; c++) {
      final rect = Rect.fromLTWH(c * colW, 0, colW, size.height);
      final glow = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _colColors[c].withOpacity(0.0),
            _colColors[c].withOpacity(0.06),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, glow);
      if (c > 0) {
        canvas.drawLine(Offset(c * colW, 0), Offset(c * colW, size.height), sep);
      }
    }
  }

  void _paintHitLine(Canvas canvas, Size size, double colW) {
    final y = GameConfig.hitLineY * size.height;
    final line = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);

    // Target rings centered in each column to invite the tap.
    for (var c = 0; c < GameConfig.columns; c++) {
      final cx = (c + 0.5) * colW;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _colColors[c].withOpacity(0.25);
      canvas.drawCircle(Offset(cx, y), colW * 0.30, ring);
    }
  }

  void _paintTiles(Canvas canvas, Size size, double colW) {
    final th = GameConfig.tileHeight * size.height;
    for (final tile in engine.tiles) {
      if (tile.resolved) continue;
      final left = tile.kind.spanLeft * colW;
      final width = (tile.kind.spanRight - tile.kind.spanLeft + 1) * colW;
      final cy = tile.y * size.height;
      final rect = Rect.fromLTWH(
        left + 6,
        cy - th / 2,
        width - 12,
        th,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

      // Outer glow.
      final glow = Paint()
        ..color = tile.kind.color.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawRRect(rrect, glow);

      // Body gradient.
      final body = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tile.kind.color,
            Color.lerp(tile.kind.color, Colors.black, 0.35)!,
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, body);

      // Combo tiles get a bright inner stroke + "2x" hint to feel special.
      if (tile.kind.isCombo) {
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withOpacity(0.85);
        canvas.drawRRect(rrect.deflate(3), stroke);
        _comboLabel(canvas, rect, tile.kind);
      }
    }
  }

  void _comboLabel(Canvas canvas, Rect rect, TileKind kind) {
    final tp = TextPainter(
      text: const TextSpan(
        text: '×2',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (final p in engine.particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (4 * p.t).clamp(0.5, 6));
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * (0.5 + p.t),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => false; // repaint via Listenable
}
