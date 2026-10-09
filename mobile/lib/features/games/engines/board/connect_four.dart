import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../../multiplayer/domain/lockstep.dart';
import 'board_widgets.dart';

class ConnectFourState {
  const ConnectFourState({required this.players, required this.cells, this.turn = 0, this.winner, this.line = const [], this.last});

  static const cols = 7;
  static const rows = 6;

  final List<String> players;

  /// Row-major, row 0 at the top. -1 empty.
  final List<int> cells;
  final int turn;
  final String? winner;
  final List<int> line;
  final int? last;

  bool get full => !cells.contains(-1);

  bool get over => winner != null || full;

  /// Lowest empty row in [col], or -1 when the column is full.
  int dropRow(int col) {
    for (var r = rows - 1; r >= 0; r--) {
      if (cells[r * cols + col] == -1) return r;
    }
    return -1;
  }
}

/// Puissance 4 — the catalogue's "stratégie rapide" game, with a negamax bot.
class ConnectFourGame extends LockstepGame<ConnectFourState> {
  const ConnectFourGame(super.game);

  static const _cols = ConnectFourState.cols;

  @override
  bool get supportsBots => true;

  @override
  ConnectFourState initial(List<String> players, int seed) =>
      ConnectFourState(players: players.take(2).toList(), cells: List.filled(_cols * ConnectFourState.rows, -1));

  @override
  ConnectFourState apply(ConnectFourState s, RoomAction a) {
    if (s.over) return s;
    if (a.type == RoomAction.left) {
      final idx = s.players.indexOf(a.sender);
      return idx < 0 ? s : ConnectFourState(players: s.players, cells: s.cells, turn: s.turn, winner: s.players[1 - idx]);
    }
    if (a.type != 'drop' || s.players.indexOf(a.sender) != s.turn) return s;
    final col = a.data.integer('col', -1);
    if (col < 0 || col >= _cols) return s;
    final row = s.dropRow(col);
    if (row < 0) return s;
    final cell = row * _cols + col;
    final cells = List.of(s.cells)..[cell] = s.turn;
    final line = _line(cells, cell);
    return ConnectFourState(
      players: s.players,
      cells: cells,
      turn: 1 - s.turn,
      winner: line.isEmpty ? null : s.players[s.turn],
      line: line,
      last: cell,
    );
  }

  static List<int> _line(List<int> cells, int cell) {
    final who = cells[cell];
    final r0 = cell ~/ _cols, c0 = cell % _cols;
    for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (1, -1)]) {
      final line = [cell];
      for (final sign in const [1, -1]) {
        var r = r0 + dr * sign, c = c0 + dc * sign;
        while (r >= 0 && r < ConnectFourState.rows && c >= 0 && c < _cols && cells[r * _cols + c] == who) {
          line.add(r * _cols + c);
          r += dr * sign;
          c += dc * sign;
        }
      }
      if (line.length >= 4) return line;
    }
    return const [];
  }

  @override
  bool isFinished(ConnectFourState s) => s.over;

  @override
  Map<String, int> scores(ConnectFourState s) => {for (final p in s.players) p: p == s.winner ? 1 : 0};

  @override
  String? turnOf(ConnectFourState s) => s.over ? null : s.players[s.turn];

  @override
  (String, Json)? botMove(ConnectFourState s, String bot, SeededRandom random) {
    if (s.over || s.players[s.turn] != bot) return null;
    final me = s.turn;
    var bestScore = -1 << 30;
    final best = <int>[];
    for (final col in _order) {
      final row = s.dropRow(col);
      if (row < 0) continue;
      final cells = List.of(s.cells)..[row * _cols + col] = me;
      final score = -_negamax(cells, 1 - me, row * _cols + col, 4, -1 << 30, 1 << 30);
      if (score > bestScore) {
        bestScore = score;
        best
          ..clear()
          ..add(col);
      } else if (score == bestScore) {
        best.add(col);
      }
    }
    return ('drop', {'col': best[random.nextInt(best.length)]});
  }

  /// Centre-first move ordering makes alpha-beta prune far more.
  static const _order = [3, 2, 4, 1, 5, 0, 6];

  static int _negamax(List<int> cells, int toMove, int last, int depth, int alpha, int beta) {
    if (_line(cells, last).isNotEmpty) return -100000 - depth;
    if (!cells.contains(-1)) return 0;
    if (depth == 0) return _evaluate(cells, toMove);
    var best = -1 << 30;
    for (final col in _order) {
      var row = -1;
      for (var r = ConnectFourState.rows - 1; r >= 0; r--) {
        if (cells[r * _cols + col] == -1) {
          row = r;
          break;
        }
      }
      if (row < 0) continue;
      final cell = row * _cols + col;
      cells[cell] = toMove;
      final score = -_negamax(cells, 1 - toMove, cell, depth - 1, -beta, -alpha);
      cells[cell] = -1;
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  /// Counts open windows of four for [who] minus the opponent's.
  static int _evaluate(List<int> cells, int who) {
    var score = 0;
    for (var r = 0; r < ConnectFourState.rows; r++) {
      for (var c = 0; c < _cols; c++) {
        for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (1, -1)]) {
          final er = r + dr * 3, ec = c + dc * 3;
          if (er < 0 || er >= ConnectFourState.rows || ec < 0 || ec >= _cols) continue;
          var mine = 0, theirs = 0;
          for (var k = 0; k < 4; k++) {
            final v = cells[(r + dr * k) * _cols + c + dc * k];
            if (v == who) mine++;
            if (v == 1 - who) theirs++;
          }
          if (theirs == 0) score += const [0, 1, 8, 60, 0][mine];
          if (mine == 0) score -= const [0, 1, 8, 60, 0][theirs];
        }
      }
    }
    return score;
  }

  @override
  Widget buildView(BuildContext context, LockstepView<ConnectFourState> view) => _ConnectFourView(view: view);
}

class _ConnectFourView extends StatelessWidget {
  const _ConnectFourView({required this.view});

  final LockstepView<ConnectFourState> view;

  static const _colors = [AppColors.danger, AppColors.warning];

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
          symbols: const ['🔴', '🟡'],
          passAndPlay: view.passAndPlay,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: ConnectFourState.cols / ConnectFourState.rows,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      for (var c = 0; c < ConnectFourState.cols; c++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: canPlay && s.dropRow(c) >= 0
                                ? () {
                                    HapticFeedback.selectionClick();
                                    view.send('drop', {'col': c});
                                  }
                                : null,
                            child: Column(
                              children: [
                                for (var r = 0; r < ConnectFourState.rows; r++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: switch (s.cells[r * ConnectFourState.cols + c]) {
                                            -1 => AppColors.background,
                                            final v => _colors[v],
                                          },
                                          border: s.line.contains(r * ConnectFourState.cols + c)
                                              ? Border.all(color: Colors.white, width: 3)
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
