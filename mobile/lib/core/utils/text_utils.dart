const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae',
};

/// Lower-cases, strips accents, punctuation and articles so typed answers
/// match generously: « L'Éponge ! » == « eponge ».
String normalizeAnswer(String input) {
  final lower = input.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    buffer.write(_accents[ch] ?? ch);
  }
  var s = buffer.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceFirst(RegExp(r'^(le |la |les |l |un |une |des |du |de |d )'), '');
  return s.replaceAll(' ', '');
}

/// Levenshtein distance, used to forgive small typos.
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// True when [guess] matches one of [answers], allowing one typo per 6 letters.
bool answerMatches(String guess, Iterable<String> answers) {
  final g = normalizeAnswer(guess);
  if (g.isEmpty) return false;
  for (final answer in answers) {
    final a = normalizeAnswer(answer);
    if (a.isEmpty) continue;
    if (g == a) return true;
    final tolerance = a.length ~/ 6;
    if (tolerance > 0 && editDistance(g, a) <= tolerance) return true;
  }
  return false;
}

/// Removes accents and upper-cases (for hangman / anagram letters).
String plainUpper(String input) {
  final buffer = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    buffer.write(_accents[ch] ?? ch);
  }
  return buffer.toString().toUpperCase();
}
