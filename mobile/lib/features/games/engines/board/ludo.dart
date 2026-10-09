import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../../multiplayer/domain/lockstep.dart';
import 'board_widgets.dart';

/// Token progress: -1 in base, 0..50 on the shared track, 51..55 home column, 56 home.
class LudoState {
  const LudoState({
    required this.players,
    required this.seats,
    required this.tokens,
    required this.seed,
    this.turn = 0,
    this.dice,
    this.rolls = 0,
    this.sixes = 0,
    this.winner,
    this.log = '',
  });

  final List<String> players;

  /// Board seat (0 red, 1 green, 2 yellow, 3 blue) of each player.
  final List<int> seats;
  final List<List<int>> tokens;
  final int seed;
  final int turn;

  /// Rolled value waiting for a move, or null when the player must roll.
  final int? dice;
  final int rolls;
  final int sixes;
  final String? winner;
  final String log;

  bool get over => winner != null;

  LudoState copyWith({List<List<int>>? tokens, int? turn, int? dice, bool clearDice = false, int? rolls, int? sixes, String? winner, String? log}) =>
      LudoState(
        players: players,
        seats: seats,
        tokens: tokens ?? this.tokens,
        seed: seed,
        turn: turn ?? this.turn,
        dice: clearDice ? null : (dice ?? this.dice),
        rolls: rolls ?? this.rolls,
        sixes: sixes ?? this.sixes,
        winner: winner ?? this.winner,
        log: log ?? this.log,
      );
}

/// Ludo for 2-4 players. Dice values come from the room seed and the roll count,
/// so every device rolls the same numbers. A 6 is needed to leave the base and
/// grants another roll (three 6s in a row end the turn). Landing on an opponent
/// outside a safe square sends it back to base. First player home with all four wins.
class LudoGame extends LockstepGame<LudoState> {
  const LudoGame(super.game);

  static const home = 56;
  static const _seatColors = [AppColors.danger, AppColors.success, AppColors.warning, Color(0xFF3B82F6)];
  static const _seatNames = ['Rouge', 'Vert', 'Jaune', 'Bleu'];

  @override
  int get maxPlayers => 4;

  @override
  bool get supportsBots => true;

  @override
  LudoState initial(List<String> players, int seed) {
    final ps = players.take(4).toList();
    final seats = switch (ps.length) { 2 => [0, 2], 3 => [0, 1, 2], _ => [0, 1, 2, 3] };
    return LudoState(players: ps, seats: seats.take(ps.length).toList(), tokens: [for (final _ in ps) List.filled(4, -1)], seed: seed);
  }

  static int globalSquare(int seat, int progress) => (seat * 13 + progress) % 52;

  static bool isSafe(int global) => global % 13 == 0 || global % 13 == 8;

  /// Tokens of the current player that can move [dice] squares.
  static List<int> movable(LudoState s, int dice) {
    final mine = s.tokens[s.turn];
    return [
      for (var t = 0; t < 4; t++)
        if ((mine[t] == -1 && dice == 6) || (mine[t] >= 0 && mine[t] + dice <= home)) t,
    ];
  }

  int _roll(LudoState s) => SeededRandom(s.seed ^ (s.rolls * 7919 + 17)).nextInt(6) + 1;

  LudoState _nextTurn(LudoState s, String log) {
    var next = (s.turn + 1) % s.players.length;
    // Skip players who already finished (only matters if the game continues).
    for (var i = 0; i < s.players.length && s.tokens[next].every((p) => p == home || p == -2); i++) {
      next = (next + 1) % s.players.length;
    }
    return s.copyWith(turn: next, clearDice: true, sixes: 0, log: log);
  }

