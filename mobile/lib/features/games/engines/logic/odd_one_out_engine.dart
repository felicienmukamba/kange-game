import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// "Trouve l'intrus": spot the one emoji that differs. The grid grows every
/// two finds (3×3 → 7×7). 45 seconds; wrong taps cost 2 seconds of score.
class OddOneOutEngine extends StatefulWidget {
  const OddOneOutEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<OddOneOutEngine> createState() => _OddOneOutEngineState();
}

class _OddOneOutEngineState extends State<OddOneOutEngine> {
  late final _rnd = widget.run.random();
  late final Duration _limit = widget.run.timeLimit(45);
  late (String, String) _pair;
  late int _odd;
  int _found = 0;
  int _misses = 0;
  bool _flip = false;
  bool _done = false;

  int get _side => min(3 + _found ~/ 2, 7);

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    final pairs = widget.run.content.oddPairs;
    _pair = pairs[_rnd.nextInt(pairs.length)];
    _flip = _rnd.nextBool();
    _odd = _rnd.nextInt(_side * _side);
  }

  void _tap(int i) {
    if (_done) return;
    if (i == _odd) {
      HapticFeedback.lightImpact();
      setState(() {
        _found++;
        _next();
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _misses++);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    final score = max(0, _found * 10 - _misses * 3);
    widget.run.onFinish(GameOutcome(
      score: score,
      rating: GameOutcome.ratingOf(score / 150),
      won: _found >= 12,
      summary: '$_found intrus trouvés',
      details: ['Erreurs : $_misses'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final (common, odd) = _flip ? (_pair.$2, _pair.$1) : _pair;
    final side = _side;
    return Column(
      children: [
        GameHud(score: _found * 10 - _misses * 3, timer: CountdownBar(duration: _limit, onElapsed: _finish)),
        const Text('Touche l\'intrus !', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMuted)),
        Expanded(
          child: EngineBody(
            maxWidth: 480,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: side, mainAxisSpacing: 4, crossAxisSpacing: 4),
                  itemCount: side * side,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _tap(i),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                      child: FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(i == _odd ? odd : common, style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                    ),
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
