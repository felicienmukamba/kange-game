import 'package:equatable/equatable.dart';

import '../../../core/utils/json.dart';

enum UserRole {
  player('Joueur', '🎮'),
  streamer('Streamer', '📺'),
  creator('Créateur', '🛠️'),
  moderator('Modérateur', '🛡️'),
  admin('Admin', '👑');

  const UserRole(this.label, this.emoji);

  final String label;
  final String emoji;

  static UserRole parse(String value) =>
      UserRole.values.firstWhere((r) => r.name.toUpperCase() == value.toUpperCase(), orElse: () => UserRole.player);

  String get apiName => name.toUpperCase();

  bool get canBroadcast => this == streamer || this == creator || this == admin;

  bool get canModerate => this == moderator || this == admin;
}

/// The signed-in player's own profile.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatar,
    this.bio,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.reputation = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.dailyStreak = 0,
  });

  factory UserProfile.fromJson(Json j) => UserProfile(
        id: j.integer('id'),
        username: j.str('username'),
        email: j.str('email'),
        role: UserRole.parse(j.str('role', 'PLAYER')),
        avatar: j.strOrNull('avatar'),
        bio: j.strOrNull('bio'),
        level: j.integer('level', 1),
        xp: j.integer('xp'),
        coins: j.integer('coins'),
        reputation: j.integer('reputation'),
        gamesPlayed: j.integer('gamesPlayed'),
        wins: j.integer('wins'),
        dailyStreak: j.integer('dailyStreak'),
      );

  static const xpPerLevel = 1000;

  final int id;
  final String username;
  final String email;
  final UserRole role;
  final String? avatar;
  final String? bio;
  final int level;
  final int xp;
  final int coins;
  final int reputation;
  final int gamesPlayed;
  final int wins;
  final int dailyStreak;

  /// Progress through the current level, 0..1.
  double get levelProgress => (xp % xpPerLevel) / xpPerLevel;

  int get xpToNextLevel => xpPerLevel - xp % xpPerLevel;

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  UserProfile copyWith({String? avatar, String? bio, int? coins, int? xp, int? level}) => UserProfile(
        id: id,
        username: username,
        email: email,
        role: role,
        avatar: avatar ?? this.avatar,
        bio: bio ?? this.bio,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        coins: coins ?? this.coins,
        reputation: reputation,
        gamesPlayed: gamesPlayed,
        wins: wins,
        dailyStreak: dailyStreak,
      );

  @override
  List<Object?> get props =>
      [id, username, email, role, avatar, bio, level, xp, coins, reputation, gamesPlayed, wins, dailyStreak];
}
