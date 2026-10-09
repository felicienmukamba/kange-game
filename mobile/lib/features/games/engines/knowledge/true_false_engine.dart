import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../domain/content.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Vrai ou faux / oui ou non / swipe. Options: `pack`, `count`, `time`.
/// Swipe right = vrai, left = faux, or tap the buttons.
class TrueFalseEngine extends StatefulWidget {
  const TrueFalseEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<TrueFalseEngine> createState() => _TrueFalseEngineState();
}

class _TrueFalseEngineState extends State<TrueFalseEngine> {
  late final List<Statement> _items;
  late final Duration _limit;
  int _index = 0;
  int _score = 0;
  int _correct = 0;
  bool? _lastRight;
  double _drag = 0;
  final _watch = Stopwatch()..start();
  Timer? _next;

  @override
  void initState() {
    super.initState();
    final pool = List.of(widget.run.content.statements(widget.run.game.cfgStr('pack')));
    widget.run.random().shuffle(pool);
    _items = pool.take(widget.run.game.cfgInt('count', 10).clamp(1, pool.length)).toList();
    _limit = widget.run.timeLimit(6);
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  void _answer(bool? value) {
    if (_lastRight != null) return;
    final right = value != null && value == _items[_index].isTrue;
    final speedBonus = right ? (10 * (1 - _watch.elapsedMilliseconds / _limit.inMilliseconds)).round().clamp(0, 10) : 0;
    setState(() {
      _lastRight = right;
      _drag = 0;
      if (right) {
        _correct++;
        _score += 10 + speedBonus;
      }
    });
    right ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    _next = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_index + 1 >= _items.length) {
        widget.run.onFinish(GameOutcome(
          score: _score,
          rating: GameOutcome.ratingOf(_correct / _items.length),
          won: _correct >= (_items.length * 0.7).ceil(),
          summary: '$_correct / ${_items.length} bonnes réponses',
        ));
      } else {
        setState(() {
          _index++;
          _lastRight = null;
        });
        _watch
          ..reset()
          ..start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return Column(
      children: [
        GameHud(
          score: _score,
          round: _index,
          total: _items.length,
          timer: CountdownBar(key: ValueKey(_index), duration: _limit, paused: _lastRight != null, onElapsed: () => _answer(null)),
        ),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const Spacer(),
                GestureDetector(
                  onHorizontalDragUpdate: (d) => setState(() => _drag += d.delta.dx),
                  onHorizontalDragEnd: (_) {
                    if (_drag.abs() > 80) {
                      _answer(_drag > 0);
                    } else {
                      setState(() => _drag = 0);
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(_drag, 0),
                    child: Transform.rotate(
                      angle: _drag / 900,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 220),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            width: 2,
                            color: _lastRight == null
                                ? (_drag > 30 ? AppColors.success : (_drag < -30 ? AppColors.danger : AppColors.border))
                                : (_lastRight! ? AppColors.success : AppColors.danger),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.35)),
                            if (_lastRight != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                '${_lastRight! ? '✅ Bien vu' : '❌ Raté'} — c\'est ${item.isTrue ? 'VRAI' : 'FAUX'}',
                                style: TextStyle(fontWeight: FontWeight.w900, color: _lastRight! ? AppColors.success : AppColors.danger),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('← glisse pour FAUX · VRAI pour glisser →', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: AnswerButton(
                        label: 'FAUX',
                        leading: '👎',
                        color: AppColors.danger,
                        onTap: () => _answer(false),
                        state: _lastRight == null ? AnswerState.idle : AnswerState.disabled,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnswerButton(
                        label: 'VRAI',
                        leading: '👍',
                        color: AppColors.success,
                        onTap: () => _answer(true),
                        state: _lastRight == null ? AnswerState.idle : AnswerState.disabled,
                      ),
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
