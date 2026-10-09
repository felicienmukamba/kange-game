import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/seeded_random.dart';
import '../../../multiplayer/domain/lockstep.dart';
import 'board_widgets.dart';

class RpsState {
  const RpsState({required this.players, this.picks = const {}, this.wins = const {}, this.history = const [], this.winner});

  final List<String> players;

  /// Current round's secret picks (r, p or s).
  final Map<String, String> picks;
  final Map<String, int> wins;

  /// Revealed rounds: [pick of player 0, pick of player 1].
  final List<(String, String)> history;
  final String? winner;

  bool get over => winner != null;
}

/// Pierre-feuille-ciseaux, first to 3 rounds. Both pick in secret; the round
/// resolves when the second pick arrives.
class RpsGame extends LockstepGame<RpsState> {
  const RpsGame(super.game);

  static const target = 3;
  static const emoji = {'r': '✊', 'p': '✋', 's': '✌️'};

  @override
  bool get supportsBots => true;

  @override
  RpsState initial(List<String> players, int seed) =>
      RpsState(players: players.take(2).toList(), wins: {for (final p in players.take(2)) p: 0});

  static int beats(String a, String b) {
    if (a == b) return 0;
    return (a == 'r' && b == 's') || (a == 'p' && b == 'r') || (a == 's' && b == 'p') ? 1 : -1;
  }

  @override
  RpsState apply(RpsState s, RoomAction a) {
    if (s.over || !s.players.contains(a.sender)) return s;
    if (a.type == RoomAction.left) {
      return RpsState(players: s.players, picks: s.picks, wins: s.wins, history: s.history, winner: s.players.firstWhere((p) => p != a.sender));
    }
    final pick = a.data.str('c');
    if (a.type != 'pick' || !emoji.containsKey(pick) || s.picks.containsKey(a.sender)) return s;
    final picks = {...s.picks, a.sender: pick};
    if (picks.length < 2) return RpsState(players: s.players, picks: picks, wins: s.wins, history: s.history);
    final p0 = picks[s.players[0]]!, p1 = picks[s.players[1]]!;
    final result = beats(p0, p1);
    final wins = Map.of(s.wins);
    if (result == 1) wins[s.players[0]] = wins[s.players[0]]! + 1;
    if (result == -1) wins[s.players[1]] = wins[s.players[1]]! + 1;
    final winner = wins.entries.where((e) => e.value >= target).map((e) => e.key).firstOrNull;
    return RpsState(players: s.players, wins: wins, history: [...s.history, (p0, p1)], winner: winner);
  }

  @override
  bool isFinished(RpsState s) => s.over;

  @override
  Map<String, int> scores(RpsState s) => s.wins;

  @override
  (String, Json)? botMove(RpsState s, String bot, SeededRandom random) {
    if (s.over || s.picks.containsKey(bot)) return null;
    return ('pick', {'c': const ['r', 'p', 's'][random.nextInt(3)]});
  }

  @override
  Widget buildView(BuildContext context, LockstepView<RpsState> view) => _RpsView(view: view);
}

class _RpsView extends StatelessWidget {
  const _RpsView({required this.view});

  final LockstepView<RpsState> view;

  @override
  Widget build(BuildContext context) {
    final s = view.state;
    final picked = s.picks.containsKey(view.me);
    final opponentPicked = s.picks.keys.any((p) => p != view.me);
    final last = s.history.isEmpty ? null : s.history.last;
    final i0 = s.players.isNotEmpty ? s.players.first : '';
    final i1 = s.players.length > 1 ? s.players[1] : '';
    return Column(
      children: [
        TurnBanner(
          players: s.players,
          current: picked ? (opponentPicked ? null : 'adversaire') : view.me,
          me: view.me,
          winner: s.winner,
          passAndPlay: view.passAndPlay,
        ),
        ScoreStrip(players: s.players, scores: s.wins),
        Expanded(
          child: Center(
            child: last == null
                ? const Text('Premier à 3 manches 🏆', style: TextStyle(fontSize: 18, color: AppColors.textMuted))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Hand(name: i0, pick: last.$1),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
                          _Hand(name: i1, pick: last.$2),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        switch (RpsGame.beats(last.$1, last.$2)) { 1 => '$i0 gagne la manche', -1 => '$i1 gagne la manche', _ => 'Égalité !' },
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ),
        if (!s.over && !view.spectator)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: picked
                ? Text(opponentPicked ? '…' : '⏳ En attente du choix adverse', style: const TextStyle(color: AppColors.textMuted))
                : Column(
                    children: [
                      if (view.passAndPlay) Text('${view.me}, choisis en secret :', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final c in const ['r', 'p', 's'])
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                view.send('pick', {'c': c});
                              },
                              child: Container(
                                width: 92,
                                height: 92,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                                child: Text(RpsGame.emoji[c]!, style: const TextStyle(fontSize: 46)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _Hand extends StatelessWidget {
  const _Hand({required this.name, required this.pick});

  final String name;
  final String pick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(RpsGame.emoji[pick]!, style: const TextStyle(fontSize: 64)),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
