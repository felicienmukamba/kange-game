import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../../multiplayer/domain/lockstep.dart';
import 'board_widgets.dart';

typedef CheckersMove = ({int from, int to, int? captured});

class CheckersState {
  const CheckersState({
    required this.players,
    required this.board,
    this.turn = 0,
    this.chain,
    this.winner,
    this.quietMoves = 0,
    this.draw = false,
  });

  final List<String> players;

  /// 0 empty · 1 man / 2 king of player 0 (bottom) · 3 man / 4 king of player 1 (top).
  final List<int> board;
  final int turn;

  /// Square of a piece in the middle of a multi-capture: it must keep capturing.
  final int? chain;
  final String? winner;
  final int quietMoves;
  final bool draw;

  bool get over => winner != null || draw;

  static int owner(int v) => v == 1 || v == 2 ? 0 : (v == 3 || v == 4 ? 1 : -1);

  static bool isKing(int v) => v == 2 || v == 4;
}

/// English draughts (dames) on 8×8: forced captures, multi-jumps, kings.
/// Draw after 60 moves without a capture.
class CheckersGame extends LockstepGame<CheckersState> {
  const CheckersGame(super.game);

  @override
  bool get supportsBots => true;

  @override
  CheckersState initial(List<String> players, int seed) {
    final board = List.filled(64, 0);
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r + c).isOdd) {
          if (r < 3) board[r * 8 + c] = 3;
          if (r > 4) board[r * 8 + c] = 1;
        }
      }
    }
    return CheckersState(players: players.take(2).toList(), board: board);
  }

  static List<(int, int)> _dirs(int v) => switch (v) {
        1 => const [(-1, -1), (-1, 1)],
        3 => const [(1, -1), (1, 1)],
        _ => const [(-1, -1), (-1, 1), (1, -1), (1, 1)],
      };

  static List<CheckersMove> _capturesFrom(List<int> b, int sq) {
    final v = b[sq];
    final me = CheckersState.owner(v);
    final r = sq ~/ 8, c = sq % 8;
    final moves = <CheckersMove>[];
    for (final (dr, dc) in _dirs(v)) {
      final mr = r + dr, mc = c + dc, tr = r + 2 * dr, tc = c + 2 * dc;
      if (tr < 0 || tr > 7 || tc < 0 || tc > 7) continue;
      final mid = b[mr * 8 + mc];
      if (CheckersState.owner(mid) == 1 - me && b[tr * 8 + tc] == 0) {
        moves.add((from: sq, to: tr * 8 + tc, captured: mr * 8 + mc));
      }
    }
    return moves;
  }

  static List<CheckersMove> _stepsFrom(List<int> b, int sq) {
    final r = sq ~/ 8, c = sq % 8;
    return [
      for (final (dr, dc) in _dirs(b[sq]))
        if (r + dr >= 0 && r + dr <= 7 && c + dc >= 0 && c + dc <= 7 && b[(r + dr) * 8 + c + dc] == 0)
          (from: sq, to: (r + dr) * 8 + c + dc, captured: null),
    ];
  }

  /// All legal moves for the player to move (captures are mandatory).
  static List<CheckersMove> legalMoves(CheckersState s) {
    if (s.over) return const [];
    if (s.chain != null) return _capturesFrom(s.board, s.chain!);
    final captures = <CheckersMove>[];
    final steps = <CheckersMove>[];
    for (var sq = 0; sq < 64; sq++) {
      if (CheckersState.owner(s.board[sq]) != s.turn) continue;
      captures.addAll(_capturesFrom(s.board, sq));
      if (captures.isEmpty) steps.addAll(_stepsFrom(s.board, sq));
    }
    return captures.isNotEmpty ? captures : steps;
  }

  @override
  CheckersState apply(CheckersState s, RoomAction a) {
    if (s.over) return s;
    if (a.type == RoomAction.left) {
      final idx = s.players.indexOf(a.sender);
      return idx < 0 ? s : _with(s, winner: s.players[1 - idx]);
    }
    if (a.type != 'move' || s.players.indexOf(a.sender) != s.turn) return s;
    final from = a.data.integer('from', -1), to = a.data.integer('to', -1);
    final move = legalMoves(s).where((m) => m.from == from && m.to == to).firstOrNull;
    if (move == null) return s;

    final b = List.of(s.board);
    var piece = b[from];
    b[from] = 0;
    if (move.captured != null) b[move.captured!] = 0;
    final row = to ~/ 8;
    final promoted = (piece == 1 && row == 0) || (piece == 3 && row == 7);
    if (promoted) piece += 1;
    b[to] = piece;

    final quiet = move.captured == null ? s.quietMoves + 1 : 0;
    if (move.captured != null && !promoted && _capturesFrom(b, to).isNotEmpty) {
      return CheckersState(players: s.players, board: b, turn: s.turn, chain: to, quietMoves: quiet);
    }
    final next = CheckersState(players: s.players, board: b, turn: 1 - s.turn, quietMoves: quiet);
    if (legalMoves(next).isEmpty) return _with(next, winner: s.players[s.turn]);
    if (quiet >= 60) return _with(next, draw: true);
    return next;
  }

  static CheckersState _with(CheckersState s, {String? winner, bool draw = false}) => CheckersState(
        players: s.players,
        board: s.board,
        turn: s.turn,
        winner: winner,
        draw: draw,
        quietMoves: s.quietMoves,
      );

  @override
  bool isFinished(CheckersState s) => s.over;

  @override
  Map<String, int> scores(CheckersState s) => {for (final p in s.players) p: p == s.winner ? 1 : 0};

  @override
  String? turnOf(CheckersState s) => s.over ? null : s.players[s.turn];

  @override
  (String, Json)? botMove(CheckersState s, String bot, SeededRandom random) {
    if (s.over || s.players[s.turn] != bot) return null;
    final moves = legalMoves(s);
    if (moves.isEmpty) return null;
    var best = <CheckersMove>[];
    var bestScore = -1 << 20;
    for (final m in moves) {
      var score = 0;
      final piece = s.board[m.from];
      if (m.captured != null) score += 10 + (CheckersState.isKing(s.board[m.captured!]) ? 5 : 0);
      final row = m.to ~/ 8;
      if ((piece == 1 && row == 0) || (piece == 3 && row == 7)) score += 8;
      // Avoid landing where the opponent can jump us right away.
      final after = apply(s, RoomAction(seq: 0, sender: bot, type: 'move', data: {'from': m.from, 'to': m.to}));
      if (after.turn != s.turn && legalMoves(after).any((r) => r.captured == m.to)) score -= 9;
      if (score > bestScore) {
        bestScore = score;
        best = [m];
      } else if (score == bestScore) {
        best.add(m);
      }
    }
    final pick = best[random.nextInt(best.length)];
    return ('move', {'from': pick.from, 'to': pick.to});
  }

  @override
  Widget buildView(BuildContext context, LockstepView<CheckersState> view) => _CheckersView(view: view);
}

