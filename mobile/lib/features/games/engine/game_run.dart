import 'package:flutter/foundation.dart';

import '../../../core/utils/seeded_random.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/content.dart';

/// How a finished run went. [rating] (0-100) is the engine-independent
/// performance used for rewards; [score] is the engine's own number.
@immutable
class GameOutcome {
  const GameOutcome({required this.score, required this.rating, this.won = false, this.summary, this.details = const []});

  final int score;
  final int rating;
  final bool won;

  /// Short sentence for the result screen ("8 bonnes réponses sur 10").
  final String? summary;

  /// Extra lines for the result screen (stats, personality profile…).
  final List<String> details;

  /// Maps a ratio (0..1) onto [rating].
  static int ratingOf(num ratio) => (ratio.clamp(0, 1) * 100).round();
}

/// Everything a solo engine needs to run one game.
@immutable
class GameRun {
  const GameRun({
    required this.game,
    required this.seed,
    required this.content,
    required this.onFinish,
    this.isRace = false,
  });

  final GameDefinition game;

  /// Same seed ⇒ same questions / layout. Online races share the room seed.
  final int seed;
  final GameContent content;
  final ValueChanged<GameOutcome> onFinish;

  /// Online race: everyone plays the same seeded run, score compared at the end.
  final bool isRace;

  SeededRandom random([int salt = 0]) => SeededRandom(seed ^ (salt * 0x9E3779B9));

  /// Per-question time limit from the catalogue config, or [fallback] seconds.
  Duration timeLimit(int fallback) => Duration(seconds: game.cfgInt('time', fallback).clamp(2, 300));
}
