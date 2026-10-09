import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../engine/game_run.dart';
import 'arcade_host.dart';

/// Endless runner: tap to jump (double jump allowed) over obstacles; it speeds up.
class RunnerGame extends ArcadeGame {
  RunnerGame(this.rnd);

  final SeededRandom rnd;
  final sprites = EmojiSprites();
  double y = 0, vy = 0, distance = 0;
  int jumps = 0;
  final List<_Obstacle> _obstacles = [];
  double _spawn = 1;

  static const runnerX = 80.0;
  static const runnerSize = 40.0;
  static const gravity = 2300.0;
  static const jumpSpeed = -820.0;
  static const _obstacleEmojis = ['🌵', '🪨', '🔥', '🦂'];

  double get ground => size.height - 60;

  @override
  String get title => 'Runner 🏃';

  @override
  String get help => 'Touche pour sauter (double saut possible). Évite les obstacles !';

  @override
  void onTapDown(Offset position) {
    if (jumps >= 2) return;
    vy = jumpSpeed * (jumps == 0 ? 1 : 0.85);
    jumps++;
    HapticFeedback.selectionClick();
  }

  @override
  void onKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.arrowUp) onTapDown(Offset.zero);
  }

  @override
  void update(double dt) {
    if (size == Size.zero) return;
    final speed = 300 + distance / 12;
    distance += speed * dt;
    score = (distance / 50).floor();

    vy += gravity * dt;
    y += vy * dt;
    if (y > 0) {
      y = 0;
      vy = 0;
      jumps = 0;
    }

    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = 0.9 + rnd.nextDouble() * 1.1 - (distance / 40000).clamp(0, 0.5);
      final tall = rnd.nextInt(3) == 0;
      _obstacles.add(_Obstacle(size.width + 40, tall ? 64 : 40, _obstacleEmojis[rnd.nextInt(_obstacleEmojis.length)]));
    }
    for (final o in _obstacles) {
      o.x -= speed * dt;
    }
    _obstacles.removeWhere((o) => o.x < -60);

    final runner = Rect.fromCenter(center: Offset(runnerX, ground - runnerSize / 2 + y), width: runnerSize * 0.7, height: runnerSize * 0.8);
    for (final o in _obstacles) {
      final box = Rect.fromLTWH(o.x - o.size * 0.35, ground - o.size * 0.85, o.size * 0.7, o.size * 0.85);
      if (runner.overlaps(box)) over = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, ground, size.width, size.height - ground), Paint()..color = AppColors.surfaceHigh);
    final stripe = Paint()..color = AppColors.border;
    final offset = distance % 40;
    for (var x = -offset; x < size.width; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x, ground + 12, 20, 4), stripe);
    }
    for (final o in _obstacles) {
      sprites.draw(canvas, o.emoji, Offset(o.x, ground - o.size / 2), o.size);
    }
    sprites.draw(canvas, '🏃', Offset(runnerX, ground - runnerSize / 2 + y), runnerSize);
  }

  @override
  GameOutcome outcome() => GameOutcome(
        score: score,
        rating: GameOutcome.ratingOf(score / 300),
        won: score >= 200,
        summary: '$score m parcourus',
      );

  @override
  void dispose() {
    sprites.dispose();
    super.dispose();
  }
}

class _Obstacle {
  _Obstacle(this.x, this.size, this.emoji);

  double x;
  final double size;
  final String emoji;
}
