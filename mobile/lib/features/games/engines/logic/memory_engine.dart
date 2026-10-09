import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Memory games. Variants:
/// * default / `flash` — find the pairs (flash: all cards shown for 3 s first),
/// * `simon` / `reverse` — repeat a growing colour sequence (reverse: backwards).
class MemoryEngine extends StatelessWidget {
  const MemoryEngine({super.key, required this.run});

  final GameRun run;

  @override
  Widget build(BuildContext context) {
    final variant = run.game.cfgStr('variant');
    return switch (variant) {
      'simon' || 'reverse' => _SimonGame(run: run, reverse: variant == 'reverse'),
      _ => _PairsGame(run: run, peek: variant == 'flash'),
    };
  }
}

class _PairsGame extends StatefulWidget {
  const _PairsGame({required this.run, required this.peek});

  final GameRun run;
  final bool peek;

  @override
  State<_PairsGame> createState() => _PairsGameState();
}

class _PairsGameState extends State<_PairsGame> {
  static const _symbols = ['🦁', '🐘', '🦒', '🐢', '🦋', '🍍', '⚽', '🎸', '🚀', '👑', '🌍', '🍕', '🎧', '🦈', '🌵', '🐼'];
  static const _pairs = 8;

  late final List<String> _cards;
  final Set<int> _matched = {};
  final List<int> _open = [];
  int _moves = 0;
  bool _peeking = false;
  bool _locked = false;
  final _watch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rnd = widget.run.random();
    final symbols = List.of(_symbols);
    rnd.shuffle(symbols);
    _cards = [...symbols.take(_pairs), ...symbols.take(_pairs)];
    rnd.shuffle(_cards);
    if (widget.peek) {
      _peeking = true;
      _timer = Timer(const Duration(seconds: 3), () => mounted ? setState(() => _peeking = false) : null);
    }
    _watch.start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _flip(int i) {
    if (_locked || _peeking || _matched.contains(i) || _open.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => _open.add(i));
    if (_open.length < 2) return;
    _moves++;
    final [a, b] = _open;
    if (_cards[a] == _cards[b]) {
      setState(() {
        _matched.addAll(_open);
        _open.clear();
      });
      if (_matched.length == _cards.length) _finish();
    } else {
      _locked = true;
      _timer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _open.clear();
          _locked = false;
        });
      });
    }
  }

  void _finish() {
    _watch.stop();
    final seconds = _watch.elapsed.inSeconds;
    // Perfect memory = 8 moves; 24+ moves rates 0.
    final efficiency = ((24 - _moves) / 16).clamp(0, 1);
    widget.run.onFinish(GameOutcome(
      score: (1000 - _moves * 20 - seconds * 5).clamp(50, 1000),
      rating: GameOutcome.ratingOf(efficiency),
      won: _moves <= 14,
      summary: 'Toutes les paires en $_moves coups',
      details: ['Temps : $seconds s'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _matched.length ~/ 2 * 10, extra: Text('$_moves coups', style: const TextStyle(fontWeight: FontWeight.w700))),
        if (_peeking) const Text('👀 Mémorise !', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Expanded(
          child: EngineBody(
            maxWidth: 480,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < _cards.length; i++)
                      GestureDetector(
                        onTap: () => _flip(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: _peeking || _open.contains(i) || _matched.contains(i) ? null : AppColors.primaryGradient,
                            color: _matched.contains(i) ? AppColors.success.withValues(alpha: 0.2) : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _peeking || _open.contains(i) || _matched.contains(i)
                              ? Text(_cards[i], style: const TextStyle(fontSize: 34))
                              : const Text('?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimonGame extends StatefulWidget {
  const _SimonGame({required this.run, required this.reverse});

  final GameRun run;
  final bool reverse;

  @override
  State<_SimonGame> createState() => _SimonGameState();
}

class _SimonGameState extends State<_SimonGame> {
  static const _colors = [AppColors.danger, AppColors.success, AppColors.secondary, AppColors.warning];
  static const _emojis = ['🔴', '🟢', '🔵', '🟡'];

  late final _rnd = widget.run.random();
  final List<int> _sequence = [];
  int _input = 0;
  int? _lit;
  bool _playing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _extend();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _extend() {
    _sequence.add(_rnd.nextInt(4));
    _input = 0;
    _playback();
  }

  Future<void> _playback() async {
    setState(() => _playing = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final speed = (520 - _sequence.length * 20).clamp(220, 520);
    for (final step in _sequence) {
      if (!mounted) return;
      setState(() => _lit = step);
      await Future<void>.delayed(Duration(milliseconds: speed));
      if (!mounted) return;
      setState(() => _lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
    if (mounted) setState(() => _playing = false);
  }

  void _press(int i) {
    if (_playing) return;
    final expected = widget.reverse ? _sequence[_sequence.length - 1 - _input] : _sequence[_input];
    HapticFeedback.selectionClick();
    setState(() => _lit = i);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 160), () => mounted ? setState(() => _lit = null) : null);
    if (i != expected) {
      final reached = _sequence.length - 1;
      widget.run.onFinish(GameOutcome(
        score: reached * 10,
        rating: GameOutcome.ratingOf(reached / 12),
        won: reached >= 8,
        summary: 'Séquence de $reached retenue',
      ));
      setState(() => _playing = true);
      return;
    }
    _input++;
    if (_input == _sequence.length) _extend();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: (_sequence.length - 1) * 10),
        Text(
          _playing ? '👀 Regarde bien…' : (widget.reverse ? '🔁 À toi, à l\'envers !' : '👉 À toi !'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Expanded(
          child: EngineBody(
            maxWidth: 420,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < 4; i++)
                      GestureDetector(
                        onTapDown: (_) => _press(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 90),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _colors[i].withValues(alpha: _lit == i ? 1 : 0.28),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: _lit == i ? [BoxShadow(color: _colors[i], blurRadius: 30)] : null,
                          ),
                          child: Text(_emojis[i], style: const TextStyle(fontSize: 30)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text('Longueur : ${_sequence.length}', style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 24),
      ],
    );
  }
}
