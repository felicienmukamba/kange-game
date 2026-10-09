import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Top bar shown by most engines: progress, score and an optional timer.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.score, this.round, this.total, this.timer, this.extra});

  final int score;
  final int? round;
  final int? total;
  final Widget? timer;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              if (round != null && total != null)
                Text('${round! + 1} / $total', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMuted)),
              const Spacer(),
              ?extra,
              const SizedBox(width: 8),
              _ScoreChip(score: score),
            ],
          ),
          if (timer != null) ...[const SizedBox(height: 10), timer!],
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(score),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
        child: Text('$score pts', style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

enum AnswerState { idle, selected, correct, wrong, disabled }

/// A big tappable answer (quiz options, true/false, polls…).
class AnswerButton extends StatelessWidget {
  const AnswerButton({super.key, required this.label, required this.onTap, this.state = AnswerState.idle, this.leading, this.color});

  final String label;
  final VoidCallback? onTap;
  final AnswerState state;
  final String? leading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (state) {
      AnswerState.correct => (AppColors.success.withValues(alpha: 0.25), AppColors.success),
      AnswerState.wrong => (AppColors.danger.withValues(alpha: 0.25), AppColors.danger),
      AnswerState.selected => (AppColors.primary.withValues(alpha: 0.25), AppColors.primary),
      AnswerState.disabled => (AppColors.surface, AppColors.border),
      AnswerState.idle => (AppColors.surfaceHigh, color ?? AppColors.border),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: state == AnswerState.idle ? 1 : 2),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: state == AnswerState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                if (leading != null) ...[
                  Text(leading!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: state == AnswerState.disabled ? AppColors.textFaint : AppColors.text,
                    ),
                  ),
                ),
                if (state == AnswerState.correct) const Icon(Icons.check_circle, color: AppColors.success),
                if (state == AnswerState.wrong) const Icon(Icons.cancel, color: AppColors.danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The question / prompt card at the top of knowledge games.
class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.text, this.emoji, this.fontSize = 20});

  final String text;
  final String? emoji;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 44)), const SizedBox(height: 10)],
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.3)),
        ],
      ),
    );
  }
}

/// "3, 2, 1, GO" before action games so the player is ready.
class ReadyCountdown extends StatefulWidget {
  const ReadyCountdown({super.key, required this.onDone, this.title, this.subtitle});

  final VoidCallback onDone;
  final String? title;
  final String? subtitle;

  @override
  State<ReadyCountdown> createState() => _ReadyCountdownState();
}

class _ReadyCountdownState extends State<ReadyCountdown> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (_count <= 1) {
        t.cancel();
        widget.onDone();
      } else {
        setState(() => _count--);
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(widget.title!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            ),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(widget.subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$_count', key: ValueKey(_count), style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

/// Drives a real-time game at the display refresh rate without rebuilding widgets:
/// subclasses update their model in [tick] and a [CustomPainter] listening to this
/// notifier repaints. Pauses automatically with the ticker (app in background).
abstract class GameLoop extends ChangeNotifier {
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _running = false;

  bool get running => _running;

  void attach(TickerProvider vsync) {
    _ticker ??= vsync.createTicker(_onTick);
  }

  void start() {
    if (_running) return;
    _running = true;
    _last = Duration.zero;
    _ticker?.start();
  }

  void stop() {
    _running = false;
    _ticker?.stop();
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Clamp long frames (debugger, background) so physics never explodes.
    tick(dt.clamp(0, 1 / 20).toDouble());
    notifyListeners();
  }

  /// Advance the simulation by [dt] seconds.
  void tick(double dt);

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

/// Feedback flash ("+15", "Raté !") floating over the game.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: (positive ? AppColors.success : AppColors.danger).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }
}

/// Lays out an engine's body with consistent padding and a max width on tablets / desktop.
class EngineBody extends StatelessWidget {
  const EngineBody({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child),
      ),
    );
  }
}

/// Thin progress bar fed by a fraction (for loop-driven games).
class ProgressBarTimer extends StatelessWidget {
  const ProgressBarTimer({super.key, required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: f,
        minHeight: 8,
        backgroundColor: AppColors.surfaceHigh,
        valueColor: AlwaysStoppedAnimation(f > 0.5 ? AppColors.success : (f > 0.2 ? AppColors.warning : AppColors.danger)),
      ),
    );
  }
}