  @override
  LudoState apply(LudoState s, RoomAction a) {
    if (s.over) return s;
    final idx = s.players.indexOf(a.sender);
    if (a.type == RoomAction.left) {
      if (idx < 0) return s;
      final remaining = [for (var i = 0; i < s.players.length; i++) if (i != idx && !s.tokens[i].every((p) => p < -1)) i];
      // A player leaving forfeits: their tokens go back to base for good.
      final tokens = [for (var i = 0; i < s.tokens.length; i++) i == idx ? List.filled(4, -2) : s.tokens[i]];
      var next = s.copyWith(tokens: tokens);
      if (remaining.length == 1) return next.copyWith(winner: s.players[remaining.first]);
      if (s.turn == idx) next = _nextTurn(next, '${a.sender} a quitté la partie');
      return next;
    }
    if (idx != s.turn) return s;

    if (a.type == 'roll' && s.dice == null) {
      final value = _roll(s);
      final sixes = value == 6 ? s.sixes + 1 : 0;
      final rolled = s.copyWith(dice: value, rolls: s.rolls + 1, sixes: sixes, log: '${a.sender} fait $value');
      if (sixes >= 3) return _nextTurn(rolled, 'Trois 6 d\'affilée : tour perdu !');
      if (movable(rolled, value).isEmpty) return _nextTurn(rolled, '${a.sender} fait $value : aucun coup possible');
      return rolled;
    }

    if (a.type == 'move' && s.dice != null) {
      final token = a.data.integer('token', -1);
      final dice = s.dice!;
      if (!movable(s, dice).contains(token)) return s;
      final tokens = [for (final list in s.tokens) List.of(list)];
      final seat = s.seats[s.turn];
      final from = tokens[s.turn][token];
      final to = from == -1 ? 0 : from + dice;
      tokens[s.turn][token] = to;
      var log = '${a.sender} avance de $dice';
      var captured = false;
      if (to <= 50) {
        final g = globalSquare(seat, to);
        if (!isSafe(g)) {
          for (var p = 0; p < s.players.length; p++) {
            if (p == s.turn) continue;
            for (var t = 0; t < 4; t++) {
              final pos = tokens[p][t];
              if (pos >= 0 && pos <= 50 && globalSquare(s.seats[p], pos) == g) {
                tokens[p][t] = -1;
                captured = true;
                log = '💥 ${a.sender} capture un pion de ${s.players[p]} !';
              }
            }
          }
        }
      }
      if (tokens[s.turn].every((p) => p == home)) {
        return s.copyWith(tokens: tokens, winner: a.sender, clearDice: true, log: '🏆 ${a.sender} a ramené tous ses pions !');
      }
      final moved = s.copyWith(tokens: tokens, clearDice: true, log: log);
      // A 6, a capture or reaching home earns another roll.
      if (dice == 6 || captured || to == home) return moved;
      return _nextTurn(moved, log);
    }
    return s;
  }

  @override
  bool isFinished(LudoState s) => s.over;

  @override
  Map<String, int> scores(LudoState s) => {
        for (var i = 0; i < s.players.length; i++)
          s.players[i]: (s.players[i] == s.winner ? 50 : 0) + s.tokens[i].where((p) => p >= 0).fold<int>(0, (a, p) => a + p ~/ 6),
      };

  @override
  String? turnOf(LudoState s) => s.over ? null : s.players[s.turn];

  @override
  (String, Json)? botMove(LudoState s, String bot, SeededRandom random) {
    if (s.over || s.players[s.turn] != bot) return null;
    final dice = s.dice;
    if (dice == null) return ('roll', const {});
    final options = movable(s, dice);
    if (options.isEmpty) return null;
    final seat = s.seats[s.turn];
    var best = options.first;
    var bestScore = -1 << 20;
    for (final t in options) {
      final from = s.tokens[s.turn][t];
      final to = from == -1 ? 0 : from + dice;
      var score = random.nextInt(3);
      if (to == home) score += 50;
      if (from == -1) score += 30;
      if (to <= 50) {
        final g = globalSquare(seat, to);
        for (var p = 0; p < s.players.length; p++) {
          if (p == s.turn) continue;
          for (final pos in s.tokens[p]) {
            if (pos >= 0 && pos <= 50 && globalSquare(s.seats[p], pos) == g && !isSafe(g)) score += 60;
          }
        }
        if (isSafe(g)) score += 10;
      } else {
        score += 20;
      }
      score += to;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }
    return ('move', {'token': best});
  }

  @override
  Widget buildView(BuildContext context, LockstepView<LudoState> view) => _LudoView(view: view);
}

/// Standard 15×15 board: the 52 shared squares, clockwise from red's start.
final List<Point<int>> _track = () {
  final cells = <Point<int>>[];
  void add(int r, int c) => cells.add(Point(r, c));
  for (var c = 1; c <= 5; c++) {
    add(6, c);
  }
  for (var r = 5; r >= 0; r--) {
    add(r, 6);
  }
  add(0, 7);
  add(0, 8);
  for (var r = 1; r <= 5; r++) {
    add(r, 8);
  }
  for (var c = 9; c <= 14; c++) {
    add(6, c);
  }
  add(7, 14);
  add(8, 14);
  for (var c = 13; c >= 9; c--) {
    add(8, c);
  }
  for (var r = 9; r <= 14; r++) {
    add(r, 8);
  }
  add(14, 7);
  add(14, 6);
  for (var r = 13; r >= 9; r--) {
    add(r, 6);
  }
  for (var c = 5; c >= 0; c--) {
    add(8, c);
  }
  add(7, 0);
  add(6, 0);
  return cells;
}();

Point<int> _homeColumn(int seat, int step) => switch (seat) {
      0 => Point(7, step),
      1 => Point(step, 7),
      2 => Point(7, 14 - step),
      _ => Point(14 - step, 7),
    };

