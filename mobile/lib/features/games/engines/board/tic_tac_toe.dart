import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../../multiplayer/domain/lockstep.dart';
import 'board_widgets.dart';

class TicTacToeState {
  const TicTacToeState({
    required this.size,
    required this.toWin,
    required this.players,
    required this.cells,
    this.turn = 0,
    this.winner,
    this.line = const [],
  });

  final int size;
  final int toWin;
  final List<String> players;

  /// -1 empty, otherwise the player index.
  final List<int> cells;
  final int turn;
  final String? winner;
  final List<int> line;

  bool get full => !cells.contains(-1);

  bool get over => winner != null || full;

  TicTacToeState copyWith({List<int>? cells, int? turn, String? winner, List<int>? line}) => TicTacToeState(
        size: size,
        toWin: toWin,
        players: players,
        cells: cells ?? this.cells,
        turn: turn ?? this.turn,
        winner: winner ?? this.winner,
        line: line ?? this.line,
      );
}

/// Tic-tac-toe on an N×N board with K in a row (3/3 classic, 7/4 "géant").
class TicTacToeGame extends LockstepGame<TicTacToeState> {
  const TicTacToeGame(super.game);

  int get _size => game.cfgInt('size', 3).clamp(3, 9);

  int get _toWin => game.cfgInt('win', 3).clamp(3, 5);

  @override
  bool get supportsBots => true;

  @override
  TicTacToeState initial(List<String> players, int seed) => TicTacToeState(
        size: _size,
        toWin: _toWin,
        players: players.take(2).toList(),
        cells: List.filled(_size * _size, -1),
      );

  @override
  TicTacToeState apply(TicTacToeState s, RoomAction a) {
    if (s.over) return s;
    if (a.type == RoomAction.left) {
      final idx = s.players.indexOf(a.sender);
      if (idx < 0) return s;
      return s.copyWith(winner: s.players[1 - idx]);
    }
    if (a.type != 'move' || s.players.indexOf(a.sender) != s.turn) return s;
    final cell = a.data.integer('cell', -1);
    if (cell < 0 || cell >= s.cells.length || s.cells[cell] != -1) return s;
    final cells = List.of(s.cells)..[cell] = s.turn;
    final line = winningLine(cells, s.size, s.toWin, cell);
    return s.copyWith(
      cells: cells,
      turn: 1 - s.turn,
      winner: line.isEmpty ? null : s.players[s.turn],
      line: line,
    );
  }

  /// The winning cells through [last], or empty.
  static List<int> winningLine(List<int> cells, int size, int k, int last) {
    final who = cells[last];
    final r0 = last ~/ size, c0 = last % size;
    for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (1, -1)]) {
      final line = [last];
      for (final sign in const [1, -1]) {
        var r = r0 + dr * sign, c = c0 + dc * sign;
        while (r >= 0 && r < size && c >= 0 && c < size && cells[r * size + c] == who) {
          line.add(r * size + c);
          r += dr * sign;
          c += dc * sign;
        }
      }
      if (line.length >= k) return line;
    }
    return const [];
  }

  @override
  bool isFinished(TicTacToeState s) => s.over;

  @override
  Map<String, int> scores(TicTacToeState s) => {for (final p in s.players) p: p == s.winner ? 1 : 0};

  @override
  String? turnOf(TicTacToeState s) => s.over ? null : s.players[s.turn];

  @override
  (String, Json)? botMove(TicTacToeState s, String bot, SeededRandom random) {
    if (s.over || s.players[s.turn] != bot) return null;
    final me = s.turn;
    final empty = [for (var i = 0; i < s.cells.length; i++) if (s.cells[i] == -1) i];
    if (empty.isEmpty) return null;
    final hard = game.cfgStr('bot') == 'hard';
    if (s.size == 3 && (hard || random.nextInt(4) != 0)) {
      return ('move', {'cell': _minimaxBest(s.cells, me)});
    }
    // Win, then block, then the most promising cell.
    for (final who in [me, 1 - me]) {
      for (final i in empty) {
        final trial = List.of(s.cells)..[i] = who;
        if (winningLine(trial, s.size, s.toWin, i).isNotEmpty) return ('move', {'cell': i});
      }
    }
    var best = empty.first;
    var bestScore = -1;
    for (final i in empty) {
      final score = _potential(s, i, me) * 2 + _potential(s, i, 1 - me) + random.nextInt(3);
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return ('move', {'cell': best});
  }

  int _potential(TicTacToeState s, int cell, int who) {
    var total = 0;
    final r0 = cell ~/ s.size, c0 = cell % s.size;
    for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (1, -1)]) {
      var run = 0;
      for (final sign in const [1, -1]) {
        var r = r0 + dr * sign, c = c0 + dc * sign;
        while (r >= 0 && r < s.size && c >= 0 && c < s.size && s.cells[r * s.size + c] == who) {
          run++;
          r += dr * sign;
          c += dc * sign;
        }
      }
      total += run * run;
    }
    return total;
  }

  static int _minimaxBest(List<int> cells, int me) {
    var bestScore = -1000, best = cells.indexOf(-1);
    for (var i = 0; i < 9; i++) {
      if (cells[i] != -1) continue;
      final next = List.of(cells)..[i] = me;
      final score = -_negamax(next, 1 - me, i, 1);
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  static int _negamax(List<int> cells, int toMove, int last, int depth) {
    if (winningLine(cells, 3, 3, last).isNotEmpty) return -(10 - depth);
    if (!cells.contains(-1)) return 0;
    var best = -1000;
    for (var i = 0; i < 9; i++) {
      if (cells[i] != -1) continue;
      cells[i] = toMove;
      final score = -_negamax(cells, 1 - toMove, i, depth + 1);
      cells[i] = -1;
      if (score > best) best = score;
    }
    return best;
  }

  @override
  Widget buildView(BuildContext context, LockstepView<TicTacToeState> view) => _TicTacToeView(view: view);
}

class _TicTacToeView extends StatelessWidget {
  const _TicTacToeView({required this.view});

  final LockstepView<TicTacToeState> view;

  static const _symbols = ['❌', '⭕'];

  @override
  Widget build(BuildContext context) {
    final s = view.state;
    final current = s.over ? null : s.players[s.turn];
    final canPlay = !view.spectator && current == view.me;
    return Column(
      children: [
        TurnBanner(
          players: s.players,
          current: current,
          me: view.me,
          winner: s.winner,
          draw: s.full && s.winner == null,
          symbols: _symbols,
          passAndPlay: view.passAndPlay,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: s.size,
                      mainAxisSpacing: s.size > 5 ? 4 : 8,
                      crossAxisSpacing: s.size > 5 ? 4 : 8,
                    ),
                    itemCount: s.cells.length,
                    itemBuilder: (context, i) {
                      final v = s.cells[i];
                      final winning = s.line.contains(i);
                      return GestureDetector(
                        onTap: canPlay && v == -1
                            ? () {
                                HapticFeedback.selectionClick();
                                view.send('move', {'cell': i});
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: winning ? AppColors.gold.withValues(alpha: 0.35) : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(s.size > 5 ? 8 : 16),
                          ),
                          child: v == -1
                              ? null
                              : FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(_symbols[v], style: const TextStyle(fontSize: 48)),
                                  ),
                                ),
                        ),
                      );
                    },
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
