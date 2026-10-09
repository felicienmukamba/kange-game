import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Risk / reward games, played with points (never real coins). Variants:
/// * default — push your luck: draw cards to grow the pot, a 💣 wipes it; bank any time (5 rounds),
/// * `chest` — pick one of three chests per round; one is trapped and halves your points,
/// * `business` — buy and sell a product over 10 days of a volatile market.
class RiskEngine extends StatelessWidget {
  const RiskEngine({super.key, required this.run});

  final GameRun run;

  @override
  Widget build(BuildContext context) => switch (run.game.cfgStr('variant')) {
        'chest' => _ChestGame(run: run),
        'business' => _BusinessGame(run: run),
        _ => _PushYourLuck(run: run),
      };
}

class _PushYourLuck extends StatefulWidget {
  const _PushYourLuck({required this.run});

  final GameRun run;

  @override
  State<_PushYourLuck> createState() => _PushYourLuckState();
}

class _PushYourLuckState extends State<_PushYourLuck> {
  static const _rounds = 5;

  late final _rnd = widget.run.random();
  int _round = 0;
  int _pot = 0;
  int _bank = 0;
  int _draws = 0;
  final List<String> _cards = [];
  String? _message;

  /// Bomb chance grows with each draw in the round.
  double get _risk => min(0.6, 0.1 + _draws * 0.08);

  void _draw() {
    final bomb = _rnd.nextDouble() < _risk;
    HapticFeedback.mediumImpact();
    setState(() {
      _draws++;
      if (bomb) {
        _cards.add('💣');
        _message = '💥 Boum ! Pot perdu ($_pot)';
        _pot = 0;
        _next();
      } else {
        final value = 5 + _rnd.nextInt(16);
        _pot += value;
        _cards.add('+$value');
        _message = null;
      }
    });
  }

  void _bankIt() {
    setState(() {
      _bank += _pot;
      _message = '🏦 $_pot sécurisés';
      _pot = 0;
      _next();
    });
  }

  void _next() {
    _round++;
    _draws = 0;
    if (_round >= _rounds) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        widget.run.onFinish(GameOutcome(
          score: _bank,
          rating: GameOutcome.ratingOf(_bank / 220),
          won: _bank >= 150,
          summary: '$_bank points sécurisés',
        ));
      });
    } else {
      Future<void>.delayed(const Duration(milliseconds: 700), () => mounted ? setState(_cards.clear) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _round >= _rounds;
    return Column(
      children: [
        GameHud(score: _bank, round: _round.clamp(0, _rounds - 1), total: _rounds),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text('Pot : $_pot', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                Text('Risque de 💣 : ${(_risk * 100).round()} %', style: TextStyle(color: Color.lerp(AppColors.success, AppColors.danger, _risk / 0.6))),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final c in _cards)
                      Container(
                        width: 58,
                        height: 78,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c == '💣' ? AppColors.danger : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(c, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
                const Spacer(),
                SizedBox(height: 28, child: _message == null ? null : Text(_message!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: done ? null : _draw, child: const Text('🃏 Continuer'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton(onPressed: done || _pot == 0 ? null : _bankIt, child: const Text('🏦 Quitter'))),
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

class _ChestGame extends StatefulWidget {
  const _ChestGame({required this.run});

  final GameRun run;

  @override
  State<_ChestGame> createState() => _ChestGameState();
}

class _ChestGameState extends State<_ChestGame> {
  static const _rounds = 6;

  late final _rnd = widget.run.random();
  int _round = 0;
  int _points = 50;
  int? _opened;
  late List<int> _contents = _deal();

  /// Two prizes and one trap (-1).
  List<int> _deal() {
    final c = [10 + _rnd.nextInt(41), 10 + _rnd.nextInt(41), -1];
    _rnd.shuffle(c);
    return c;
  }

  void _open(int i) {
    if (_opened != null) return;
    final v = _contents[i];
    HapticFeedback.mediumImpact();
    setState(() {
      _opened = i;
      _points = v < 0 ? _points ~/ 2 : _points + v;
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        widget.run.onFinish(GameOutcome(
          score: _points,
          rating: GameOutcome.ratingOf(_points / 250),
          won: _points >= 180,
          summary: '$_points points après $_rounds coffres',
        ));
        return;
      }
      setState(() {
        _round++;
        _opened = null;
        _contents = _deal();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _points, round: _round, total: _rounds),
        const Spacer(),
        const Text('Un des coffres est piégé 💀', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => _open(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 96,
                    height: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _opened == null
                          ? AppColors.surfaceHigh
                          : (_contents[i] < 0 ? AppColors.danger : AppColors.success).withValues(alpha: _opened == i ? 0.6 : 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _opened == null ? '🧰' : (_contents[i] < 0 ? '💀' : '+${_contents[i]}'),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _BusinessGame extends StatefulWidget {
  const _BusinessGame({required this.run});

  final GameRun run;

  @override
  State<_BusinessGame> createState() => _BusinessGameState();
}

class _BusinessGameState extends State<_BusinessGame> {
  static const _days = 10;
  static const _events = [
    ('📰 Un influenceur adore le produit !', 1.35),
    ('🌧️ Saison des pluies, moins de clients', 0.8),
    ('🚚 Rupture chez le concurrent', 1.25),
    ('📉 Nouveau concurrent en ville', 0.75),
    ('🎉 Jour de fête au quartier', 1.2),
    ('😐 Journée calme', 1.0),
    ('⚡ Coupure de courant', 0.85),
  ];

  late final _rnd = widget.run.random();
  int _day = 0;
  double _cash = 1000;
  int _stock = 0;
  double _price = 100;
  String _news = '🏪 Ton commerce ouvre ! Achète bas, vends haut.';

  double get _worth => _cash + _stock * _price;

  void _trade(int qty) {
    setState(() {
      if (qty > 0) {
        final max = (_cash / _price).floor();
        final n = qty > max ? max : qty;
        _stock += n;
        _cash -= n * _price;
      } else {
        final n = -qty > _stock ? _stock : -qty;
        _stock -= n;
        _cash += n * _price;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _nextDay() {
    final (text, factor) = _events[_rnd.nextInt(_events.length)];
    final noise = 0.9 + _rnd.nextDouble() * 0.2;
    setState(() {
      _day++;
      _price = (_price * factor * noise).clamp(20, 400);
      _news = 'Jour ${_day + 1} — $text';
    });
    if (_day >= _days) {
      final worth = _worth.round();
      widget.run.onFinish(GameOutcome(
        score: worth,
        rating: GameOutcome.ratingOf((worth - 800) / 1200),
        won: worth > 1000,
        summary: 'Valeur finale : $worth 💰 (départ 1000)',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _worth.round(), round: _day.clamp(0, _days - 1), total: _days),
        Expanded(
          child: EngineBody(
            child: ListView(
              children: [
                PromptCard(text: _news, fontSize: 17),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(label: 'Prix', value: '${_price.round()} 💰'),
                    _Stat(label: 'Stock', value: '$_stock 📦'),
                    _Stat(label: 'Caisse', value: '${_cash.round()} 💵'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => _trade(1), child: const Text('Acheter 1'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => _trade(5), child: const Text('Acheter 5'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => _trade(-1), child: const Text('Vendre 1'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => _trade(-1000), child: const Text('Tout vendre'))),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _day >= _days ? null : _nextDay, child: const Text('☀️ Jour suivant')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}
