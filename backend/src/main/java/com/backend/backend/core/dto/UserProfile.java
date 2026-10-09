package com.backend.backend.core.dto;

import com.backend.backend.core.domain.User;

/** The signed-in user's own profile (includes private fields such as email). */
public record UserProfile(
        Long id,
        String username,
        String email,
        String role,
        String avatar,
        String bio,
        int level,
        long xp,
        long coins,
        int reputation,
        int gamesPlayed,
        int wins,
        int dailyStreak
) {
    public static UserProfile of(User u) {
        return new UserProfile(
                u.getId(), u.getUsername(), u.getEmail(), u.getRole().name(), u.getAvatar(), u.getBio(),
                u.getLevel(), u.getXp(), u.getCoins(), u.getReputation(), u.getGamesPlayed(), u.getWins(),
                u.getDailyStreak() == null ? 0 : u.getDailyStreak()
        );
    }
}
