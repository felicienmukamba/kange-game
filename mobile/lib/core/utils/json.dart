/// Typed, null-tolerant readers for decoded JSON.
///
/// Keeps `fromJson` factories short and safe under `strict-casts`:
/// a missing or mistyped field falls back to a default instead of throwing.
typedef Json = Map<String, dynamic>;

extension JsonRead on Json {
  String str(String key, [String fallback = '']) {
    final v = this[key];
    return v is String ? v : (v == null ? fallback : v.toString());
  }

  String? strOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    final s = v is String ? v : v.toString();
    return s.isEmpty ? null : s;
  }

  int integer(String key, [int fallback = 0]) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double dbl(String key, [double fallback = 0]) {
    final v = this[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  bool boolean(String key, [bool fallback = false]) {
    final v = this[key];
    return v is bool ? v : fallback;
  }

  Json obj(String key) {
    final v = this[key];
    return v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
  }

  Json? objOrNull(String key) {
    final v = this[key];
    return v is Map ? v.cast<String, dynamic>() : null;
  }

  List<dynamic> list(String key) {
    final v = this[key];
    return v is List ? v : const [];
  }

  List<Json> objList(String key) => list(key).whereType<Map<dynamic, dynamic>>().map((m) => m.cast<String, dynamic>()).toList();

  List<String> strList(String key) => list(key).map((e) => e.toString()).toList();

  Map<String, int> intMap(String key) {
    final v = this[key];
    if (v is! Map) return const {};
    return {for (final e in v.entries) e.key.toString(): e.value is num ? (e.value as num).toInt() : 0};
  }

  DateTime? date(String key) {
    final v = this[key];
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}

/// Casts a decoded JSON value to a list of objects, ignoring anything else.
List<Json> asObjList(Object? value) =>
    value is List ? value.whereType<Map<dynamic, dynamic>>().map((m) => m.cast<String, dynamic>()).toList() : const [];

/// Casts a decoded JSON value to an object, or an empty one.
Json asObj(Object? value) => value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
