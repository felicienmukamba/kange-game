import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Perfect timing. Default: stop the sweeping cursor in the centre zone (10 rounds,
/// faster each time). Variant `hold`: hold the button for exactly the target duration.
/// Variants `beat` / `sync`: tap on the pulse.
class TimingEngine extends StatefulWidget {
  const TimingEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<TimingEngine> createState() => _TimingEngineState();
}

class _TimingEngineState extends State<TimingEngine> with SingleTickerProviderStateMixin {
  static const _rounds = 10;

  late final _rnd = widget.run.random();
  late final String? _variant = widget.run.game.cfgStr('variant');
  late final AnimationController _sweep = AnimationController(vsync: this);
  int _round = 0;
  int _score = 0;
  final List<int> _accuracies = [];
  String? _feedback;
  double _holdTarget = 1.5;
  final _holdWatch = Stopwatch();
  Timer? _next;

  bool get _hold => _variant == 'hold';

  bool get _beat => _variant == 'beat' || _variant == 'sync';

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  @override
  void dispose() {
    _next?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  void _setupRound() {
    _feedback = null;
    if (_hold) {
      _holdTarget = (10 + _rnd.nextInt(30)) / 10;
      return;
    }
    final ms = max(450, 1500 - _round * 100);
    _sweep.duration = Duration(milliseconds: ms);
    if (_beat) {
      _sweep.repeat();
    } else {
      _sweep.repeat(reverse: true);
    }
  }

  /// 0..100 accuracy for the sweep: distance of the cursor from the centre (or from the beat).
  int _sweepAccuracy() {
    final v = _sweep.value;
    final distance = _beat ? min(v, 1 - v) * 2 : (v - 0.5).abs() * 2;
    return (100 * (1 - distance)).round().clamp(0, 100);
  }

  void _record(int accuracy) {
    HapticFeedback.mediumImpact();
    final points = accuracy >= 95 ? 30 : (accuracy >= 80 ? 20 : (accuracy >= 60 ? 10 : 0));
    setState(() {
      _accuracies.add(accuracy);
      _score += points;
      _feedback = accuracy >= 95 ? '🎯 PARFAIT' : (accuracy >= 80 ? '👍 Très bien' : (accuracy >= 60 ? '😐 Moyen' : '❌ Raté'));
    });
    _next = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        final avg = _accuracies.reduce((a, b) => a + b) ~/ _accuracies.length;
        widget.run.onFinish(GameOutcome(
          score: _score,
          rating: avg,
          won: avg >= 80,
          summary: 'Précision moyenne : $avg %',
        ));
      } else {
        setState(() {
          _round++;
          _setupRound();
        });
      }
    });
  }

  void _tap() {
    if (_feedback != null || _hold) return;
    _sweep.stop();
    _record(_sweepAccuracy());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _score, round: _round, total: _rounds),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const Spacer(),
                if (_hold) ...[
                  Text('Maintiens exactement', style: Theme.of(context).textTheme.titleMedium),
                  Text('${_holdTarget.toStringAsFixed(1)} s', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900)),
                ] else
                  SizedBox(
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _sweep,
                      builder: (context, _) => CustomPaint(
                        painter: _SweepPainter(_sweep.value, beat: _beat),
                        size: const Size(double.infinity, 80),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: _feedback == null ? null : Text(_feedback!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                GestureDetector(
                  onTapDown: (_) {
                    if (_hold && _feedback == null) {
                      _holdWatch
                        ..reset()
                        ..start();
                      HapticFeedback.selectionClick();
                    } else {
                      _tap();
                    }
                  },
                  onTapUp: (_) {
                    if (!_hold || _feedback != null || !_holdWatch.isRunning) return;
                    _holdWatch.stop();
                    final held = _holdWatch.elapsedMilliseconds / 1000;
                    final error = (held - _holdTarget).abs() / _holdTarget;
                    _record((100 * (1 - error * 2)).round().clamp(0, 100));
                    setState(() => _feedback = '${held.toStringAsFixed(2)} s · $_feedback');
                  },
                  child: Container(
                    width: 170,
                    height: 170,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: Text(_hold ? 'MAINTENIR' : 'STOP', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.value, {required this.beat});

  final double value;
  final bool beat;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
    canvas.drawRRect(r, Paint()..color = AppColors.surfaceHigh);
    if (beat) {
      // A pulse that peaks at the beat (value 0/1).
      final pulse = 1 - min(value, 1 - value) * 2;
      canvas.drawCircle(size.center(Offset.zero), 10 + 26 * pulse, Paint()..color = AppColors.accent.withValues(alpha: 0.3 + 0.7 * pulse));
      return;
    }
    final zone = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.1, height: size.height);
    canvas.drawRect(zone, Paint()..color = AppColors.success.withValues(alpha: 0.4));
    final x = value * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, size.height / 2), width: 8, height: size.height), const Radius.circular(4)),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.value != value;
}
