import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Type the sentence as fast and accurately as possible (3 sentences).
/// Rating mixes words-per-minute and accuracy. Option `strict`: one mistake ends the run.
class TypingEngine extends StatefulWidget {
  const TypingEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<TypingEngine> createState() => _TypingEngineState();
}

class _TypingEngineState extends State<TypingEngine> {
  static const _sentences = 3;

  late final List<String> _texts;
  final _input = TextEditingController();
  final _watch = Stopwatch();
  int _index = 0;
  int _typed = 0;
  int _errors = 0;
  int _score = 0;
  String _previous = '';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final pool = List.of(widget.run.content.typing);
    widget.run.random().shuffle(pool);
    _texts = pool.take(_sentences).toList();
    _input.addListener(_onChanged);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String get _target => _texts[_index];

  void _onChanged() {
    if (_done) return;
    final text = _input.text;
    if (!_watch.isRunning && text.isNotEmpty) _watch.start();
    // Count newly typed characters that don't match the target.
    if (text.length > _previous.length) {
      for (var i = _previous.length; i < text.length; i++) {
        _typed++;
        if (i >= _target.length || text[i] != _target[i]) _errors++;
      }
      if (widget.run.game.cfgBool('strict') && _errors > 0) {
        _finish();
        return;
      }
    }
    _previous = text;
    if (text == _target) {
      _score += _target.length;
      if (_index + 1 >= _texts.length) {
        _finish();
      } else {
        setState(() {
          _index++;
          _previous = '';
        });
        _input.clear();
      }
    } else {
      setState(() {});
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _watch.stop();
    final minutes = _watch.elapsedMilliseconds / 60000;
    final chars = _texts.take(_index).fold<int>(0, (s, t) => s + t.length) + _previous.length;
    final wpm = minutes == 0 ? 0 : (chars / 5) / minutes;
    final accuracy = _typed == 0 ? 0 : (_typed - _errors) / _typed;
    widget.run.onFinish(GameOutcome(
      score: (wpm * accuracy).round(),
      rating: GameOutcome.ratingOf((wpm / 50).clamp(0, 1) * accuracy),
      won: wpm >= 30 && accuracy >= 0.9,
      summary: '${wpm.round()} mots/min · précision ${(accuracy * 100).round()} %',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final typed = _input.text;
    return Column(
      children: [
        GameHud(score: _score, round: _index, total: _texts.length),
        Expanded(
          child: EngineBody(
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 21, height: 1.5, fontWeight: FontWeight.w600),
                      children: [
                        for (var i = 0; i < _target.length; i++)
                          TextSpan(
                            text: _target[i],
                            style: TextStyle(
                              color: i >= typed.length
                                  ? AppColors.textMuted
                                  : (typed[i] == _target[i] ? AppColors.success : AppColors.danger),
                              backgroundColor: i == typed.length ? AppColors.primary.withValues(alpha: 0.35) : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _input,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(hintText: 'Recopie le texte ici…'),
                ),
                const SizedBox(height: 10),
                Text('Erreurs : $_errors', style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
