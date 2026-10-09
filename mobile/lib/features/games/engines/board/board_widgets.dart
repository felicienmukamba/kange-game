import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shows whose turn it is (or the result) above a board.
class TurnBanner extends StatelessWidget {
  const TurnBanner({
    super.key,
    required this.players,
    required this.current,
    required this.me,
    this.winner,
    this.draw = false,
    this.symbols = const [],
    this.passAndPlay = false,
  });

  final List<String> players;
  final String? current;
  final String me;
  final String? winner;
  final bool draw;
  final List<String> symbols;
  final bool passAndPlay;

  String _symbol(String p) {
    final i = players.indexOf(p);
    return i >= 0 && i < symbols.length ? '${symbols[i]} ' : '';
  }

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch ((winner, draw)) {
      (final String w, _) => (w == me && !passAndPlay ? '🏆 Victoire !' : '🏆 ${_symbol(w)}$w gagne', AppColors.gold),
      (_, true) => ('🤝 Match nul', AppColors.secondary),
      _ => current == me && !passAndPlay
          ? ('👉 À toi de jouer ${_symbol(me)}', AppColors.success)
          : ('⏳ Tour de ${_symbol(current ?? '')}${current ?? '…'}', AppColors.textMuted),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color == AppColors.textMuted ? AppColors.text : color))),
        ],
      ),
    );
  }
}

/// Player chips with scores.
class ScoreStrip extends StatelessWidget {
  const ScoreStrip({super.key, required this.players, required this.scores, this.highlight});

  final List<String> players;
  final Map<String, int> scores;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final p in players)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p == highlight ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: p == highlight ? AppColors.primary : AppColors.border),
              ),
              child: Text('$p · ${scores[p] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
