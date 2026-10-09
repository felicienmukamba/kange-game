import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';
import 'puzzle_logic.dart';

/// Timed rapid-fire on generated questions: mental math or number sequences.
/// The run lasts [GameRun.timeLimit]; each streak of 3 raises the difficulty.
class QuickQuestionEngine extends StatefulWidget {
  const QuickQuestionEngine.math({super.key, required this.run}) : sequence = false;

  const QuickQuestionEngine.sequence({super.key, required this.run}) : sequence = true;

  final GameRun run;
  final bool sequence;

  @override
  State<QuickQuestionEngine> createState() => _QuickQuestionEngineState();
}

class _QuickQuestionEngineState extends State<QuickQuestionEngine> {
  late final _rnd = widget.run.random();
  late final Duration _limit = widget.run.timeLimit(widget.sequence ? 90 : 60);
  late final bool _hardcore = widget.run.game.cfgBool('hardcore');
  late GeneratedQuestion _q = _generate();
  int _level = 0;
  int _score = 0;
  int _right = 0;
  int _asked = 1;
  int _streak = 0;
  int? _flash;
  bool _done = false;
  Timer? _flashTimer;

  GeneratedQuestion _generate() =>
      widget.sequence ? sequenceQuestion(_rnd, _level) : mathQuestion(_rnd, _level, hardcore: _hardcore);

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _answer(int i) {
    if (_done) return;
    final ok = i == _q.answer;
    setState(() {
      if (ok) {
        _right++;
        _streak++;
        _score += 10 + _level * 2;
        if (_streak % 3 == 0) _level++;
        HapticFeedback.lightImpact();
      } else {
        _streak = 0;
        _score = (_score - 5).clamp(0, 1 << 30);
        HapticFeedback.heavyImpact();
      }
      _flash = ok ? 1 : 0;
      _q = _generate();
      _asked++;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 250), () => mounted ? setState(() => _flash = null) : null);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    final answered = _asked - 1;
    final accuracy = answered == 0 ? 0 : _right / answered;
    widget.run.onFinish(GameOutcome(
      score: _score,
      rating: GameOutcome.ratingOf((_right / (widget.sequence ? 12 : 25)) * (0.5 + accuracy / 2)),
      won: _right >= (widget.sequence ? 8 : 15),
      summary: '$_right bonnes réponses · niveau ${_level + 1}',
      details: ['Précision : ${(accuracy * 100).round()} %'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(
          score: _score,
          extra: Text('Niv. ${_level + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary)),
          timer: CountdownBar(duration: _limit, onElapsed: _finish),
        ),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _flash == null
                        ? AppColors.surface
                        : (_flash == 1 ? AppColors.success : AppColors.danger).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_q.prompt, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                  ),
                ),
                const Spacer(),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < _q.options.length; i++)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceHigh,
                          foregroundColor: AppColors.text,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _answer(i),
                        child: Text(_q.options[i], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
