import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../domain/content.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Multiple-choice quiz. Catalogue options:
/// `topic`, `count`, `time`, `suddenDeath`/`elimination`, `shrinking`, `gameShow` (jokers),
/// `combo`, `boss`, `bot`/`duel` (AI opponent), `forfeit` (a gage on wrong answers).
class QuizEngine extends StatefulWidget {
  const QuizEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<QuizEngine> createState() => _QuizEngineState();
}

class _QuizEngineState extends State<QuizEngine> {
  static const _basePoints = 10;
  static const _maxBonus = 10;

  late final List<QuizItem> _questions;
  late final Random _botRandom;
  late final bool _suddenDeath;
  late final bool _jokers;
  late final bool _combo;
  late final bool _shrinking;
  late final bool _bot;
  late final String? _forfeit;
  late final int _baseTime;

  int _index = 0;
  int _score = 0;
  int _correct = 0;
  int _streak = 0;
  int _botScore = 0;
  int? _selected;
  bool _revealed = false;
  bool _fiftyUsed = false;
  bool _skipUsed = false;
  Set<int> _hidden = {};
  final _stopwatch = Stopwatch();
  final _clock = Stopwatch()..start();
  Timer? _next;

  GameRun get run => widget.run;

  @override
  void initState() {
    super.initState();
    final game = run.game;
    final rnd = run.random();
    final topic = game.cfgStr('topic');
    // "Culture générale" draws from every topic for variety.
    final mixed = topic == null || topic == 'culture';
    final pool = List.of(mixed ? run.content.allQuiz : run.content.quizTopic(topic));
    rnd.shuffle(pool);
    final boss = game.cfgBool('boss');
    final count = game.cfgInt('count', boss ? 15 : 10).clamp(1, pool.length);
    _questions = [for (final q in pool.take(count)) q.shuffled(rnd)];
    _suddenDeath = game.cfgBool('suddenDeath') || game.cfgBool('elimination');
    _jokers = game.cfgBool('gameShow');
    _combo = game.cfgBool('combo');
    _shrinking = game.cfgBool('shrinking');
    _bot = game.cfgBool('bot') || game.cfgBool('duel');
    _forfeit = game.cfgStr('forfeit');
    _baseTime = game.cfgInt('time', boss ? 8 : 15);
    _botRandom = Random(run.seed);
    _stopwatch.start();
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  QuizItem get _q => _questions[_index];

  Duration get _timeLimit {
    final seconds = _shrinking ? max(3, _baseTime - _index) : _baseTime;
    return Duration(seconds: seconds);
  }

  void _answer(int? choice) {
    if (_revealed) return;
    final elapsed = _stopwatch.elapsedMilliseconds;
    final limit = _timeLimit.inMilliseconds;
    final correct = choice != null && choice == _q.answer;
    setState(() {
      _selected = choice;
      _revealed = true;
      if (correct) {
        _correct++;
        _streak++;
        final bonus = (_maxBonus * (1 - elapsed / limit)).round().clamp(0, _maxBonus);
        final multiplier = _combo ? min(_streak, 5) : 1;
        _score += (_basePoints + bonus) * multiplier;
        HapticFeedback.lightImpact();
      } else {
        _streak = 0;
        HapticFeedback.heavyImpact();
      }
      if (_bot && _botRandom.nextDouble() < 0.62) {
        _botScore += _basePoints + _botRandom.nextInt(_maxBonus + 1);
      }
    });
    final lost = !correct && _suddenDeath;
    _next = Timer(Duration(milliseconds: _forfeit != null && !correct ? 2600 : 1400), () {
      if (!mounted) return;
      if (lost || _index + 1 >= _questions.length) {
        _finish();
      } else {
        setState(() {
          _index++;
          _selected = null;
          _revealed = false;
          _hidden = {};
        });
        _stopwatch
          ..reset()
          ..start();
      }
    });
  }

  void _useFifty() {
    final wrong = [for (var i = 0; i < _q.options.length; i++) if (i != _q.answer) i]..shuffle(_botRandom);
    setState(() {
      _fiftyUsed = true;
      _hidden = wrong.take(max(0, _q.options.length - 2)).toSet();
    });
  }

  void _useSkip() {
    setState(() => _skipUsed = true);
    _next?.cancel();
    if (_index + 1 >= _questions.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
      _hidden = {};
    });
    _stopwatch
      ..reset()
      ..start();
  }

  void _finish() {
    final total = _questions.length;
    final won = _bot ? _score > _botScore : _correct >= (total * 0.7).ceil();
    run.onFinish(GameOutcome(
      score: _score,
      rating: GameOutcome.ratingOf(_correct / total),
      won: won,
      summary: '$_correct bonne${_correct > 1 ? 's' : ''} réponse${_correct > 1 ? 's' : ''} sur $total',
      details: [
        if (_bot) 'Toi $_score – $_botScore IA ${won ? '🏆' : '🤖'}',
        'Temps total : ${_clock.elapsed.inSeconds} s',
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return Column(
      children: [
        GameHud(
          score: _score,
          round: _index,
          total: _questions.length,
          extra: _bot ? Text('🤖 $_botScore', style: const TextStyle(fontWeight: FontWeight.w800)) : null,
          timer: CountdownBar(
            key: ValueKey(_index),
            duration: _timeLimit,
            paused: _revealed,
            onElapsed: () => _answer(null),
          ),
        ),
        Expanded(
          child: EngineBody(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                PromptCard(text: q.question),
                if (_combo && _streak > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(child: Text('🔥 Combo x${min(_streak, 5)}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w900))),
                  ),
                const SizedBox(height: 16),
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnimatedOpacity(
                      opacity: _hidden.contains(i) ? 0.15 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: AnswerButton(
                        leading: 'ABCD'[i],
                        label: q.options[i],
                        onTap: _hidden.contains(i) ? null : () => _answer(i),
                        state: !_revealed
                            ? (_hidden.contains(i) ? AnswerState.disabled : AnswerState.idle)
                            : i == q.answer
                                ? AnswerState.correct
                                : i == _selected
                                    ? AnswerState.wrong
                                    : AnswerState.disabled,
                      ),
                    ),
                  ),
                if (_revealed && _selected != q.answer && _forfeit != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: FeedbackBanner(text: '💃 Raté ! Gage : danse 5 secondes !', positive: false),
                  ),
                if (_jokers && !_revealed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(onPressed: _fiftyUsed ? null : _useFifty, child: const Text('🎯 50/50')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(onPressed: _skipUsed ? null : _useSkip, child: const Text('⏭️ Passer')),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
