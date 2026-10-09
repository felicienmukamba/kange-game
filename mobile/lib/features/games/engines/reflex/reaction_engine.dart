import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Reaction time: wait for green (or the 🔔 for `sound` / `buzzer`), then tap.
/// Five attempts; tapping too early costs a 1 s penalty. Rating: 200 ms = 100, 600 ms = 0.
class ReactionEngine extends StatefulWidget {
  const ReactionEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<ReactionEngine> createState() => _ReactionEngineState();
}

enum _Phase { waiting, go, result, early }

class _ReactionEngineState extends State<ReactionEngine> {
  static const _attempts = 5;
  static const _penaltyMs = 1000;

  late final _rnd = widget.run.random();
  late final String? _variant = widget.run.game.cfgStr('variant');
  final List<int> _times = [];
  _Phase _phase = _Phase.waiting;
  Timer? _timer;
  final _watch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _phase = _Phase.waiting;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: 1200 + _rnd.nextInt(2800)), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.go);
      if (_variant == 'sound' || _variant == 'buzzer') SystemSound.play(SystemSoundType.alert);
      _watch
        ..reset()
        ..start();
    });
  }

  void _tap() {
    switch (_phase) {
      case _Phase.waiting:
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _phase = _Phase.early;
          _times.add(_penaltyMs);
        });
      case _Phase.go:
        _watch.stop();
        HapticFeedback.lightImpact();
        setState(() {
          _phase = _Phase.result;
          _times.add(_watch.elapsedMilliseconds);
        });
      case _Phase.result:
      case _Phase.early:
        if (_times.length >= _attempts) {
          _finish();
        } else {
          setState(_arm);
        }
    }
  }

  void _finish() {
    final avg = _times.reduce((a, b) => a + b) ~/ _times.length;
    final best = _times.reduce((a, b) => a < b ? a : b);
    widget.run.onFinish(GameOutcome(
      // Lower is better for reaction time; the score is inverted so higher wins in races.
      score: (1000 - avg).clamp(0, 1000),
      rating: GameOutcome.ratingOf((600 - avg) / 400),
      won: avg < 300,
      summary: 'Moyenne : $avg ms',
      details: ['Meilleur : $best ms', 'Essais : ${_times.join(' · ')} ms'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final (color, title, subtitle) = switch (_phase) {
      _Phase.waiting => (AppColors.danger, 'Attends…', _variant == 'sound' || _variant == 'buzzer' ? 'Tape au 🔔' : 'Tape quand ça devient VERT'),
      _Phase.go => (AppColors.success, _variant == 'sound' || _variant == 'buzzer' ? '🔔 MAINTENANT !' : 'TAPE !', ''),
      _Phase.result => (AppColors.primary, '${_times.last} ms', _times.length >= _attempts ? 'Touche pour voir le résultat' : 'Touche pour continuer'),
      _Phase.early => (AppColors.warning, 'Trop tôt ! +1 s', 'Touche pour réessayer'),
    };
    return Column(
      children: [
        GameHud(score: _times.length, round: _times.length.clamp(0, _attempts - 1), total: _attempts),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _tap(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28)),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
