import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import 'arcade_host.dart';

/// Stack tower: a block slides back and forth; tap to drop it. The overhang is
/// cut off; miss completely and the tower is done. Perfect drops keep the width.
class StackGame extends ArcadeGame {
  final List<Rect> blocks = [];
  double _x = 0, _dir = 1, _width = 0;
  int perfects = 0;
  double _camera = 0;

  static const blockH = 28.0;

  @override
  String get title => 'Tour infinie 🏗️';

  @override
  String get help => 'Touche pour poser le bloc. Aligne-le parfaitement !';

  @override
  void layout(Size newSize) {
    super.layout(newSize);
    if (blocks.isEmpty) {
      _width = newSize.width * 0.6;
      blocks.add(Rect.fromLTWH((newSize.width - _width) / 2, newSize.height - blockH, _width, blockH));
      _x = 0;
    }
  }

  double get _speed => 220 + blocks.length * 12;

  @override
  void update(double dt) {
    if (blocks.isEmpty) return;
    _x += _dir * _speed * dt;
    if (_x <= 0) {
      _x = 0;
      _dir = 1;
    } else if (_x + _width >= size.width) {
      _x = size.width - _width;
      _dir = -1;
    }
    final target = max(0.0, (blocks.length - 8) * blockH);
    _camera += (target - _camera) * min(1, dt * 6);
  }

  @override
  void onTapDown(Offset position) {
    if (over || blocks.isEmpty) return;
    final top = blocks.last;
    final left = max(_x, top.left);
    final right = min(_x + _width, top.right);
    if (right <= left) {
      over = true;
      return;
    }
    var placed = Rect.fromLTRB(left, top.top - blockH, right, top.top);
    if ((placed.width - top.width).abs() < 6) {
      placed = Rect.fromLTWH(top.left, top.top - blockH, top.width, blockH);
      perfects++;
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    blocks.add(placed);
    _width = placed.width;
    score = blocks.length - 1;
    _x = _dir > 0 ? 0 : size.width - _width;
  }

  @override
  void onKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) onTapDown(Offset.zero);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(0, _camera);
    for (var i = 0; i < blocks.length; i++) {
      final color = AppColors.palette[i % AppColors.palette.length];
      canvas.drawRRect(RRect.fromRectAndRadius(blocks[i], const Radius.circular(4)), Paint()..color = color);
    }
    if (!over && blocks.isNotEmpty) {
      final y = blocks.last.top - blockH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(_x, y, _width, blockH), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
    canvas.restore();
  }

  @override
  GameOutcome outcome() => GameOutcome(
        score: score,
        rating: GameOutcome.ratingOf(score / 30),
        won: score >= 20,
        summary: 'Tour de $score étages',
        details: ['Poses parfaites : $perfects'],
      );
}
