import 'package:chess/chess.dart' as ch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../../multiplayer/domain/lockstep.dart';
import 'board_widgets.dart';

class ChessState {
  const ChessState({required this.players, required this.fen, this.lastFrom, this.lastTo, this.winner, this.draw = false, this.moves = 0});

  final List<String> players; // [white, black]
  final String fen;
  final String? lastFrom;
  final String? lastTo;
  final String? winner;
  final bool draw;
  final int moves;

  bool get over => winner != null || draw;

  int get turn => fen.split(' ')[1] == 'w' ? 0 : 1;
}

/// Chess with full rules (via the `chess` package). The bot searches 2 plies on material.
class ChessGame extends LockstepGame<ChessState> {
  const ChessGame(super.game);

  @override
  bool get supportsBots => true;

  @override
  ChessState initial(List<String> players, int seed) => ChessState(players: players.take(2).toList(), fen: ch.Chess.DEFAULT_POSITION);

  @override
  ChessState apply(ChessState s, RoomAction a) {
    if (s.over) return s;
    if (a.type == RoomAction.left) {
      final idx = s.players.indexOf(a.sender);
      return idx < 0 ? s : ChessState(players: s.players, fen: s.fen, winner: s.players[1 - idx], moves: s.moves);
    }
    if (a.type != 'move' || s.players.indexOf(a.sender) != s.turn) return s;
    final board = ch.Chess.fromFEN(s.fen, check_validity: false);
    final from = a.data.str('from'), to = a.data.str('to');
    final ok = board.move({'from': from, 'to': to, 'promotion': a.data.str('promotion', 'q')});
    if (!ok) return s;
    String? winner;
    var draw = false;
    if (board.in_checkmate) {
      winner = s.players[s.turn];
    } else if (board.in_draw || board.in_stalemate) {
      draw = true;
    }
    return ChessState(players: s.players, fen: board.fen, lastFrom: from, lastTo: to, winner: winner, draw: draw, moves: s.moves + 1);
  }

  @override
  bool isFinished(ChessState s) => s.over;

  @override
  Map<String, int> scores(ChessState s) => {for (final p in s.players) p: p == s.winner ? 1 : 0};

  @override
  String? turnOf(ChessState s) => s.over ? null : s.players[s.turn];

  static const _values = {'p': 1, 'n': 3, 'b': 3, 'r': 5, 'q': 9, 'k': 0};

  static int _material(ch.Chess board, ch.Color side) {
    var total = 0;
    for (final sq in ch.Chess.SQUARES.keys) {
      final p = board.get(sq);
      if (p == null) continue;
      final v = _values[p.type.name] ?? 0;
      total += p.color == side ? v : -v;
    }
    return total;
  }

  @override
  (String, Json)? botMove(ChessState s, String bot, SeededRandom random) {
    if (s.over || s.players[s.turn] != bot) return null;
    final board = ch.Chess.fromFEN(s.fen, check_validity: false);
    final side = board.turn;
    final moves = board.generate_moves();
    if (moves.isEmpty) return null;
    var bestScore = -1 << 20;
    final best = <ch.Move>[];
    for (final m in moves) {
      board.make_move(m);
      int score;
      if (board.in_checkmate) {
        score = 1000;
      } else {
        // Assume the opponent replies with its best material capture.
        var worst = 1 << 20;
        final replies = board.generate_moves();
        if (replies.isEmpty) {
          worst = board.in_check ? 1000 : 0;
        }
        for (final r in replies) {
          board.make_move(r);
          final v = board.in_checkmate ? -1000 : _material(board, side);
          board.undo_move();
          if (v < worst) worst = v;
        }
        score = worst;
      }
      board.undo_move();
      if (score > bestScore) {
        bestScore = score;
        best
          ..clear()
          ..add(m);
      } else if (score == bestScore) {
        best.add(m);
      }
    }
    final pick = best[random.nextInt(best.length)];
    return ('move', {'from': pick.fromAlgebraic, 'to': pick.toAlgebraic, 'promotion': 'q'});
  }

  @override
  Widget buildView(BuildContext context, LockstepView<ChessState> view) => _ChessView(view: view);
}

class _ChessView extends StatefulWidget {
  const _ChessView({required this.view});

  final LockstepView<ChessState> view;

  @override
  State<_ChessView> createState() => _ChessViewState();
}

class _ChessViewState extends State<_ChessView> {
  static const _glyphs = {
    'k': ('♔', '♚'),
    'q': ('♕', '♛'),
    'r': ('♖', '♜'),
    'b': ('♗', '♝'),
    'n': ('♘', '♞'),
    'p': ('♙', '♟'),
  };

  String? _selected;

  @override
  void didUpdateWidget(_ChessView old) {
    super.didUpdateWidget(old);
    if (old.view.state.fen != widget.view.state.fen) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final s = view.state;
    final board = ch.Chess.fromFEN(s.fen, check_validity: false);
    final current = s.over ? null : s.players[s.turn];
    final canPlay = !view.spectator && current == view.me;
    final targets = <String>{};
    if (canPlay && _selected != null) {
      for (final m in board.generate_moves({'square': _selected})) {
        targets.add(m.toAlgebraic);
      }
    }
    final flip = s.players.indexOf(view.me) == 1 && !view.passAndPlay;
    final inCheck = !s.over && board.in_check;

    return Column(
      children: [
        TurnBanner(players: s.players, current: current, me: view.me, winner: s.winner, draw: s.draw, symbols: const ['⬜', '⬛'], passAndPlay: view.passAndPlay),
        if (inCheck) const Text('⚠️ Échec !', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900)),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemCount: 64,
                  itemBuilder: (context, i) {
                    final idx = flip ? 63 - i : i;
                    final file = idx % 8, rank = 7 - idx ~/ 8;
                    final sq = '${'abcdefgh'[file]}${rank + 1}';
                    final piece = board.get(sq);
                    final light = (file + rank).isOdd;
                    final last = sq == s.lastFrom || sq == s.lastTo;
                    return GestureDetector(
                      onTap: () {
                        if (!canPlay) return;
                        if (targets.contains(sq)) {
                          HapticFeedback.selectionClick();
                          view.send('move', {'from': _selected!, 'to': sq, 'promotion': 'q'});
                        } else if (piece != null && piece.color == board.turn) {
                          setState(() => _selected = sq);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: sq == _selected
                              ? AppColors.secondary.withValues(alpha: 0.6)
                              : last
                                  ? AppColors.warning.withValues(alpha: 0.45)
                                  : (light ? const Color(0xFFEEEED2) : const Color(0xFF769656)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (piece != null)
                              FittedBox(
                                child: Text(
                                  piece.color == ch.Color.WHITE ? _glyphs[piece.type.name]!.$1 : _glyphs[piece.type.name]!.$2,
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: piece.color == ch.Color.WHITE ? Colors.white : Colors.black,
                                    shadows: const [Shadow(blurRadius: 2, color: Colors.black54)],
                                  ),
                                ),
                              ),
                            if (targets.contains(sq))
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
