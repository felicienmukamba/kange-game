import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/content.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// "Devine avant la révélation": an emoji starts as a few huge pixels and sharpens
/// over [_revealTime]. The earlier you answer, the more points.
/// Variant `shadow` shows a black silhouette instead.
class PixelRevealEngine extends StatefulWidget {
  const PixelRevealEngine({super.key, required this.run});

  final GameRun run;

  @override
  State<PixelRevealEngine> createState() => _PixelRevealEngineState();
}

class _PixelRevealEngineState extends State<PixelRevealEngine> with SingleTickerProviderStateMixin {
  static const _revealTime = Duration(seconds: 10);
  static const _rounds = 8;

  late final List<PixelItem> _items;
  late final List<List<String>> _options;
  late final AnimationController _reveal = AnimationController(vsync: this, duration: _revealTime);
  late final bool _shadow = widget.run.game.cfgStr('variant') == 'shadow';
  int _index = 0;
  int _score = 0;
  int _found = 0;
  String? _picked;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    final rnd = widget.run.random();
    final pool = List.of(widget.run.content.pixel);
    rnd.shuffle(pool);
    _items = pool.take(_rounds).toList();
    _options = [
      for (final item in _items) [item.answer, ...item.decoys.take(3)],
    ];
    for (final o in _options) {
      rnd.shuffle(o);
    }
    _reveal.addStatusListener((s) {
      if (s == AnimationStatus.completed) _pick(null);
    });
    _reveal.forward();
  }

  @override
  void dispose() {
    _next?.cancel();
    _reveal.dispose();
    super.dispose();
  }

  void _pick(String? option) {
    if (_picked != null) return;
    _reveal.stop();
    final right = option == _items[_index].answer;
    setState(() {
      _picked = option ?? '';
      if (right) {
        _found++;
        _score += 10 + (20 * (1 - _reveal.value)).round();
      }
    });
    right ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    _next = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (_index + 1 >= _items.length) {
        widget.run.onFinish(GameOutcome(
          score: _score,
          rating: GameOutcome.ratingOf(_score / (_items.length * 30)),
          won: _found >= 6,
          summary: '$_found / ${_items.length} trouvés',
        ));
        return;
      }
      setState(() {
        _index++;
        _picked = null;
      });
      _reveal.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return Column(
      children: [
        GameHud(score: _score, round: _index, total: _items.length),
        Expanded(
          child: EngineBody(
            child: Column(
              children: [
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 1.4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _reveal,
                        builder: (context, _) => _PixelatedEmoji(
                          emoji: item.emoji,
                          // 4 → 64 px resolution as time passes; fully sharp once answered.
                          resolution: _picked != null ? 0 : (4 + 60 * Curves.easeIn.transform(_reveal.value)).round(),
                          silhouette: _shadow && _picked == null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final o in _options[_index])
                        AnswerButton(
                          label: o,
                          onTap: () => _pick(o),
                          state: _picked == null
                              ? AnswerState.idle
                              : o == item.answer
                                  ? AnswerState.correct
                                  : o == _picked
                                      ? AnswerState.wrong
                                      : AnswerState.disabled,
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

/// Renders an emoji into a tiny offscreen picture and scales it up without
/// smoothing, giving a true pixel-art blur that costs one raster per frame.
class _PixelatedEmoji extends StatelessWidget {
  const _PixelatedEmoji({required this.emoji, required this.resolution, required this.silhouette});

  final String emoji;

  /// Pixels across; 0 means full quality.
  final int resolution;
  final bool silhouette;

  @override
  Widget build(BuildContext context) {
    final text = Text(emoji, style: const TextStyle(fontSize: 120));
    if (resolution == 0) return Center(child: text);
    return CustomPaint(painter: _PixelPainter(emoji, resolution, silhouette), child: const SizedBox.expand());
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter(this.emoji, this.resolution, this.silhouette);

  final String emoji;
  final int resolution;
  final bool silhouette;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.8;
    final small = resolution.toDouble();
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: small * 0.85)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((small - tp.width) / 2, (small - tp.height) / 2));
    tp.dispose();
    final image = recorder.endRecording().toImageSync(resolution, resolution);

    final dst = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final paint = Paint()..filterQuality = FilterQuality.none;
    if (silhouette) paint.colorFilter = const ColorFilter.mode(Colors.black, BlendMode.srcIn);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, small, small), dst, paint);
    image.dispose();
  }

  @override
  bool shouldRepaint(_PixelPainter old) => old.resolution != resolution || old.emoji != emoji || old.silhouette != silhouette;
}
