import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/json.dart';
import '../domain/content.dart';

/// Bundled French game content (quiz banks, riddles, words, party prompts).
///
/// Loaded once in a background isolate; afterwards [data] is synchronous so
/// game engines never wait on I/O mid-game.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<GameContent>? _loading;
  GameContent? _data;

  bool get isLoaded => _data != null;

  GameContent get data {
    final d = _data;
    if (d == null) throw StateError('ContentRepository.load() must complete first');
    return d;
  }

  Future<GameContent> load() => _loading ??= _read();

  Future<GameContent> _read() async {
    try {
      final files = await Future.wait([
        _bundle.loadString('assets/content/quiz.json'),
        _bundle.loadString('assets/content/guess.json'),
        _bundle.loadString('assets/content/words.json'),
        _bundle.loadString('assets/content/party.json'),
      ]);
      final content = await compute(_parse, files);
      _data = content;
      return content;
    } catch (_) {
      _loading = null;
      throw const UnexpectedFailure('Impossible de charger le contenu des jeux.');
    }
  }

  static GameContent _parse(List<String> files) => GameContent.fromJson(
        quiz: asObj(jsonDecode(files[0])),
        guess: asObj(jsonDecode(files[1])),
        words: asObj(jsonDecode(files[2])),
        party: asObj(jsonDecode(files[3])),
      );
}
