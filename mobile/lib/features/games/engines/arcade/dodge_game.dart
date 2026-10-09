import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/seeded_random.dart';
import '../../engine/game_run.dart';
import 'arcade_host.dart';

/// Drag the player left / right.
/// * default — dodge falling objects, survive as long as possible (`time`: survive that long),
/// * `collect` — catch the coins, avoid the bombs (45 s),
/// * `virus` — avoid the 🦠, collect the 💉 to stay healthy.
class DodgeGame extends ArcadeGame {
  DodgeGame(this.rnd, {this.variant, this.surviveSeconds, this.hardcore = false});

  final SeededRandom rnd;
  final String? variant;
  final int? surviveSeconds;
  final bool hardcore;
  final sprites = EmojiSprites();
  double x = 0;
  final List<_Drop> _drops = [];
  double _spawn = 0;
  int caught = 0;
  int lives = 3;

  static const playerSize = 46.0;

  bool get collect => variant == 'collect' || variant == 'virus';

  @override
  double? get timeLimit => collect ? 45 : surviveSeconds?.toDouble();

  @override
  String get title => switch (variant) {
        'collect' => 'Attrape tout 🪙',
        'virus' => 'Mode virus 🦠',
        _ => surviveSeconds == null ? 'Esquive ☄️' : 'Survis ${surviveSeconds}s ⏱️',
      };

  @override
  String get help => collect ? 'Glisse pour attraper les bons objets, évite les mauvais. 3 vies.' : 'Glisse pour esquiver. Un seul contact et c\'est fini !';

  @override
  void layout(Size newSize) {
    if (size == Size.zero) x = newSize.width / 2;
    super.layout(newSize);
  }

  @override
  void onDrag(Offset delta, Offset position) => x = (x + delta.dx).clamp(playerSize / 2, size.width - playerSize / 2);

  @override
  void onTapDown(Offset position) => x = position.dx.clamp(playerSize / 2, size.width - playerSize / 2);

  @override
  void onKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft) x = max(playerSize / 2, x - 40);
    if (key == LogicalKeyboardKey.arrowRight) x = min(size.width - playerSize / 2, x + 40);
  }

  @override
  void update(double dt) {
    if (size == Size.zero) return;
    final intensity = 1 + elapsed / (hardcore ? 10 : 20);
    if (!collect) score = (elapsed * 10).floor();

    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = max(0.12, 0.7 / intensity);
      final good = collect && rnd.nextInt(3) != 0;
      final emoji = switch (variant) {
        'virus' => good ? '💉' : '🦠',
        'collect' => good ? '🪙' : '💣',
        _ => ['☄️', '🪨', '⚡'][rnd.nextInt(3)],
      };
      _drops.add(_Drop(rnd.nextDouble() * size.width, -30, (180 + rnd.nextDouble() * 160) * intensity, emoji, good));
    }
    final playerY = size.height - playerSize;
    for (final d in _drops) {
      d.y += d.speed * dt;
      if ((Offset(d.x, d.y) - Offset(x, playerY)).distance < playerSize * 0.7) {
        d.y = size.height + 100;
        if (d.good) {
          caught++;
          score += 10;
          HapticFeedback.selectionClick();
        } else if (collect) {
          lives--;
          HapticFeedback.heavyImpact();
          if (lives <= 0) over = true;
        } else {
          over = true;
        }
      }
    }
    _drops.removeWhere((d) => d.y > size.height + 40);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _drops) {
      sprites.draw(canvas, d.emoji, Offset(d.x, d.y), 32);
    }
    sprites.draw(canvas, collect ? '🧺' : '🛸', Offset(x, size.height - playerSize), playerSize);
    if (collect) {
      for (var i = 0; i < lives; i++) {
        sprites.draw(canvas, '❤️', Offset(20 + i * 26.0, 20), 20);
      }
    }
  }

  @override
  GameOutcome outcome() {
    if (collect) {
      return GameOutcome(
        score: score,
        rating: GameOutcome.ratingOf(caught / 40),
        won: lives > 0,
        summary: '$caught objets attrapés',
      );
    }
    final seconds = elapsed.toStringAsFixed(1);
    final goal = surviveSeconds;
    return GameOutcome(
      score: score,
      rating: GameOutcome.ratingOf(elapsed / (goal ?? 60)),
      won: goal != null ? elapsed >= goal : elapsed >= 45,
      summary: goal != null && elapsed >= goal ? 'Survécu $goal s ! 🏆' : 'Survécu $seconds s',
    );
  }

  @override
  void dispose() {
    sprites.dispose();
    super.dispose();
  }
}

class _Drop {
  _Drop(this.x, this.y, this.speed, this.emoji, this.good);

  final double x;
  double y;
  final double speed;
  final String emoji;
  final bool good;
}
