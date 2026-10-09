import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../domain/content.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Free-text guessing with progressive clues (emoji riddles, 3 indices, devinettes,
/// enquêtes, traductions…). Options: `pack`, `count`, `time`.
/// Points: 30 with one clue, 20 with two, 10 with three. Typos are forgiven.
class GuessEngine extends StatefulWidget {
  const GuessEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<GuessEngine> createState() => _GuessEngineState();
}

class _GuessEngineState extends State<GuessEngine> {
  late final List<GuessItem> _items;
  late final Duration _limit;
  final _input = TextEditingController();
  final _focus = FocusNode();
  int _index = 0;
  int _clues = 1;
  int _score = 0;
  int _found = 0;
  bool? _result;
  bool _shake = false;
  bool _letterHint = false;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    final pool = List.of(widget.run.content.guessPack(widget.run.game.cfgStr('pack')));
    widget.run.random().shuffle(pool);
    _items = pool.take(widget.run.game.cfgInt('count', 6).clamp(1, pool.length)).toList();
    _limit = widget.run.timeLimit(45);
  }

  @override
  void dispose() {
    _next?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  GuessItem get _item => _items[_index];

  void _submit() {
    if (_result != null) return;
    final guess = _input.text;
    if (guess.trim().isEmpty) return;
    if (answerMatches(guess, _item.accepted)) {
      HapticFeedback.lightImpact();
      final points = (40 - _clues * 10 - (_letterHint ? 5 : 0)).clamp(5, 30);
      setState(() {
        _result = true;
        _found++;
        _score += points;
      });
      _advance();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _shake = !_shake);
      _input.selection = TextSelection(baseOffset: 0, extentOffset: _input.text.length);
    }
  }

  void _giveUp() {
    if (_result != null) return;
    setState(() => _result = false);
    _advance();
  }

  void _advance() {
    _next = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_index + 1 >= _items.length) {
        widget.run.onFinish(GameOutcome(
          score: _score,
          rating: GameOutcome.ratingOf(_found / _items.length),
          won: _found >= (_items.length * 0.6).ceil(),
          summary: '$_found trouvé${_found > 1 ? 's' : ''} sur ${_items.length}',
        ));
        return;
      }
      setState(() {
        _index++;
        _clues = 1;
        _result = null;
        _letterHint = false;
        _input.clear();
      });
      _focus.requestFocus();
    });
  }

  String get _mask {
    final a = _item.answer;
    return a.split('').asMap().entries.map((e) => e.value == ' ' || e.value == '-' || e.value == "'" ? e.value : (e.key == 0 ? e.value.toUpperCase() : '_')).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Column(
      children: [
        GameHud(
          score: _score,
          round: _index,
          total: _items.length,
          timer: CountdownBar(key: ValueKey(_index), duration: _limit, paused: _result != null, onElapsed: _giveUp),
        ),
        Expanded(
          child: EngineBody(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                for (var i = 0; i < _clues && i < item.clues.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PromptCard(text: item.clues[i], fontSize: i == 0 ? 22 : 17),
                  ),
                if (_letterHint && _result == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: Text(_mask, style: const TextStyle(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                    ),
                  ),
                if (_result != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: FeedbackBanner(text: _result! ? '✅ Bravo : ${item.answer}' : '💡 C\'était : ${item.answer}', positive: _result!),
                    ),
                  )
                else ...[
                  TweenAnimationBuilder<double>(
                    key: ValueKey(_shake),
                    tween: Tween(begin: 1, end: 0),
                    duration: const Duration(milliseconds: 350),
                    builder: (context, v, child) => Transform.translate(offset: Offset(12 * v * (v * 10 % 2 > 1 ? 1 : -1), 0), child: child),
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      autofocus: true,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Ta réponse…',
                        suffixIcon: IconButton(icon: const Icon(Icons.send_rounded), onPressed: _submit),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clues < item.clues.length ? () => setState(() => _clues++) : (_letterHint ? null : () => setState(() => _letterHint = true)),
                          child: Text(_clues < item.clues.length ? '💡 Indice (-10)' : '🔤 1re lettre (-5)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton(onPressed: _giveUp, child: const Text('🏳️ Passer'))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
