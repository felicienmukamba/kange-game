import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/json.dart';
import '../domain/catalog.dart';

/// Loads the bundled catalogue once; parsing runs off the UI isolate.
class CatalogRepository {
  CatalogRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/catalog/catalog.json';

  final AssetBundle _bundle;
  Future<Catalog>? _catalog;

  Future<Catalog> load() => _catalog ??= _read();

  Future<Catalog> _read() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      return await compute(_parse, raw);
    } catch (e) {
      _catalog = null;
      throw const UnexpectedFailure('Impossible de charger le catalogue des jeux.');
    }
  }

  static Catalog _parse(String raw) => Catalog.fromJson(asObj(jsonDecode(raw)));
}
