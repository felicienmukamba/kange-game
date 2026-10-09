import '../../../core/utils/json.dart';
import '../../../core/utils/seeded_random.dart';

class QuizItem {
  const QuizItem(this.question, this.options, this.answer);

  factory QuizItem.fromJson(Json j) => QuizItem(j.str('q'), j.strList('o'), j.integer('a'));

  final String question;
  final List<String> options;
  final int answer;

  /// Same question with options shuffled (answer index follows).
  QuizItem shuffled(SeededRandom rnd) {
    final order = List.generate(options.length, (i) => i);
    rnd.shuffle(order);
    return QuizItem(question, [for (final i in order) options[i]], order.indexOf(answer));
  }
}

class GuessItem {
  const GuessItem(this.clues, this.answer, this.alternatives);

  factory GuessItem.fromJson(Json j) => GuessItem(j.strList('c'), j.str('a'), j.strList('alt'));

  final List<String> clues;
  final String answer;
  final List<String> alternatives;

  Iterable<String> get accepted => [answer, ...alternatives];
}

class PixelItem {
  const PixelItem(this.emoji, this.answer, this.decoys);

  factory PixelItem.fromJson(Json j) => PixelItem(j.str('e'), j.str('a'), j.strList('o'));

  final String emoji;
  final String answer;
  final List<String> decoys;
}

class Statement {
  const Statement(this.text, this.isTrue);

  final String text;
  final bool isTrue;
}

/// A vote prompt: question + 2-4 options. Two-element "this or that" pairs use a default question.
class PollItem {
  const PollItem(this.question, this.options);

  factory PollItem.fromList(List<dynamic> raw, {required bool pair}) {
    final parts = raw.map((e) => e.toString()).toList();
    if (pair) return PollItem('Tu préfères…', parts);
    return PollItem(parts.first, parts.sublist(1));
  }

  final String question;
  final List<String> options;
}

class GameContent {
  GameContent({
    required this.quiz,
    required this.guess,
    required this.hangman,
    required this.categories,
    required this.typing,
    required this.drawing,
    required this.pixel,
    required this.oddPairs,
    required this.trueFalse,
    required this.polls,
    required this.personalityResults,
    required this.truths,
    required this.dares,
    required this.streamerDares,
    required this.performance,
    required this.storyStarters,
    required this.storyIdeas,
    required this.storyWords,
    required this.missions,
  });

  factory GameContent.fromJson({required Json quiz, required Json guess, required Json words, required Json party}) {
    final tf = party.obj('true_false');
    final polls = party.obj('polls');
    return GameContent(
      quiz: {for (final e in quiz.entries) e.key: asObjList(e.value).map(QuizItem.fromJson).toList()},
      guess: {for (final e in guess.entries) e.key: asObjList(e.value).map(GuessItem.fromJson).toList()},
      hangman: {for (final e in words.obj('hangman').entries) e.key: (e.value as List).map((w) => w.toString()).toList()},
      categories: {
        for (final e in words.obj('categories').entries) e.key: (e.value as List).map((w) => w.toString()).toSet()
      },
      typing: words.strList('typing'),
      drawing: words.strList('drawing'),
      pixel: words.objList('pixel').map(PixelItem.fromJson).toList(),
      oddPairs: words.list('odd').whereType<List<dynamic>>().map((p) => (p[0].toString(), p[1].toString())).toList(),
      trueFalse: {
        for (final e in tf.entries)
          e.key: (e.value as List)
              .whereType<List<dynamic>>()
              .map((s) => Statement(s[0].toString(), s[1] == true))
              .toList()
      },
      polls: {
        for (final e in polls.entries)
          e.key: (e.value as List)
              .whereType<List<dynamic>>()
              .map((p) => PollItem.fromList(p, pair: e.key == 'this_or_that' || e.key == 'dilemmes'))
              .toList()
      },
      personalityResults: {
        for (final e in party.obj('personality_results').entries)
          e.key: ((e.value as List)[0].toString(), (e.value as List)[1].toString())
      },
      truths: party.strList('truth'),
      dares: party.strList('dare'),
      streamerDares: party.strList('streamer_dares'),
      performance: {for (final e in party.obj('performance').entries) e.key: (e.value as List).map((s) => s.toString()).toList()},
      storyStarters: party.obj('story').strList('starters'),
      storyIdeas: party.obj('story').strList('ideas'),
      storyWords: party.obj('story').strList('words'),
      missions: party.strList('missions'),
    );
  }

  final Map<String, List<QuizItem>> quiz;
  final Map<String, List<GuessItem>> guess;
  final Map<String, List<String>> hangman;
  final Map<String, Set<String>> categories;
  final List<String> typing;
  final List<String> drawing;
  final List<PixelItem> pixel;
  final List<(String, String)> oddPairs;
  final Map<String, List<Statement>> trueFalse;
  final Map<String, List<PollItem>> polls;
  final Map<String, (String, String)> personalityResults;
  final List<String> truths;
  final List<String> dares;
  final List<String> streamerDares;
  final Map<String, List<String>> performance;
  final List<String> storyStarters;
  final List<String> storyIdeas;
  final List<String> storyWords;
  final List<String> missions;

  List<QuizItem> quizTopic(String? topic) => quiz[topic] ?? quiz['culture'] ?? const [];

  List<GuessItem> guessPack(String? pack) => guess[pack] ?? guess['devinettes'] ?? const [];

  List<Statement> statements(String? pack) => trueFalse[pack] ?? trueFalse['general'] ?? const [];

  List<PollItem> pollPack(String? pack) => polls[pack] ?? polls['dilemmes'] ?? const [];

  List<String> performancePrompts(String? theme) => performance[theme] ?? performance['talent'] ?? const [];

  /// Every quiz question, across topics (for "culture" mixes and the AI-less fallback).
  List<QuizItem> get allQuiz => [for (final list in quiz.values) ...list];
}
