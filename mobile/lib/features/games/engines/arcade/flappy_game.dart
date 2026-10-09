import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../engine/game_run.dart';
import 'arcade_host.dart';

/// Flappy-style: tap to flap through the gaps.
class FlappyGame extends ArcadeGame {
  FlappyGame(this.rnd);

  final SeededRandom rnd;
  final sprites = EmojiSprites();
  double y = 0, vy = 0;
  final List<_Pipe> _pipes = [];
  double _spawn = 0;

  static const gravity = 1500.0;
  static const flap = -480.0;
  static const birdX = 90.0;
  static const birdR = 18.0;
  static const pipeW = 64.0;

  @override
  String get title => 'Flappy 🐤';

  @override
  String get help => 'Touche pour battre des ailes. Passe entre les tuyaux.';

  @override
  void layout(Size newSize) {
    if (size == Size.zero) y = newSize.height / 2;
    super.layout(newSize);
  }

  @override
  void onTapDown(Offset position) {
    vy = flap;
    HapticFeedback.selectionClick();
  }

  @override
  void onKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.arrowUp) onTapDown(Offset.zero);
  }

  @override
  void update(double dt) {
    if (size == Size.zero) return;
    vy += gravity * dt;
    y += vy * dt;
    final speed = 170.0 + score * 4;
    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = 1.55;
      final gap = (size.height * 0.28).clamp(140.0, 220.0);
      final top = 60 + rnd.nextDouble() * (size.height - gap - 120);
      _pipes.add(_Pipe(size.width + pipeW, top, gap));
    }
    for (final p in _pipes) {
      p.x -= speed * dt;
      if (!p.passed && p.x + pipeW < birdX) {
        p.passed = true;
        score++;
      }
    }
    _pipes.removeWhere((p) => p.x < -pipeW);
    if (y - birdR < 0 || y + birdR > size.height) over = true;
    for (final p in _pipes) {
      final hitsX = birdX + birdR > p.x && birdX - birdR < p.x + pipeW;
      if (hitsX && (y - birdR < p.top || y + birdR > p.top + p.gap)) over = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()..color = AppColors.success;
    for (final p in _pipes) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.x, 0, pipeW, p.top), const Radius.circular(8)), pipePaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(p.x, p.top + p.gap, pipeW, size.height - p.top - p.gap), const Radius.circular(8)),
        pipePaint,
      );
    }
    canvas.save();
    canvas.translate(birdX, y);
    canvas.rotate((vy / 900).clamp(-0.5, 0.9));
    sprites.draw(canvas, '🐤', Offset.zero, 36);
    canvas.restore();
  }

  @override
  GameOutcome outcome() => GameOutcome(
        score: score,
        rating: GameOutcome.ratingOf(score / 25),
        won: score >= 15,
        summary: '$score tuyau${score > 1 ? 'x' : ''} franchi${score > 1 ? 's' : ''}',
      );

  @override
  void dispose() {
    sprites.dispose();
    super.dispose();
  }
}

class _Pipe {
  _Pipe(this.x, this.top, this.gap);

  double x;
  final double top;
  final double gap;
  bool passed = false;
}
