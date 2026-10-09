import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Spam-tap: as many taps as possible in 10 s.
/// `target`: reach that many taps as fast as possible instead.
/// Variant `panic`: the button jumps around after each tap.
class TapBattleEngine extends StatefulWidget {
  const TapBattleEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<TapBattleEngine> createState() => _TapBattleEngineState();
}

class _TapBattleEngineState extends State<TapBattleEngine> {
  late final _rnd = widget.run.random();
  late final int? _target = widget.run.game.config['target'] is int ? widget.run.game.cfgInt('target', 100) : null;
  late final bool _panic = widget.run.game.cfgStr('variant') == 'panic';
  late final Duration _limit = widget.run.timeLimit(_target == null ? 10 : 30);
  bool _started = false;
  bool _done = false;
  int _taps = 0;
  Alignment _pos = Alignment.center;
  final _watch = Stopwatch();

  void _tap() {
    if (_done) return;
    if (!_started) {
      _started = true;
      _watch.start();
    }
    HapticFeedback.selectionClick();
    setState(() {
      _taps++;
      if (_panic) _pos = Alignment(_rnd.nextDouble() * 1.6 - 0.8, _rnd.nextDouble() * 1.6 - 0.8);
    });
    if (_target != null && _taps >= _target) _finish();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _watch.stop();
    final seconds = max(_watch.elapsedMilliseconds, 1) / 1000;
    if (_target != null) {
      final reached = _taps >= _target;
      widget.run.onFinish(GameOutcome(
        score: reached ? (100000 / seconds).round() : _taps,
        rating: GameOutcome.ratingOf(reached ? 12 / seconds : _taps / _target / 2),
        won: reached,
        summary: reached ? '$_target taps en ${seconds.toStringAsFixed(2)} s' : 'Seulement $_taps taps',
      ));
    } else {
      final cps = _taps / _limit.inSeconds;
      widget.run.onFinish(GameOutcome(
        score: _taps,
        rating: GameOutcome.ratingOf(cps / 9),
        won: cps >= 7,
        summary: '$_taps taps · ${cps.toStringAsFixed(1)} par seconde',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(
          score: _taps,
          timer: _started ? CountdownBar(duration: _limit, onElapsed: _finish) : const SizedBox(height: 8),
          extra: _target == null ? null : Text('Objectif $_target', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        if (!_started) const Text('Le chrono démarre au premier tap !', style: TextStyle(color: AppColors.textMuted)),
        Expanded(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 90),
            alignment: _pos,
            child: GestureDetector(
              onTapDown: (_) => _tap(),
              child: Container(
                width: 190,
                height: 190,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.liveGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 40)],
                ),
                child: Text('$_taps', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
