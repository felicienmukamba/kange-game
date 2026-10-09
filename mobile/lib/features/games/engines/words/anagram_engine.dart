import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Unscramble as many words as possible in 90 seconds by tapping letter tiles.
class AnagramEngine extends StatefulWidget {
  const AnagramEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<AnagramEngine> createState() => _AnagramEngineState();
}

class _AnagramEngineState extends State<AnagramEngine> {
  late final List<String> _words;
  late final Duration _limit = widget.run.timeLimit(90);
  int _index = 0;
  late List<String> _tiles;
  final List<int> _picked = [];
  int _score = 0;
  int _found = 0;
  bool _flash = false;
  bool _done = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    final rnd = widget.run.random();
    _words = [
      for (final list in widget.run.content.hangman.values)
        for (final w in list)
          if (!w.contains(' ') && w.length >= 4 && w.length <= 9) w,
    ];
    rnd.shuffle(_words);
    _load();
  }

  void _load() {
    final rnd = widget.run.random(_index + 1);
    final word = _words[_index % _words.length];
    var tiles = word.split('');
    do {
      tiles = List.of(tiles);
      rnd.shuffle(tiles);
    } while (tiles.join() == word && word.length > 1);
    _tiles = tiles;
    _picked.clear();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  String get _word => _words[_index % _words.length];

  void _tap(int i) {
    if (_done || _picked.contains(i)) return;
    setState(() => _picked.add(i));
    HapticFeedback.selectionClick();
    if (_picked.length == _tiles.length) {
      final attempt = _picked.map((p) => _tiles[p]).join();
      if (attempt == _word) {
        setState(() {
          _score += _word.length * 5;
          _found++;
          _index++;
          _load();
        });
        HapticFeedback.lightImpact();
      } else {
        setState(() {
          _flash = true;
          _picked.clear();
        });
        _flashTimer = Timer(const Duration(milliseconds: 400), () => mounted ? setState(() => _flash = false) : null);
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _skip() => setState(() {
        _index++;
        _load();
      });

  void _finish() {
    if (_done) return;
    _done = true;
    widget.run.onFinish(GameOutcome(
      score: _score,
      rating: GameOutcome.ratingOf(_found / 8),
      won: _found >= 5,
      summary: '$_found mot${_found > 1 ? 's' : ''} retrouvé${_found > 1 ? 's' : ''}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _score, timer: CountdownBar(duration: _limit, onElapsed: _finish)),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const Spacer(),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  children: [
                    for (var i = 0; i < _tiles.length; i++)
                      Container(
                        width: 38,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: _flash ? AppColors.danger : AppColors.primary, width: 3)),
                        ),
                        child: Text(i < _picked.length ? _tiles[_picked[i]] : '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
                const SizedBox(height: 36),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _tiles.length; i++)
                      AnimatedOpacity(
                        opacity: _picked.contains(i) ? 0.2 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: GestureDetector(
                          onTap: () => _tap(i),
                          child: Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                            child: Text(_tiles[i], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _picked.isEmpty ? null : () => setState(_picked.removeLast),
                        icon: const Icon(Icons.backspace_outlined),
                        label: const Text('Effacer'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton(onPressed: _skip, child: const Text('⏭️ Passer'))),
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
