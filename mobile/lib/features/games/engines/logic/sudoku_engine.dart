import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';
import 'puzzle_logic.dart';

/// Sudoku 4×4 (default), 6×6 or 9×9 (`size`).
class SudokuEngine extends StatefulWidget {
  const SudokuEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<SudokuEngine> createState() => _SudokuEngineState();
}

class _SudokuEngineState extends State<SudokuEngine> {
  late final Sudoku _sudoku = Sudoku.generate(widget.run.random(), size: widget.run.game.cfgInt('size', 4));
  late final List<int> _grid = List.of(_sudoku.puzzle);
  int? _selected;
  int _mistakes = 0;
  final _watch = Stopwatch()..start();

  int get _n => _sudoku.size;

  void _place(int value) {
    final i = _selected;
    if (i == null || _sudoku.puzzle[i] != 0) return;
    setState(() => _grid[i] = value);
    if (value != 0 && _sudoku.conflicts(_grid, i, value)) {
      _mistakes++;
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    if (_sudoku.isSolved(_grid)) {
      _watch.stop();
      final seconds = _watch.elapsed.inSeconds;
      final par = switch (_n) { 9 => 600, 6 => 180, _ => 60 };
      widget.run.onFinish(GameOutcome(
        score: (par * 10 ~/ (seconds + 1) * 10 - _mistakes * 20).clamp(10, 100000),
        rating: GameOutcome.ratingOf((par / (seconds + 1)).clamp(0, 1) * (1 - _mistakes * 0.1).clamp(0.2, 1)),
        won: true,
        summary: 'Résolu en $seconds s',
        details: ['Erreurs : $_mistakes'],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _grid.where((v) => v != 0).length, extra: Text('❌ $_mistakes', style: const TextStyle(fontWeight: FontWeight.w800))),
        Expanded(
          child: EngineBody(
            maxWidth: 480,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.text, width: 2), borderRadius: BorderRadius.circular(6)),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _n),
                      itemCount: _n * _n,
                      itemBuilder: (context, i) {
                        final r = i ~/ _n, c = i % _n;
                        final fixed = _sudoku.puzzle[i] != 0;
                        final value = _grid[i];
                        final conflict = !fixed && _sudoku.conflicts(_grid, i, value);
                        final thickRight = (c + 1) % _sudoku.boxCols == 0 && c != _n - 1;
                        final thickBottom = (r + 1) % _sudoku.boxRows == 0 && r != _n - 1;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = i),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selected == i
                                  ? AppColors.primary.withValues(alpha: 0.35)
                                  : (fixed ? AppColors.surfaceHigh : AppColors.surface),
                              border: Border(
                                right: BorderSide(color: thickRight ? AppColors.text : AppColors.border, width: thickRight ? 2 : 0.5),
                                bottom: BorderSide(color: thickBottom ? AppColors.text : AppColors.border, width: thickBottom ? 2 : 0.5),
                              ),
                            ),
                            child: Text(
                              value == 0 ? '' : '$value',
                              style: TextStyle(
                                fontSize: _n == 9 ? 20 : 28,
                                fontWeight: fixed ? FontWeight.w900 : FontWeight.w600,
                                color: conflict ? AppColors.danger : (fixed ? AppColors.text : AppColors.secondary),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var v = 1; v <= _n; v++)
                      SizedBox(
                        width: 48,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: AppColors.surfaceHigh, foregroundColor: AppColors.text),
                          onPressed: () => _place(v),
                          child: Text('$v', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    SizedBox(
                      width: 48,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => _place(0),
                        child: const Icon(Icons.backspace_outlined),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
