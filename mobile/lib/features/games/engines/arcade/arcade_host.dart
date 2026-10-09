import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../engine/game_run.dart';
import '../common/engine_widgets.dart';

/// A real-time game simulated in [tick] and drawn in [paint].
///
/// The host repaints only the canvas (via [CustomPaint.painter]'s `repaint`)
/// on every frame; no widget is rebuilt during play.
abstract class ArcadeGame extends GameLoop {
  Size size = Size.zero;
  int score = 0;
  bool over = false;

  /// Optional time limit in seconds (shown as a bar); `null` = until game over.
  double? get timeLimit => null;
  double elapsed = 0;

  String get title;
  String get help;

  /// Called once the canvas size is known (and on resize).
  void layout(Size newSize) => size = newSize;

  void onTapDown(Offset position) {}

  void onTapUp() {}

  void onDrag(Offset delta, Offset position) {}

  void onKey(LogicalKeyboardKey key) {}

  void paint(Canvas canvas, Size size);

  GameOutcome outcome();

  @override
  void tick(double dt) {
    if (over) return;
    elapsed += dt;
    final limit = timeLimit;
    if (limit != null && elapsed >= limit) {
      over = true;
      return;
    }
    update(dt);
  }

  /// Advance the simulation; set [over] to end the game.
  void update(double dt);
}

/// Runs an [ArcadeGame]: countdown, input, HUD, end detection.
class ArcadeHost extends StatefulWidget {
  const ArcadeHost({super.key, required this.run, required this.create, this.background = AppColors.surface});

  final GameRun run;
  final ArcadeGame Function() create;
  final Color background;

  @override
  State<ArcadeHost> createState() => _ArcadeHostState();
}

class _ArcadeHostState extends State<ArcadeHost> with SingleTickerProviderStateMixin {
  late final ArcadeGame _game = widget.create()..attach(this);
  final _focus = FocusNode();
  bool _ready = false;
  bool _reported = false;
  int _shownScore = 0;

  @override
  void initState() {
    super.initState();
    _game.addListener(_onFrame);
  }

  void _onFrame() {
    if (_game.over && !_reported) {
      _reported = true;
      _game.stop();
      HapticFeedback.heavyImpact();
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.run.onFinish(_game.outcome());
      });
    }
    // Only rebuild the HUD when the visible score changes.
    if (_game.score != _shownScore && mounted) setState(() => _shownScore = _game.score);
  }

  @override
  void dispose() {
    _game.removeListener(_onFrame);
    _game.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return ReadyCountdown(
        title: _game.title,
        subtitle: _game.help,
        onDone: () {
          setState(() => _ready = true);
          _game.start();
          _focus.requestFocus();
        },
      );
    }
    final limit = _game.timeLimit;
    return Column(
      children: [
        GameHud(
          score: _shownScore,
          timer: limit == null
              ? null
              : ListenableBuilder(
                  listenable: _game,
                  builder: (context, _) => ProgressBarTimer(fraction: 1 - _game.elapsed / limit),
                ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: KeyboardListener(
              focusNode: _focus,
              autofocus: true,
              onKeyEvent: (e) {
                if (e is KeyDownEvent) _game.onKey(e.logicalKey);
              },
              child: LayoutBuilder(
                builder: (context, box) {
                  if (_game.size != box.biggest) _game.layout(box.biggest);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _game.onTapDown(d.localPosition),
                    onTapUp: (_) => _game.onTapUp(),
                    onPanUpdate: (d) => _game.onDrag(d.delta, d.localPosition),
                    onPanEnd: (_) => _game.onTapUp(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: box.biggest,
                          painter: _ArcadePainter(_game, widget.background),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcadePainter extends CustomPainter {
  _ArcadePainter(this.game, this.background) : super(repaint: game);

  final ArcadeGame game;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    game.paint(canvas, size);
    if (game.over) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.45));
      final tp = TextPainter(
        text: const TextSpan(text: 'TERMINÉ', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, size.center(Offset.zero) - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_ArcadePainter old) => false;
}

/// Caches laid-out emoji glyphs; drawing text every frame is the main arcade cost.
class EmojiSprites {
  final Map<String, TextPainter> _cache = {};

  void draw(Canvas canvas, String emoji, Offset center, double size) {
    final key = '$emoji@${size.round()}';
    final tp = _cache.putIfAbsent(
      key,
      () => TextPainter(text: TextSpan(text: emoji, style: TextStyle(fontSize: size)), textDirection: TextDirection.ltr)..layout(),
    );
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void dispose() {
    for (final tp in _cache.values) {
      tp.dispose();
    }
    _cache.clear();
  }
}
