import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../engine/game_run.dart';
import 'arcade_host.dart';

/// Listens to the accelerometer when the device has one. Desktop / web without
/// motion sensors simply never emit, and games fall back to touch or keys.
mixin AccelerometerInput on ArcadeGame {
  StreamSubscription<AccelerometerEvent>? _sub;
  double ax = 0, ay = 0, az = 0;
  bool hasSensor = false;

  void listenSensors() {
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
        (e) {
          hasSensor = true;
          ax = e.x;
          ay = e.y;
          az = e.z;
          onSensor();
        },
        onError: (_) {},
        cancelOnError: true,
      );
    } catch (_) {
      // No sensor plugin on this platform.
    }
  }

  void onSensor() {}

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Tilt the phone to roll the ball onto the stars (45 s). Drag / arrow keys without a sensor.
class TiltGame extends ArcadeGame with AccelerometerInput {
  TiltGame(this.rnd) {
    listenSensors();
  }

  final SeededRandom rnd;
  final sprites = EmojiSprites();
  Offset ball = Offset.zero, velocity = Offset.zero, star = Offset.zero;
  Offset _keyPush = Offset.zero;

  static const radius = 20.0;

  @override
  double? get timeLimit => 45;

  @override
  String get title => 'Inclinaison 📱';

  @override
  String get help => 'Penche ton téléphone pour guider la bille vers les ⭐ (ou glisse le doigt).';

  @override
  void layout(Size newSize) {
    final first = size == Size.zero;
    super.layout(newSize);
    if (first) {
      ball = newSize.center(Offset.zero);
      _moveStar();
    }
  }

  void _moveStar() {
    star = Offset(40 + rnd.nextDouble() * (size.width - 80), 40 + rnd.nextDouble() * (size.height - 80));
  }

  @override
  void onDrag(Offset delta, Offset position) => velocity += delta * 6;

  @override
  void onKey(LogicalKeyboardKey key) {
    const push = 140.0;
    if (key == LogicalKeyboardKey.arrowLeft) _keyPush = const Offset(-push, 0);
    if (key == LogicalKeyboardKey.arrowRight) _keyPush = const Offset(push, 0);
    if (key == LogicalKeyboardKey.arrowUp) _keyPush = const Offset(0, -push);
    if (key == LogicalKeyboardKey.arrowDown) _keyPush = const Offset(0, push);
  }

  @override
  void update(double dt) {
    if (size == Size.zero) return;
    final accel = hasSensor ? Offset(-ax, ay) * 160 : _keyPush;
    _keyPush *= 0.9;
    velocity = (velocity + accel * dt) * pow(0.4, dt).toDouble();
    ball += velocity * dt;
    if (ball.dx < radius || ball.dx > size.width - radius) {
      velocity = Offset(-velocity.dx * 0.5, velocity.dy);
      ball = Offset(ball.dx.clamp(radius, size.width - radius), ball.dy);
    }
    if (ball.dy < radius || ball.dy > size.height - radius) {
      velocity = Offset(velocity.dx, -velocity.dy * 0.5);
      ball = Offset(ball.dx, ball.dy.clamp(radius, size.height - radius));
    }
    if ((ball - star).distance < radius + 16) {
      score++;
      HapticFeedback.lightImpact();
      _moveStar();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    sprites.draw(canvas, '⭐', star, 34);
    canvas.drawCircle(ball, radius, Paint()..color = AppColors.secondary);
    canvas.drawCircle(ball - const Offset(6, 6), radius * 0.3, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  @override
  GameOutcome outcome() => GameOutcome(
        score: score,
        rating: GameOutcome.ratingOf(score / 15),
        won: score >= 10,
        summary: '$score étoile${score > 1 ? 's' : ''} attrapée${score > 1 ? 's' : ''}',
      );

  @override
  void dispose() {
    sprites.dispose();
    super.dispose();
  }
}

/// Shake as hard as possible for 10 s. Without a sensor, tapping counts instead.
class ShakeGame extends ArcadeGame with AccelerometerInput {
  ShakeGame() {
    listenSensors();
  }

  final sprites = EmojiSprites();
  double _energy = 0;
  bool _peak = false;

  @override
  double? get timeLimit => 10;

  @override
  String get title => 'Secoue ton téléphone 📳';

  @override
  String get help => 'Secoue le plus fort possible pendant 10 secondes ! (ou tape l\'écran)';

  @override
  void onSensor() {
    if (over || !running) return;
    final g = sqrt(ax * ax + ay * ay + az * az);
    // Count a shake on each rising edge above 2 g.
    if (g > 19 && !_peak) {
      _peak = true;
      score++;
      _energy = 1;
    } else if (g < 13) {
      _peak = false;
    }
  }

  @override
  void onTapDown(Offset position) {
    if (hasSensor) return;
    score++;
    _energy = 1;
    HapticFeedback.selectionClick();
  }

  @override
  void update(double dt) => _energy = max(0, _energy - dt * 3);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final wobble = sin(elapsed * 60) * 14 * _energy;
    canvas.drawCircle(c, 90 + 20 * _energy, Paint()..color = AppColors.accent.withValues(alpha: 0.15 + 0.3 * _energy));
    sprites.draw(canvas, '📱', c + Offset(wobble, 0), 90);
  }

  @override
  GameOutcome outcome() => GameOutcome(
        score: score,
        rating: GameOutcome.ratingOf(score / 40),
        won: score >= 30,
        summary: '$score secousses en 10 s',
      );

  @override
  void dispose() {
    sprites.dispose();
    super.dispose();
  }
}
