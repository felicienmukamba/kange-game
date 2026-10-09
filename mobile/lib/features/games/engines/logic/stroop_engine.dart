import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_bar.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// Stroop test: a colour word printed in another ink. Pick the INK colour.
/// Variant `chaos`: the rule randomly switches between "ink" and "word".
class StroopEngine extends StatefulWidget {
  const StroopEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<StroopEngine> createState() => _StroopEngineState();
}

class _StroopEngineState extends State<StroopEngine> {
  static const _names = ['ROUGE', 'VERT', 'BLEU', 'JAUNE'];
  static const _colors = [AppColors.danger, AppColors.success, Color(0xFF3B82F6), AppColors.warning];

  late final _rnd = widget.run.random();
  late final bool _chaos = widget.run.game.cfgStr('variant') == 'chaos' || widget.run.game.cfgBool('hardcore');
  late final Duration _limit = widget.run.timeLimit(45);
  int _word = 0;
  int _ink = 1;
  bool _askInk = true;
  int _score = 0;
  int _right = 0;
  int _wrong = 0;
  int? _flash;
  bool _done = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _next() {
    _word = _rnd.nextInt(4);
    do {
      _ink = _rnd.nextInt(4);
    } while (_ink == _word && _rnd.nextInt(4) != 0); // mostly incongruent
    _askInk = !_chaos || _rnd.nextInt(3) != 0;
  }

  void _answer(int i) {
    if (_done) return;
    final ok = i == (_askInk ? _ink : _word);
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      if (ok) {
        _right++;
        _score += 10;
      } else {
        _wrong++;
        _score = (_score - 5).clamp(0, 1 << 30);
      }
      _flash = ok ? 1 : 0;
      _next();
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 200), () => mounted ? setState(() => _flash = null) : null);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    final total = _right + _wrong;
    widget.run.onFinish(GameOutcome(
      score: _score,
      rating: GameOutcome.ratingOf((_right / 35) * (total == 0 ? 0 : _right / total)),
      won: _right >= 25,
      summary: '$_right bonnes réponses, $_wrong erreurs',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameHud(score: _score, timer: CountdownBar(duration: _limit, onElapsed: _finish)),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_askInk ? AppColors.primary : AppColors.accent).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _askInk ? '🎨 Quelle est la COULEUR du texte ?' : '📖 Quel MOT est écrit ?',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: _flash == null ? AppColors.surface : (_flash == 1 ? AppColors.success : AppColors.danger).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(_names[_word], style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: _colors[_ink])),
                  ),
                ),
                const Spacer(),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < 4; i++)
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.surfaceHigh, foregroundColor: AppColors.text),
                        onPressed: () => _answer(i),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 16, height: 16, decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(_names[i], style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
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
