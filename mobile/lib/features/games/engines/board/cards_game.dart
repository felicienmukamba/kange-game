import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../../multiplayer/domain/lockstep.dart';
import 'board_widgets.dart';

/// Cards are two-character codes: colour (R, G, B, Y or W for wild) + value
/// (0-9, `+` draw two, `S` skip, `I` reverse, `W` joker, `4` wild draw four).
class CardsState {
  const CardsState({
    required this.players,
    required this.hands,
    required this.drawPile,
    required this.discard,
    required this.color,
    required this.seed,
    this.turn = 0,
    this.direction = 1,
    this.hasDrawn = false,
    this.reshuffles = 0,
    this.winner,
    this.log = '',
  });

  final List<String> players;
  final List<List<String>> hands;
  final List<String> drawPile;
  final List<String> discard;

  /// Active colour (a wild card sets it).
  final String color;
  final int seed;
  final int turn;
  final int direction;
  final bool hasDrawn;
  final int reshuffles;
  final String? winner;
  final String log;

  String get top => discard.last;

  bool get over => winner != null;

  bool playable(String card) => card[0] == 'W' || card[0] == color || card[1] == top[1];
}

/// "Couleurs" — a UNO-style shedding game for 2-6 players with a deterministic deck.
class CardsGame extends LockstepGame<CardsState> {
  const CardsGame(super.game);

  static const colors = ['R', 'G', 'B', 'Y'];
  static const _handSize = 7;

  @override
  int get maxPlayers => 6;

  @override
  bool get supportsBots => true;

  static List<String> buildDeck() => [
        for (final c in colors) ...[
          '${c}0',
          for (var v = 1; v <= 9; v++) ...['$c$v', '$c$v'],
          for (final a in ['+', 'S', 'I']) ...['$c$a', '$c$a'],
        ],
        for (var i = 0; i < 4; i++) ...['WW', 'W4'],
      ];

  @override
  CardsState initial(List<String> players, int seed) {
    final ps = players.take(maxPlayers).toList();
    final deck = buildDeck();
    SeededRandom(seed).shuffle(deck);
    final hands = [for (var p = 0; p < ps.length; p++) deck.sublist(p * _handSize, (p + 1) * _handSize)];
    final rest = deck.sublist(ps.length * _handSize);
    // The first discard must be a plain number card.
    final firstIndex = rest.indexWhere((c) => c[0] != 'W' && int.tryParse(c[1]) != null);
    final first = rest.removeAt(firstIndex);
    return CardsState(players: ps, hands: hands, drawPile: rest, discard: [first], color: first[0], seed: seed);
  }

  int _next(CardsState s, [int steps = 1]) => (s.turn + s.direction * steps) % s.players.length;

  /// Draws [n] cards for [player], reshuffling the discard pile when needed.
  ({List<List<String>> hands, List<String> pile, List<String> discard, int reshuffles}) _draw(CardsState s, int player, int n) {
    final hands = [for (final h in s.hands) List.of(h)];
    var pile = List.of(s.drawPile);
    var discard = List.of(s.discard);
    var reshuffles = s.reshuffles;
    for (var i = 0; i < n; i++) {
      if (pile.isEmpty) {
        if (discard.length <= 1) break;
        pile = discard.sublist(0, discard.length - 1);
        discard = [discard.last];
        reshuffles++;
        SeededRandom(s.seed ^ (reshuffles * 104729)).shuffle(pile);
      }
      hands[player].add(pile.removeLast());
    }
    return (hands: hands, pile: pile, discard: discard, reshuffles: reshuffles);
  }

