import 'package:flutter/material.dart';

/// Design tokens. Dark, high-contrast "arena" palette.
abstract final class AppColors {
  static const background = Color(0xFF0A0A12);
  static const surface = Color(0xFF14141F);
  static const surfaceHigh = Color(0xFF1D1D2C);
  static const border = Color(0xFF2A2A3D);

  static const primary = Color(0xFF7C5CFF);
  static const secondary = Color(0xFF22D3EE);
  static const accent = Color(0xFFFF4D8D);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFEF4444);
  static const gold = Color(0xFFFFC94D);

  static const text = Color(0xFFF4F4F8);
  static const textMuted = Color(0xFF9A9AB0);
  static const textFaint = Color(0xFF66667A);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFFB45CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const liveGradient = LinearGradient(
    colors: [Color(0xFFFF4D8D), Color(0xFFFF7A45)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Stable accent per category / player, derived from a seed.
  static const palette = [
    Color(0xFF7C5CFF),
    Color(0xFF22D3EE),
    Color(0xFFFF4D8D),
    Color(0xFF22C55E),
    Color(0xFFFBBF24),
    Color(0xFFFF7A45),
    Color(0xFF60A5FA),
    Color(0xFFE879F9),
  ];

  static Color forSeed(Object seed) => palette[seed.hashCode.abs() % palette.length];

  static Color rarity(String rarity) => switch (rarity.toUpperCase()) {
        'LEGENDARY' => gold,
        'EPIC' => const Color(0xFFB45CFF),
        'RARE' => secondary,
        _ => textMuted,
      };
}
