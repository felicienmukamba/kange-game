import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../engine/game_run.dart';
import 'arcade_host.dart';

/// Classic snake on an 18-column grid. Swipe or arrow keys to turn.
class SnakeGame extends ArcadeGame {
  SnakeGame(this.rnd);

  static const cols = 18;

  final SeededRandom rnd;
  final sprites = EmojiSprites();
  int rows = 24;
  late List<Point<int>> body;
  Point<int> dir = const Point(1, 0);
  Point<int> _pending = const Point(1, 0);
  late Point<int> food;
  double _acc = 0;
  Offset _swipe = Offset.zero;
  bool _initialised = false;

  @override
  String get title => 'Snake 🐍';

  @override
  String get help => 'Glisse (ou flèches) pour tourner. Mange les 🍎, évite ta queue et les murs.';

  double get cell => size.width / cols;

  @override
  void layout(Size newSize) {
    super.layout(newSize);
    rows = max(10, (newSize.height / (newSize.width / cols)).floor());
    if (!_initialised) {
      _initialised = true;
      final mid = Point(cols ~/ 2, rows ~/ 2);
      body = [mid, Point(mid.x - 1, mid.y), Point(mid.x - 2, mid.y)];
      _placeFood();
    }
  }

  void _placeFood() {
    do {
      food = Point(rnd.nextInt(cols), rnd.nextInt(rows));
    } while (body.contains(food));
  }

  void _turn(Point<int> d) {
    if (d.x == -dir.x && d.y == -dir.y) return;
    _pending = d;
  }

  @override
  void onDrag(Offset delta, Offset position) {
    _swipe += delta;
    if (_swipe.distance < 18) return;
    _turn(_swipe.dx.abs() > _swipe.dy.abs() ? Point(_swipe.dx.sign.toInt(), 0) : Point(0, _swipe.dy.sign.toInt()));
    _swipe = Offset.zero;
  }

  @override
  void onTapUp() => _swipe = Offset.zero;

  @override
  void onKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) _turn(const Point(0, -1));
    if (key == LogicalKeyboardKey.arrowDown) _turn(const Point(0, 1));
    if (key == LogicalKeyboardKey.arrowLeft) _turn(const Point(-1, 0));
    if (key == LogicalKeyboardKey.arrowRight) _turn(const Point(1, 0));
  }

  @override
  void update(double dt) {
    if (!_initialised) return;
    _acc += dt;
    final step = max(0.06, 0.16 - score * 0.003);
    if (_acc < step) return;
    _acc = 0;
    dir = _pending;
    final head = Point(body.first.x + dir.x, body.first.y + dir.y);
    if (head.x < 0 || head.y < 0 || head.x >= cols || head.y >= rows || body.contains(head)) {
      over = true;
      return;
    }
    body.insert(0, head);
    if (head == food) {
      score++;
      HapticFeedback.selectionClick();
      _placeFood();
    } else {
      body.removeLast();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!_initialised) return;
    final c = cell;
    final grid = Paint()..color = AppColors.surfaceHigh;
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y < rows; y++) {
        if ((x + y).isEven) canvas.drawRect(Rect.fromLTWH(x * c, y * c, c, c), grid);
      }
    }
    sprites.draw(canvas, '🍎', Offset((food.x + 0.5) * c, (food.y + 0.5) * c), c * 0.9);
    for (var i = 0; i < body.length; i++) {
      final p = body[i];
      final color = Color.lerp(AppColors.success, AppColors.secondary, i / max(1, body.length))!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(p.x * c + 1, p.y * c + 1, c - 2, c - 2), Radius.circular(c * 0.3)),
        Paint()..color = color,
      );
    }
  }

  @override
  GameOutcome outcome() => GameOutcome(
        score: score,
        rating: GameOutcome.ratingOf(score / 30),
        won: score >= 20,
        summary: 'Longueur ${score + 3} · $score 🍎',
      );

  @override
  void dispose() {
    sprites.dispose();
    super.dispose();
  }
}
