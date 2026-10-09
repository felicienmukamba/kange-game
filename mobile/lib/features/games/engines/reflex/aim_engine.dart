import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Tap the targets before they vanish; avoid the bombs. 30 seconds.
/// Variants: `moving` (targets drift), `penalty` (⚽ in goal corners).
class AimEngine extends StatefulWidget {
  const AimEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<AimEngine> createState() => _AimEngineState();
}

class _AimEngineState extends State<AimEngine> with SingleTickerProviderStateMixin {
  late final _AimLoop _loop = _AimLoop(widget.run.random(), widget.run.game.cfgStr('variant'), widget.run.timeLimit(30))
    ..onEnd = _finish;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loop.attach(this);
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  void _finish() {
    widget.run.onFinish(GameOutcome(
      score: _loop.score,
      rating: GameOutcome.ratingOf(_loop.score / 300),
      won: _loop.hits >= 25,
      summary: '${_loop.hits} cibles touchées',
      details: ['Bombes : ${_loop.bombs}', 'Ratées : ${_loop.missed}'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return ReadyCountdown(
        title: 'Touche les cibles 🎯',
        subtitle: 'Évite les bombes 💣',
        onDone: () {
          setState(() => _ready = true);
          _loop.start();
        },
      );
    }
    return Column(
      children: [
        ListenableBuilder(
          listenable: _loop,
          builder: (context, _) => GameHud(
            score: _loop.score,
            timer: ProgressBarTimer(fraction: _loop.remaining / _loop.duration),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: LayoutBuilder(
              builder: (context, box) {
                _loop.size = box.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _loop.tap(d.localPosition),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _AimPainter(_loop), size: box.biggest),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Target {
  _Target(this.pos, this.velocity, this.bomb, this.life);

  Offset pos;
  final Offset velocity;
  final bool bomb;
  double life;
}

class _AimLoop extends GameLoop {
  _AimLoop(this.rnd, this.variant, Duration limit) : duration = limit.inMilliseconds / 1000;

  final SeededRandom rnd;
  final String? variant;
  final double duration;
  late double remaining = duration;
  Size size = Size.zero;
  final List<_Target> targets = [];
  double _spawn = 0;
  int score = 0, hits = 0, bombs = 0, missed = 0;
  VoidCallback? onEnd;
  bool _ended = false;

  double get radius => 34;

  @override
  void tick(double dt) {
    remaining -= dt;
    if (remaining <= 0 && !_ended) {
      _ended = true;
      stop();
      onEnd?.call();
      return;
    }
    final progress = 1 - remaining / duration;
    _spawn -= dt;
    if (_spawn <= 0 && size != Size.zero) {
      _spawn = lerpDouble(0.9, 0.35, progress)!;
      final bomb = variant != 'penalty' && rnd.nextInt(5) == 0;
      Offset pos;
      if (variant == 'penalty') {
        final corners = [
          Offset(radius * 1.5, radius * 1.5),
          Offset(size.width - radius * 1.5, radius * 1.5),
          Offset(radius * 1.5, size.height / 2),
          Offset(size.width - radius * 1.5, size.height / 2),
          Offset(size.width / 2, radius * 1.5),
        ];
        pos = corners[rnd.nextInt(corners.length)];
      } else {
        pos = Offset(radius + rnd.nextDouble() * (size.width - 2 * radius), radius + rnd.nextDouble() * (size.height - 2 * radius));
      }
      final speed = variant == 'moving' ? 60 + progress * 120 : 0.0;
      final angle = rnd.nextDouble() * pi * 2;
      targets.add(_Target(pos, Offset(cos(angle), sin(angle)) * speed, bomb, lerpDouble(1.6, 0.9, progress)!));
    }
    for (final t in targets) {
      t.life -= dt;
      t.pos += t.velocity * dt;
      if (t.pos.dx < radius || t.pos.dx > size.width - radius || t.pos.dy < radius || t.pos.dy > size.height - radius) {
        t.pos = Offset(t.pos.dx.clamp(radius, size.width - radius), t.pos.dy.clamp(radius, size.height - radius));
      }
    }
    final expired = targets.where((t) => t.life <= 0).toList();
    for (final t in expired) {
      if (!t.bomb) missed++;
    }
    targets.removeWhere((t) => t.life <= 0);
  }

  void tap(Offset p) {
    if (!running) return;
    for (final t in targets.reversed) {
      if ((t.pos - p).distance <= radius * 1.15) {
        targets.remove(t);
        if (t.bomb) {
          bombs++;
          score = max(0, score - 15);
          HapticFeedback.heavyImpact();
        } else {
          hits++;
          score += 10;
          HapticFeedback.lightImpact();
        }
        notifyListeners();
        return;
      }
    }
  }
}

class _AimPainter extends CustomPainter {
  _AimPainter(this.loop) : super(repaint: loop);

  final _AimLoop loop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = loop.variant == 'penalty' ? const Color(0xFF14532D) : AppColors.surface);
    if (loop.variant == 'penalty') {
      final goal = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height * 0.62), goal);
    }
    for (final t in loop.targets) {
      final fade = t.life.clamp(0, 0.3) / 0.3;
      if (t.bomb) {
        canvas.drawCircle(t.pos, loop.radius, Paint()..color = Colors.black.withValues(alpha: fade));
        _emoji(canvas, '💣', t.pos, fade);
      } else {
        final ring = Paint()..color = AppColors.danger.withValues(alpha: fade);
        canvas.drawCircle(t.pos, loop.radius, ring);
        canvas.drawCircle(t.pos, loop.radius * 0.66, Paint()..color = Colors.white.withValues(alpha: fade));
        canvas.drawCircle(t.pos, loop.radius * 0.33, ring);
        if (loop.variant == 'penalty') _emoji(canvas, '⚽', t.pos, fade);
      }
    }
  }

  static final _cache = <String, TextPainter>{};

  void _emoji(Canvas canvas, String e, Offset at, double opacity) {
    final tp = _cache.putIfAbsent(
      e,
      () => TextPainter(text: TextSpan(text: e, style: const TextStyle(fontSize: 30)), textDirection: TextDirection.ltr)..layout(),
    );
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_AimPainter old) => false;
}
