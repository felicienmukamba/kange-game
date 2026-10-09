import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Hangman over themed word lists. Three words per run, 6 lives per word.
/// Variant `secret` ("mot interdit", "code secret") hides the category.
class HangmanEngine extends StatefulWidget {
  const HangmanEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<HangmanEngine> createState() => _HangmanEngineState();
}

class _HangmanEngineState extends State<HangmanEngine> {
  static const _lives = 6;
  static const _words = 3;
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  late final List<(String, String)> _queue; // (category, word)
  int _index = 0;
  final Set<String> _guessed = {};
  int _misses = 0;
  int _score = 0;
  int _found = 0;
  bool? _result;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    final rnd = widget.run.random();
    final all = <(String, String)>[
      for (final e in widget.run.content.hangman.entries)
        for (final w in e.value) (e.key, w),
    ];
    rnd.shuffle(all);
    _queue = all.take(_words).toList();
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  String get _word => _queue[_index].$2;

  bool get _solved => _word.split('').every((c) => !_alphabet.contains(c) || _guessed.contains(c));

  void _guess(String letter) {
    if (_result != null || _guessed.contains(letter)) return;
    setState(() {
      _guessed.add(letter);
      if (!_word.contains(letter)) {
        _misses++;
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }
      if (_solved) {
        _result = true;
        _found++;
        _score += 20 + (_lives - _misses) * 5;
      } else if (_misses >= _lives) {
        _result = false;
      }
    });
    if (_result != null) {
      _next = Timer(const Duration(milliseconds: 1500), _advance);
    }
  }

  void _advance() {
    if (!mounted) return;
    if (_index + 1 >= _queue.length) {
      widget.run.onFinish(GameOutcome(
        score: _score,
        rating: GameOutcome.ratingOf(_score / (_queue.length * 50)),
        won: _found == _queue.length,
        summary: '$_found mot${_found > 1 ? 's' : ''} trouvé${_found > 1 ? 's' : ''} sur ${_queue.length}',
      ));
      return;
    }
    setState(() {
      _index++;
      _guessed.clear();
      _misses = 0;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final secret = widget.run.game.cfgStr('variant') == 'secret';
    final display = _word
        .split('')
        .map((c) => !_alphabet.contains(c) ? c : (_guessed.contains(c) || _result == false ? c : '_'))
        .join(' ');
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        final ch = event.character?.toUpperCase();
        if (event is KeyDownEvent && ch != null && ch.length == 1 && _alphabet.contains(ch)) {
          _guess(ch);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          GameHud(score: _score, round: _index, total: _queue.length),
          Expanded(
            child: EngineBody(
              child: Column(
                children: [
                  Text(secret ? '🔐 Mot secret' : '📂 ${_queue[_index].$1}', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _lives; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(i < _lives - _misses ? '❤️' : '🖤', style: const TextStyle(fontSize: 22)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: _result == null ? AppColors.text : (_result! ? AppColors.success : AppColors.danger),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final l in _alphabet.split(''))
                        SizedBox(
                          width: 40,
                          height: 46,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              backgroundColor: !_guessed.contains(l)
                                  ? AppColors.surfaceHigh
                                  : (_word.contains(l) ? AppColors.success : AppColors.danger.withValues(alpha: 0.5)),
                              foregroundColor: AppColors.text,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _guessed.contains(l) || _result != null ? null : () => _guess(l),
                            child: Text(l, style: const TextStyle(fontWeight: FontWeight.w800)),
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
      ),
    );
  }
}