const _bases = [Point(1, 1), Point(1, 10), Point(10, 10), Point(10, 1)];

Point<int> _cellOf(int seat, int token, int progress) {
  if (progress < 0) {
    final b = _bases[seat];
    return Point(b.x + 1 + (token ~/ 2) * 2, b.y + 1 + (token % 2) * 2);
  }
  if (progress <= 50) return _track[LudoGame.globalSquare(seat, progress)];
  if (progress < LudoGame.home) return _homeColumn(seat, progress - 50);
  return const Point(7, 7);
}

class _LudoView extends StatelessWidget {
  const _LudoView({required this.view});

  final LockstepView<LudoState> view;

  @override
  Widget build(BuildContext context) {
    final s = view.state;
    final current = s.over ? null : s.players[s.turn];
    final canPlay = !view.spectator && current == view.me;
    final movable = canPlay && s.dice != null ? LudoGame.movable(s, s.dice!).toSet() : <int>{};
    return Column(
      children: [
        TurnBanner(
          players: s.players,
          current: current,
          me: view.me,
          winner: s.winner,
          symbols: [for (final seat in s.seats) const ['🔴', '🟢', '🟡', '🔵'][seat]],
          passAndPlay: view.passAndPlay,
        ),
        Text(s.log, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final cell = box.maxWidth / 15;
                    return Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _LudoBoardPainter())),
                        for (var p = 0; p < s.players.length; p++)
                          for (var t = 0; t < 4; t++)
                            if (s.tokens[p][t] >= -1)
                              Builder(builder: (context) {
                                final seat = s.seats[p];
                                final pos = _cellOf(seat, t, s.tokens[p][t]);
                                final stackOffset = s.tokens[p][t] == LudoGame.home ? (t - 1.5) * cell * 0.18 : 0.0;
                                final active = p == s.turn && movable.contains(t);
                                return AnimatedPositioned(
                                  duration: const Duration(milliseconds: 250),
                                  left: pos.y * cell + cell * 0.1 + stackOffset,
                                  top: pos.x * cell + cell * 0.1,
                                  width: cell * 0.8,
                                  height: cell * 0.8,
                                  child: GestureDetector(
                                    onTap: active
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            view.send('move', {'token': t});
                                          }
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: LudoGame._seatColors[seat],
                                        border: Border.all(color: active ? Colors.white : Colors.black54, width: active ? 3 : 1.5),
                                        boxShadow: active ? [const BoxShadow(color: Colors.white, blurRadius: 8)] : null,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  s.dice == null ? '🎲' : const ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'][s.dice! - 1],
                  style: TextStyle(fontSize: s.dice == null ? 34 : 52, color: Colors.black),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: canPlay && s.dice == null ? () => view.send('roll') : null,
                  child: Text(
                    !canPlay
                        ? 'En attente…'
                        : (s.dice == null ? '🎲 Lancer le dé' : 'Choisis un pion ${LudoGame._seatNames[s.seats[s.turn]].toLowerCase()}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    Rect r(int row, int col, [int h = 1, int w = 1]) => Rect.fromLTWH(col * cell, row * cell, w * cell, h * cell);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), Paint()..color = const Color(0xFFF8F8F8));
    for (var seat = 0; seat < 4; seat++) {
      final b = _bases[seat];
      final color = LudoGame._seatColors[seat];
      canvas.drawRect(r(b.x - 1, b.y - 1, 6, 6), Paint()..color = color);
      canvas.drawRect(r(b.x, b.y, 4, 4), Paint()..color = Colors.white);
      for (var step = 1; step <= 5; step++) {
        final p = _homeColumn(seat, step);
        canvas.drawRect(r(p.x, p.y), Paint()..color = color.withValues(alpha: 0.75));
      }
      final start = _track[seat * 13];
      canvas.drawRect(r(start.x, start.y), Paint()..color = color.withValues(alpha: 0.75));
    }
    final grid = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < _track.length; i++) {
      final p = _track[i];
      canvas.drawRect(r(p.x, p.y), grid);
      if (i % 13 == 8) {
        final tp = TextPainter(text: const TextSpan(text: '⭐', style: TextStyle(fontSize: 12)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(p.y * cell + (cell - tp.width) / 2, p.x * cell + (cell - tp.height) / 2));
        tp.dispose();
      }
    }
    final center = Path()
      ..moveTo(6 * cell, 6 * cell)
      ..lineTo(9 * cell, 6 * cell)
      ..lineTo(9 * cell, 9 * cell)
      ..lineTo(6 * cell, 9 * cell)
      ..close();
    canvas.drawPath(center, Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(_LudoBoardPainter oldDelegate) => false;
}