  @override
  CardsState apply(CardsState s, RoomAction a) {
    if (s.over) return s;
    final idx = s.players.indexOf(a.sender);
    if (a.type == RoomAction.left) {
      if (idx < 0 || s.players.length <= 1) return s;
      // The leaver's cards go under the draw pile; if only one player remains they win.
      final players = List.of(s.players)..removeAt(idx);
      final hands = [for (var i = 0; i < s.hands.length; i++) if (i != idx) s.hands[i]];
      final pile = [...s.hands[idx], ...s.drawPile];
      var turn = s.turn > idx ? s.turn - 1 : s.turn;
      turn %= players.length;
      return CardsState(
        players: players,
        hands: hands,
        drawPile: pile,
        discard: s.discard,
        color: s.color,
        seed: s.seed,
        turn: turn,
        direction: s.direction,
        reshuffles: s.reshuffles,
        winner: players.length == 1 ? players.first : null,
        log: '${a.sender} a quitté la partie',
      );
    }
    if (idx != s.turn) return s;

    switch (a.type) {
      case 'draw' when !s.hasDrawn:
        final d = _draw(s, idx, 1);
        return _copy(s, hands: d.hands, drawPile: d.pile, discard: d.discard, reshuffles: d.reshuffles, hasDrawn: true, log: '${a.sender} pioche');
      case 'pass' when s.hasDrawn:
        return _copy(s, turn: _next(s), hasDrawn: false, log: '${a.sender} passe');
      case 'play':
        final card = a.data.str('card');
        if (!s.hands[idx].contains(card) || !s.playable(card)) return s;
        final hand = List.of(s.hands[idx])..remove(card);
        final hands = [for (var i = 0; i < s.hands.length; i++) i == idx ? hand : s.hands[i]];
        final chosen = a.data.str('color');
        final color = card[0] == 'W' ? (colors.contains(chosen) ? chosen : 'R') : card[0];
        var next = _copy(s, hands: hands, discard: [...s.discard, card], color: color, hasDrawn: false, log: '${a.sender} joue ${cardLabel(card)}');
        if (hand.isEmpty) return _copy(next, winner: a.sender, log: '🏆 ${a.sender} n\'a plus de cartes !');
        final twoPlayers = s.players.length == 2;
        switch (card[1]) {
          case '+' || '4':
            final victim = _next(next);
            final d = _draw(next, victim, card[1] == '+' ? 2 : 4);
            next = _copy(next, hands: d.hands, drawPile: d.pile, discard: d.discard, reshuffles: d.reshuffles, turn: _next(next, 2));
          case 'S':
            next = _copy(next, turn: _next(next, 2));
          case 'I':
            next = twoPlayers ? _copy(next, turn: _next(next, 2)) : _copy(next, direction: -s.direction, turn: (s.turn - s.direction) % s.players.length);
          default:
            next = _copy(next, turn: _next(next));
        }
        return next;
    }
    return s;
  }

  static CardsState _copy(
    CardsState s, {
    List<List<String>>? hands,
    List<String>? drawPile,
    List<String>? discard,
    String? color,
    int? turn,
    int? direction,
    bool? hasDrawn,
    int? reshuffles,
    String? winner,
    String? log,
  }) =>
      CardsState(
        players: s.players,
        hands: hands ?? s.hands,
        drawPile: drawPile ?? s.drawPile,
        discard: discard ?? s.discard,
        color: color ?? s.color,
        seed: s.seed,
        turn: turn ?? s.turn,
        direction: direction ?? s.direction,
        hasDrawn: hasDrawn ?? s.hasDrawn,
        reshuffles: reshuffles ?? s.reshuffles,
        winner: winner ?? s.winner,
        log: log ?? s.log,
      );

  static String cardLabel(String card) => switch (card[1]) {
        '+' => '+2',
        'S' => '⊘',
        'I' => '⇄',
        'W' => '🌈',
        '4' => '+4',
        final v => v,
      };

  @override
  bool isFinished(CardsState s) => s.over;

  @override
  Map<String, int> scores(CardsState s) {
    final others = s.hands.fold<int>(0, (a, h) => a + h.length);
    return {
      for (var i = 0; i < s.players.length; i++)
        s.players[i]: s.players[i] == s.winner ? 30 + others : (20 - s.hands[i].length).clamp(0, 20),
    };
  }

  @override
  String? turnOf(CardsState s) => s.over ? null : s.players[s.turn];