class _CheckersView extends StatefulWidget {
  const _CheckersView({required this.view});

  final LockstepView<CheckersState> view;

  @override
  State<_CheckersView> createState() => _CheckersViewState();
}

class _CheckersViewState extends State<_CheckersView> {
  int? _selected;

  @override
  void didUpdateWidget(_CheckersView old) {
    super.didUpdateWidget(old);
    if (old.view.state != widget.view.state) _selected = widget.view.state.chain;
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final s = view.state;
    final current = s.over ? null : s.players[s.turn];
    final canPlay = !view.spectator && current == view.me;
    final legal = canPlay ? CheckersGame.legalMoves(s) : const <CheckersMove>[];
    final movable = legal.map((m) => m.from).toSet();
    final targets = legal.where((m) => m.from == _selected).map((m) => m.to).toSet();
    // Player 1 sees the board from their side.
    final flip = s.players.indexOf(view.me) == 1 && !view.passAndPlay;

    return Column(
      children: [
        TurnBanner(players: s.players, current: current, me: view.me, winner: s.winner, draw: s.draw, symbols: const ['⚪', '⚫'], passAndPlay: view.passAndPlay),
        if (s.chain != null && canPlay)
          const Text('Prise multiple : continue avec le même pion !', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w800)),
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
                    final sq = flip ? 63 - i : i;
                    final dark = ((sq ~/ 8) + (sq % 8)).isOdd;
                    final v = s.board[sq];
                    return GestureDetector(
                      onTap: () {
                        if (!canPlay) return;
                        if (targets.contains(sq)) {
                          HapticFeedback.selectionClick();
                          view.send('move', {'from': _selected!, 'to': sq});
                        } else if (movable.contains(sq)) {
                          setState(() => _selected = sq);
                        }
                      },
                      child: Container(
                        color: targets.contains(sq)
                            ? AppColors.success.withValues(alpha: 0.5)
                            : (dark ? const Color(0xFF6B4226) : const Color(0xFFE8D2A6)),
                        child: v == 0
                            ? null
                            : Padding(
                                padding: const EdgeInsets.all(5),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CheckersState.owner(v) == 0 ? const Color(0xFFF5F5F5) : const Color(0xFF1F1F1F),
                                    border: Border.all(
                                      color: sq == _selected
                                          ? AppColors.secondary
                                          : (movable.contains(sq) ? AppColors.gold : Colors.black26),
                                      width: sq == _selected || movable.contains(sq) ? 3 : 1,
                                    ),
                                  ),
                                  child: CheckersState.isKing(v) ? const FittedBox(child: Text('👑')) : null,
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
      ],
    );
  }
}
