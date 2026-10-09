import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A depleting time bar driven by its own [AnimationController], so a running
/// timer repaints only this bar — never the screen around it.
///
/// Restart it by changing [key] or [duration]/[remaining].
class CountdownBar extends StatefulWidget {
  const CountdownBar({super.key, required this.duration, this.remaining, this.onElapsed, this.height = 8, this.paused = false});

  final Duration duration;

  /// Time left when the bar appears (defaults to the full [duration]).
  final Duration? remaining;
  final VoidCallback? onElapsed;
  final double height;
  final bool paused;

  @override
  State<CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<CountdownBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) widget.onElapsed?.call();
    });
    _start();
  }

  @override
  void didUpdateWidget(CountdownBar old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration || old.remaining != widget.remaining) _start();
    if (old.paused != widget.paused) {
      widget.paused ? _controller.stop() : _resume();
    }
  }

  void _start() {
    final total = widget.duration.inMilliseconds;
    if (total <= 0) return;
    final left = (widget.remaining ?? widget.duration).inMilliseconds.clamp(0, total);
    _controller
      ..duration = widget.duration
      ..value = left / total;
    if (!widget.paused) _resume();
  }

  void _resume() {
    if (_controller.value > 0) _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = _controller.value;
          final color = v > 0.5 ? AppColors.success : (v > 0.2 ? AppColors.warning : AppColors.danger);
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.height),
            child: LinearProgressIndicator(
              value: v,
              minHeight: widget.height,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          );
        },
      ),
    );
  }
}
