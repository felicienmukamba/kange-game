import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// "Petit bac": one letter, four categories, 60 seconds. Answers are checked
/// against bundled word lists (accents and case ignored).
class CategoriesEngine extends StatefulWidget {
  const CategoriesEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<CategoriesEngine> createState() => _CategoriesEngineState();
}

class _CategoriesEngineState extends State<CategoriesEngine> {
  static const _rounds = 3;

  late final Map<String, Set<String>> _lists;
  late final List<String> _letters;
  late final Duration _limit = widget.run.timeLimit(60);
  late Map<String, TextEditingController> _inputs;
  Map<String, bool>? _checked;
  int _round = 0;
  int _score = 0;
  int _valid = 0;

  @override
  void initState() {
    super.initState();
    _lists = {
      for (final e in widget.run.content.categories.entries) e.key: e.value.map(normalizeAnswer).toSet(),
    };
    // Only letters that have an answer in every category.
    final candidates = 'ABCDEFGHIJKLMNOPRSTV'.split('').where((l) {
      final lower = l.toLowerCase();
      return _lists.values.every((set) => set.any((w) => w.startsWith(lower)));
    }).toList();
    widget.run.random().shuffle(candidates);
    _letters = candidates.take(_rounds).toList();
    _inputs = {for (final c in _lists.keys) c: TextEditingController()};
  }

  @override
  void dispose() {
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _letter => _letters[_round];

  void _check() {
    if (_checked != null) return;
    final letter = _letter.toLowerCase();
    final result = <String, bool>{};
    for (final entry in _inputs.entries) {
      final answer = normalizeAnswer(entry.value.text);
      result[entry.key] = answer.startsWith(letter) && _lists[entry.key]!.contains(answer);
    }
    final good = result.values.where((v) => v).length;
    setState(() {
      _checked = result;
      _valid += good;
      _score += good * 10 + (good == result.length ? 20 : 0);
    });
  }

  void _nextRound() {
    if (_round + 1 >= _letters.length) {
      final max = _letters.length * _lists.length;
      widget.run.onFinish(GameOutcome(
        score: _score,
        rating: GameOutcome.ratingOf(_valid / max),
        won: _valid >= max * 0.6,
        summary: '$_valid réponses valides sur $max',
      ));
      return;
    }
    setState(() {
      _round++;
      _checked = null;
      for (final c in _inputs.values) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(
          score: _score,
          round: _round,
          total: _letters.length,
          timer: CountdownBar(key: ValueKey(_round), duration: _limit, paused: _checked != null, onElapsed: _check),
        ),
        Expanded(
          child: EngineBody(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
                    child: Text(_letter, style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 20),
                for (final cat in _inputs.keys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _inputs[cat],
                      enabled: _checked == null,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: cat,
                        hintText: '$_letter…',
                        suffixIcon: _checked == null
                            ? null
                            : Icon(
                                _checked![cat]! ? Icons.check_circle : Icons.cancel,
                                color: _checked![cat]! ? AppColors.success : AppColors.danger,
                              ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _checked == null ? _check : _nextRound,
                  child: Text(_checked == null ? 'Valider' : (_round + 1 >= _letters.length ? 'Voir le résultat' : 'Lettre suivante')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
