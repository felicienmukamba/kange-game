import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Luck games, all built on a spinning wheel. Variants:
/// * default — 5 spins, sum the points (💀 halves the total),
/// * `loot` — open 5 boxes for cosmetic badges of growing rarity,
/// * `dice` — "Pig": roll to accumulate, a 1 loses the turn's pot, bank before it happens,
/// * `card` — higher or lower: guess if the next card beats this one,
/// * `chaos` — each spin rolls a random rule for a bonus round,
/// * `games` / `mission` / `quiz` — the wheel picks a challenge or a secret mission.
class SpinWheelEngine extends StatelessWidget {
  const SpinWheelEngine({super.key, required this.run});

  final GameRun run;

  @override
  Widget build(BuildContext context) {
    return switch (run.game.cfgStr('variant')) {
      'dice' => _DiceGame(run: run),
      'card' => _HighLowGame(run: run),
      'games' || 'mission' || 'quiz' => _PickerWheel(run: run),
      final v => _PointsWheel(run: run, loot: v == 'loot', chaos: v == 'chaos'),
    };
  }
}

class _Segment {
  const _Segment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

/// Shared wheel widget: spins to [target] index with an ease-out.
class _Wheel extends StatefulWidget {
  const _Wheel({required this.segments, required this.target, required this.spinId, required this.onStopped});

  final List<String> segments;
  final int target;

  /// Increment to trigger a new spin.
  final int spinId;
  final VoidCallback onStopped;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  double _from = 0, _to = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onStopped();
    });
  }

  @override
  void didUpdateWidget(_Wheel old) {
    super.didUpdateWidget(old);
    if (old.spinId != widget.spinId && widget.spinId > 0) {
      final n = widget.segments.length;
      final seg = 2 * pi / n;
      // Pointer is at the top; segment i is centred at angle i*seg.
      final targetAngle = -widget.target * seg;
      _from = _to % (2 * pi);
      _to = targetAngle - 2 * pi * 5;
      while (_to > _from - 2 * pi * 4) {
        _to -= 2 * pi;
      }
      _c.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_c.value);
                return Transform.rotate(
                  angle: _from + (_to - _from) * t,
                  child: CustomPaint(painter: _WheelPainter(widget.segments), size: Size.infinite),
                );
              },
            ),
          ),
          const Text('🔻', style: TextStyle(fontSize: 34)),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.labels);

  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 8;
    final n = labels.length;
    final seg = 2 * pi / n;
    for (var i = 0; i < n; i++) {
      final start = -pi / 2 + i * seg - seg / 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, seg, true,
          Paint()..color = AppColors.palette[i % AppColors.palette.length].withValues(alpha: 0.85));
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * seg);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(fontSize: n > 8 ? 13 : 16, fontWeight: FontWeight.w900, color: Colors.white)),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      )..layout(maxWidth: r * 0.55);
      tp.paint(canvas, Offset(-tp.width / 2, -r * 0.78));
      tp.dispose();
      canvas.restore();
    }
    canvas.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white);
    canvas.drawCircle(center, 22, Paint()..color = AppColors.background);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.labels != labels;
}

class _PointsWheel extends StatefulWidget {
  const _PointsWheel({required this.run, required this.loot, required this.chaos});

  final GameRun run;
  final bool loot;
  final bool chaos;

  @override
  State<_PointsWheel> createState() => _PointsWheelState();
}

class _PointsWheelState extends State<_PointsWheel> {
  static const _spins = 5;
  static const _points = [
    _Segment('10', 10, AppColors.primary),
    _Segment('50', 50, AppColors.secondary),
    _Segment('20', 20, AppColors.accent),
    _Segment('💀', -1, Colors.black),
    _Segment('100', 100, AppColors.gold),
    _Segment('5', 5, AppColors.success),
    _Segment('x2', -2, AppColors.warning),
    _Segment('30', 30, AppColors.primary),
  ];
  static const _loot = [
    _Segment('Commun', 10, AppColors.textMuted),
    _Segment('Rare', 30, AppColors.secondary),
    _Segment('Commun', 10, AppColors.textMuted),
    _Segment('Épique', 60, Color(0xFFB45CFF)),
    _Segment('Commun', 10, AppColors.textMuted),
    _Segment('Rare', 30, AppColors.secondary),
    _Segment('LÉGENDAIRE', 150, AppColors.gold),
    _Segment('Rare', 30, AppColors.secondary),
  ];
  static const _badges = ['🎖️', '🏅', '💎', '🔮', '🪐', '🐉', '👑', '🦄'];
  static const _chaosRules = ['Points x3 ce tour !', 'Tu perds 20 points', 'Rejoue gratuitement', 'Vole 30 points à la banque', 'Rien ne se passe…'];