  @override
  (String, Json)? botMove(CardsState s, String bot, SeededRandom random) {
    if (s.over || s.players[s.turn] != bot) return null;
    final hand = s.hands[s.turn];
    final options = hand.where(s.playable).toList();
    if (options.isEmpty) return s.hasDrawn ? ('pass', const {}) : ('draw', const {});
    // Keep wild cards for later; prefer action cards against a player close to winning.
    final nextHand = s.hands[(s.turn + s.direction) % s.players.length].length;
    options.sort((a, b) {
      int rank(String c) => c[0] == 'W' ? 0 : (nextHand <= 2 && !RegExp(r'\d').hasMatch(c[1]) ? 3 : 1 + random.nextInt(2));
      return rank(b).compareTo(rank(a));
    });
    final card = options.first;
    final counts = {for (final c in colors) c: hand.where((h) => h[0] == c).length};
    final color = (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    return ('play', {'card': card, 'color': color});
  }

  @override
  Widget buildView(BuildContext context, LockstepView<CardsState> view) => _CardsView(view: view);
}

Color cardColor(String c) => switch (c) {
      'R' => AppColors.danger,
      'G' => AppColors.success,
      'B' => const Color(0xFF3B82F6),
      'Y' => AppColors.warning,
      _ => const Color(0xFF27272A),
    };

class PlayingCard extends StatelessWidget {
  const PlayingCard({super.key, required this.card, this.width = 64, this.highlight = false, this.dimmed = false});

  final String card;
  final double width;
  final bool highlight;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: width,
        height: width * 1.45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor(card[0]),
          borderRadius: BorderRadius.circular(width * 0.16),
          border: Border.all(color: highlight ? Colors.white : Colors.black26, width: highlight ? 3 : 1),
          boxShadow: highlight ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10)] : null,
        ),
        child: Text(CardsGame.cardLabel(card), style: TextStyle(fontSize: width * 0.42, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}

class _CardsView extends StatefulWidget {
  const _CardsView({required this.view});

  final LockstepView<CardsState> view;

  @override
  State<_CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends State<_CardsView> {
  /// Pass & play: the hand stays hidden until the right person confirms.
  String? _revealedFor;

  Future<void> _play(String card) async {
    var color = '';
    if (card[0] == 'W') {
      final picked = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisis une couleur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final c in CardsGame.colors)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, c),
                      child: CircleAvatar(radius: 30, backgroundColor: cardColor(c)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      color = picked;
    }
    HapticFeedback.selectionClick();
    widget.view.send('play', {'card': card, 'color': color});
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final s = view.state;
    final current = s.over ? null : s.players[s.turn];
    final meIndex = s.players.indexOf(view.me);
    final canPlay = !view.spectator && current == view.me;
    final hidden = view.passAndPlay && _revealedFor != view.me && !s.over;
    final hand = meIndex < 0 ? <String>[] : (List.of(s.hands[meIndex])..sort());

    return Column(
      children: [
        TurnBanner(players: s.players, current: current, me: view.me, winner: s.winner, passAndPlay: view.passAndPlay),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (var i = 0; i < s.players.length; i++)
                if (s.players[i] != view.me || view.passAndPlay)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == s.turn ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${s.players[i]} · 🂠 ${s.hands[i].length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 70,
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                        child: Text('${s.drawPile.length}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                      ),
                      const SizedBox(height: 4),
                      const Text('Pioche', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  PlayingCard(card: s.top, width: 84),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      CircleAvatar(radius: 14, backgroundColor: cardColor(s.color)),
                      const SizedBox(height: 4),
                      Text(s.direction == 1 ? '↻' : '↺', style: const TextStyle(fontSize: 22)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.log, style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
        if (hidden)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => setState(() => _revealedFor = view.me),
              icon: const Icon(Icons.visibility),
              label: Text('Je suis ${view.me} : voir mes cartes'),
            ),
          )
        else ...[
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hand.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final card = hand[i];
                final ok = canPlay && s.playable(card);
                return GestureDetector(
                  onTap: ok ? () => _play(card) : null,
                  child: PlayingCard(card: card, highlight: ok, dimmed: canPlay && !ok),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: canPlay && !s.hasDrawn ? () => view.send('draw') : null, child: const Text('🂠 Piocher'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: canPlay && s.hasDrawn ? () => view.send('pass') : null, child: const Text('⏭️ Passer'))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
