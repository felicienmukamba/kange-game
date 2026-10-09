import 'package:flutter/widgets.dart';

import '../../../core/utils/json.dart';
import '../../../core/utils/seeded_random.dart';
import '../../catalog/domain/catalog.dart';

/// One ordered action in a match (from the server log, or generated locally).
@immutable
class RoomAction {
  const RoomAction({required this.seq, required this.sender, required this.type, this.data = const {}, this.serverTime = 0});

  factory RoomAction.fromJson(Json j) => RoomAction(
        seq: j.integer('seq'),
        sender: j.str('sender'),
        type: j.str('type'),
        data: j.obj('data'),
        serverTime: j.integer('serverTime'),
      );

  final int seq;
  final String sender;
  final String type;
  final Json data;
  final int serverTime;

  /// Server-generated action: the sender left the match.
  static const left = '_left';
}

/// What a view can do: read the state and send actions.
@immutable
class LockstepView<S> {
  const LockstepView({
    required this.state,
    required this.me,
    required this.players,
    required this.send,
    this.spectator = false,
    this.passAndPlay = false,
  });

  final S state;

  /// The player this device acts as (the current turn's player in pass & play).
  final String me;
  final List<String> players;
  final bool spectator;

  /// Pass & play: several people share this device.
  final bool passAndPlay;
  final void Function(String type, [Json data]) send;
}

/// A multiplayer game expressed as pure, deterministic rules.
///
/// The same implementation runs:
/// * online — every client replays the server-ordered action log,
/// * locally against bots ([botMove]),
/// * in pass & play on one device.
///
/// [apply] must be pure: same state + same action ⇒ same result on every
/// device, and invalid actions must return the state unchanged.
abstract class LockstepGame<S> {
  const LockstepGame(this.game);

  final GameDefinition game;

  int get minPlayers => 2;

  int get maxPlayers => 2;

  /// Whether bots can fill empty seats for a solo game.
  bool get supportsBots => false;

  S initial(List<String> players, int seed);

  S apply(S state, RoomAction action);

  bool isFinished(S state);

  /// Final (or running) score per player.
  Map<String, int> scores(S state);

  /// Whose turn it is, or `null` for simultaneous games.
  String? turnOf(S state) => null;

  /// The action a bot named [bot] takes now, or `null` to wait.
  (String, Json)? botMove(S state, String bot, SeededRandom random) => null;

  Widget buildView(BuildContext context, LockstepView<S> view);

  // ---- type-erased entry points used by hosts (which only know `Object?`)

  Object? initialErased(List<String> players, int seed) => initial(players, seed);

  Object? applyErased(Object? state, RoomAction action) => apply(state as S, action);

  bool isFinishedErased(Object? state) => isFinished(state as S);

  Map<String, int> scoresErased(Object? state) => scores(state as S);

  String? turnOfErased(Object? state) => turnOf(state as S);

  (String, Json)? botMoveErased(Object? state, String bot, SeededRandom random) => botMove(state as S, bot, random);

  Widget render(
    BuildContext context, {
    required Object? state,
    required String me,
    required List<String> players,
    required void Function(String type, [Json data]) send,
    bool spectator = false,
    bool passAndPlay = false,
  }) =>
      buildView(
        context,
        LockstepView<S>(
          state: state as S,
          me: me,
          players: players,
          send: send,
          spectator: spectator,
          passAndPlay: passAndPlay,
        ),
      );
}

/// Ranks players by score, best first.
List<MapEntry<String, int>> ranking(Map<String, int> scores) =>
    scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