  late final _rnd = widget.run.random();
  int _spinId = 0;
  int _target = 0;
  int _total = 0;
  bool _spinning = false;
  final List<String> _log = [];

  List<_Segment> get _segments => widget.loot ? _loot : _points;

  void _spin() {
    if (_spinning || _spinId >= _spins) return;
    setState(() {
      _spinning = true;
      _target = _rnd.nextInt(_segments.length);
      _spinId++;
    });
  }

  void _stopped() {
    final s = _segments[_target];
    setState(() {
      _spinning = false;
      if (widget.loot) {
        _total += s.value;
        _log.add('${_badges[_rnd.nextInt(_badges.length)]} Badge ${s.label.toLowerCase()} (+${s.value})');
      } else if (s.value == -1) {
        _total ~/= 2;
        _log.add('💀 Total divisé par 2');
      } else if (s.value == -2) {
        _total *= 2;
        _log.add('✨ Total doublé !');
      } else {
        var gain = s.value;
        if (widget.chaos) {
          final rule = _chaosRules[_rnd.nextInt(_chaosRules.length)];
          gain = switch (rule) {
            'Points x3 ce tour !' => gain * 3,
            'Tu perds 20 points' => gain - 20,
            'Vole 30 points à la banque' => gain + 30,
            _ => gain,
          };
          if (rule == 'Rejoue gratuitement') _spinId--;
          _log.add('🌀 $rule → ${gain >= 0 ? '+' : ''}$gain');
        } else {
          _log.add('+$gain');
        }
        _total = max(0, _total + gain);
      }
    });
    if (_spinId >= _spins) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        widget.run.onFinish(GameOutcome(
          score: _total,
          rating: GameOutcome.ratingOf(_total / (widget.loot ? 250 : 300)),
          won: _total >= (widget.loot ? 150 : 200),
          summary: widget.loot ? 'Valeur du butin : $_total' : 'Total : $_total points',
          details: _log,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _total, round: (_spinId - 1).clamp(0, _spins - 1), total: _spins),
        Expanded(
          child: EngineBody(
            maxWidth: 440,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: _Wheel(
                      segments: [for (final s in _segments) s.label],
                      target: _target,
                      spinId: _spinId,
                      onStopped: _stopped,
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: _log.isEmpty ? null : Text(_log.last, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _spinning || _spinId >= _spins ? null : _spin,
                  child: Text(widget.loot ? '🎁 Ouvrir une box (${_spins - _spinId})' : '🎡 Tourner (${_spins - _spinId})'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Lands on a random challenge category / secret mission / quiz theme.
class _PickerWheel extends StatefulWidget {
  const _PickerWheel({required this.run});

  final GameRun run;

  @override
  State<_PickerWheel> createState() => _PickerWheelState();
}

class _PickerWheelState extends State<_PickerWheel> {
  late final _rnd = widget.run.random();
  late final String _variant = widget.run.game.cfgStr('variant') ?? 'games';
  late final List<String> _labels = switch (_variant) {
    'mission' => const ['🎯', '⚡', '🧠', '🏆', '🔥', '🎲', '💎', '🚀'],
    'quiz' => const ['⚽ Foot', '🍥 Manga', '🌍 Afrique', '🎵 Musique', '🔬 Science', '📜 Histoire', '🎮 Gaming', '🗺️ Géo'],
    _ => const ['🧠 Quiz', '⚡ Réflexes', '🎨 Dessin', '🧩 Puzzle', '😂 Défi fun', '🎲 Hasard', '🕹️ Arcade', '🎤 Talent'],
  };
  int _spinId = 0;
  int _target = 0;
  String? _result;

  static const _quizTopics = ['football', 'manga', 'afrique', 'musique', 'science', 'histoire', 'gaming', 'geo'];

  void _spin() => setState(() {
        _target = _rnd.nextInt(_labels.length);
        _spinId++;
        _result = null;
      });

  void _stopped() {
    final content = widget.run.content;
    setState(() {
      _result = switch (_variant) {
        'mission' => content.missions[_rnd.nextInt(content.missions.length)],
        'quiz' => (() {
            final q = content.quizTopic(_quizTopics[_target]);
            final item = q[_rnd.nextInt(q.length)];
            return '${item.question}\n\n👉 ${item.options[item.answer]}';
          })(),
        _ => 'Ton défi : ${_labels[_target]} ! Lance un jeu de cette famille depuis le catalogue.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: EngineBody(
            maxWidth: 440,
            child: Column(
              children: [
                Expanded(child: Center(child: _Wheel(segments: _labels, target: _target, spinId: _spinId, onStopped: _stopped))),
                if (_result != null) ...[
                  PromptCard(text: _result!, fontSize: 17),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _spin,
                  child: Text(_spinId == 0 ? '🎡 Lancer la roue' : '🔁 Relancer'),
                ),
                const SizedBox(height: 8),
                if (_result != null)
                  OutlinedButton(
                    onPressed: () => widget.run.onFinish(GameOutcome(score: 10 * _spinId, rating: 50, summary: 'Roue lancée $_spinId fois')),
                    child: const Text('Terminer'),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiceGame extends StatefulWidget {
  const _DiceGame({required this.run});

  final GameRun run;

  @override
  State<_DiceGame> createState() => _DiceGameState();
}

class _DiceGameState extends State<_DiceGame> {
  static const _turns = 6;
  static const _faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  late final _rnd = widget.run.random();
  int _turn = 0;
  int _pot = 0;
  int _bank = 0;
  int? _face;
  String? _message;

  void _roll() {
    final v = _rnd.nextInt(6) + 1;
    HapticFeedback.mediumImpact();
    setState(() {
      _face = v;
      if (v == 1) {
        _message = '💥 Un 1 ! Le pot de $_pot est perdu.';
        _pot = 0;
        _endTurn();
      } else {
        _pot += v;
        _message = '+$v';
      }
    });
  }

  void _hold() {
    setState(() {
      _bank += _pot;
      _message = '🏦 $_pot points sécurisés';
      _pot = 0;
      _endTurn();
    });
  }

  void _endTurn() {
    _turn++;
    if (_turn >= _turns) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        widget.run.onFinish(GameOutcome(
          score: _bank,
          rating: GameOutcome.ratingOf(_bank / 90),
          won: _bank >= 60,
          summary: '$_bank points en $_turns tours',
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _turn >= _turns;
    return Column(
      children: [
        GameHud(score: _bank, round: _turn.clamp(0, _turns - 1), total: _turns),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const Spacer(),
                Text(_face == null ? '🎲' : _faces[_face! - 1], style: const TextStyle(fontSize: 120)),
                Text('Pot : $_pot', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                SizedBox(height: 26, child: _message == null ? null : Text(_message!, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))),
                const Spacer(),
                const Text('Lance pour remplir le pot. Un 1 fait tout perdre : encaisse à temps !', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: done ? null : _roll, child: const Text('🎲 Lancer'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton(onPressed: done || _pot == 0 ? null : _hold, child: const Text('🏦 Encaisser'))),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HighLowGame extends StatefulWidget {
  const _HighLowGame({required this.run});

  final GameRun run;

  @override
  State<_HighLowGame> createState() => _HighLowGameState();
}

class _HighLowGameState extends State<_HighLowGame> {
  static const _names = ['', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'V', 'D', 'R'];
  static const _suits = ['♠', '♥', '♦', '♣'];

  late final _rnd = widget.run.random();
  late int _card = 2 + _rnd.nextInt(11);
  late int _suit = _rnd.nextInt(4);
  int _streak = 0;
  bool _lost = false;

  void _guess(bool higher) {
    if (_lost) return;
    var next = 1 + _rnd.nextInt(13);
    while (next == _card) {
      next = 1 + _rnd.nextInt(13);
    }
    final right = higher ? next > _card : next < _card;
    setState(() {
      _card = next;
      _suit = _rnd.nextInt(4);
      if (right) {
        _streak++;
        HapticFeedback.lightImpact();
      } else {
        _lost = true;
        HapticFeedback.heavyImpact();
      }
    });
    if (!right) {
      Future<void>.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        widget.run.onFinish(GameOutcome(
          score: _streak * 10,
          rating: GameOutcome.ratingOf(_streak / 10),
          won: _streak >= 6,
          summary: 'Série de $_streak bonnes prédictions',
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = _suit == 1 || _suit == 2;
    return Column(
      children: [
        GameHud(score: _streak * 10),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => RotationTransition(turns: Tween(begin: 0.5, end: 1.0).animate(a), child: c),
                  child: Container(
                    key: ValueKey('$_card$_suit$_streak'),
                    width: 160,
                    height: 230,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _lost ? AppColors.danger : Colors.white, width: 4),
                    ),
                    child: Text('${_names[_card]}${_suits[_suit]}',
                        style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: red ? AppColors.danger : Colors.black)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Série : $_streak', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                const Text('La prochaine carte sera-t-elle plus haute ou plus basse ?', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: () => _guess(false), child: const Text('⬇️ Plus basse'))),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton(onPressed: () => _guess(true), child: const Text('⬆️ Plus haute'))),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
