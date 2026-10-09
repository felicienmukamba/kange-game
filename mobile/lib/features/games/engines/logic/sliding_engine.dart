import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';
import 'puzzle_logic.dart';

/// Sliding tile puzzle ("taquin"), 3×3 by default (`size` 3-5).
class SlidingEngine extends StatefulWidget {
  const SlidingEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<SlidingEngine> createState() => _SlidingEngineState();
}

class _SlidingEngineState extends State<SlidingEngine> {
  late final int _size = widget.run.game.cfgInt('size', 3).clamp(3, 5);
  late final SlidingBoard _board = SlidingBoard.shuffled(widget.run.random(), _size);
  int _moves = 0;
  final _watch = Stopwatch()..start();
  bool _done = false;

  void _tap(int index) {
    if (_done || !_board.move(index)) return;
    HapticFeedback.selectionClick();
    setState(() => _moves++);
    if (_board.isSolved) {
      _done = true;
      _watch.stop();
      final seconds = _watch.elapsed.inSeconds;
      final par = switch (_size) { 3 => 60, 4 => 240, _ => 600 };
      widget.run.onFinish(GameOutcome(
        score: (par * 50 ~/ (seconds + 1) + 500 ~/ (_moves ~/ 10 + 1)).clamp(10, 100000),
        rating: GameOutcome.ratingOf(par / (seconds + par / 2)),
        won: true,
        summary: 'Résolu en $_moves coups et $seconds s',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _moves, extra: const Text('coups', style: TextStyle(color: AppColors.textMuted))),
        Expanded(
          child: EngineBody(
            maxWidth: 460,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final cell = box.maxWidth / _size;
                    return Stack(
                      children: [
                        for (var i = 0; i < _board.tiles.length; i++)
                          if (_board.tiles[i] != 0)
                            AnimatedPositioned(
                              key: ValueKey(_board.tiles[i]),
                              duration: const Duration(milliseconds: 110),
                              left: (i % _size) * cell,
                              top: (i ~/ _size) * cell,
                              width: cell,
                              height: cell,
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: GestureDetector(
                                  onTap: () => _tap(i),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: _board.tiles[i] == i + 1 ? null : AppColors.primaryGradient,
                                      color: AppColors.success.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('${_board.tiles[i]}', style: TextStyle(fontSize: cell * 0.36, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Text('Remets les nombres dans l\'ordre, le trou en bas à droite', style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
