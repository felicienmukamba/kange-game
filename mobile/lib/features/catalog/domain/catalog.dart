import 'package:equatable/equatable.dart';

import '../../../core/utils/json.dart';

class GameCategory extends Equatable {
  const GameCategory({required this.id, required this.emoji, required this.name});

  factory GameCategory.fromJson(Json j) =>
      GameCategory(id: j.integer('id'), emoji: j.str('emoji', '🎮'), name: j.str('name'));

  final int id;
  final String emoji;
  final String name;

  @override
  List<Object?> get props => [id];
}

/// One of the 1000 challenges: a title, its category and the engine that runs it.
class GameDefinition extends Equatable {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.engine,
    this.config = const {},
  });

  factory GameDefinition.fromJson(Json j) => GameDefinition(
        id: j.str('id'),
        title: j.str('t'),
        categoryId: j.integer('c'),
        engine: j.str('e'),
        config: j.obj('cfg'),
      );

  final String id;
  final String title;
  final int categoryId;

  /// Engine id (see `EngineRegistry`).
  final String engine;

  /// Engine-specific options: topic, pack, variant, time…
  final Json config;

  String? cfgStr(String key) => config.strOrNull(key);

  int cfgInt(String key, int fallback) => config.integer(key, fallback);

  bool cfgBool(String key) => config.boolean(key);

  @override
  List<Object?> get props => [id];
}

class Catalog {
  Catalog({required this.categories, required this.games})
      : _byId = {for (final g in games) g.id: g},
        _byCategory = _group(games),
        _categoryById = {for (final c in categories) c.id: c};

  factory Catalog.fromJson(Json j) => Catalog(
        categories: j.objList('categories').map(GameCategory.fromJson).toList(),
        games: j.objList('games').map(GameDefinition.fromJson).toList(),
      );

  final List<GameCategory> categories;
  final List<GameDefinition> games;
  final Map<String, GameDefinition> _byId;
  final Map<int, List<GameDefinition>> _byCategory;
  final Map<int, GameCategory> _categoryById;

  static Map<int, List<GameDefinition>> _group(List<GameDefinition> games) {
    final map = <int, List<GameDefinition>>{};
    for (final g in games) {
      (map[g.categoryId] ??= []).add(g);
    }
    return map;
  }

  GameDefinition? byId(String id) => _byId[id];

  GameCategory? category(int id) => _categoryById[id];

  List<GameDefinition> inCategory(int id) => _byCategory[id] ?? const [];

  /// Playable games only (excludes links to platform screens).
  Iterable<GameDefinition> get playable => games.where((g) => g.engine != 'feature');
}
