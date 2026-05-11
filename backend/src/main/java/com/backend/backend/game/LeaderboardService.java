package com.backend.backend.game;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LeaderboardService {

    private final RedisTemplate<String, String> redisTemplate;
    private static final String LEADERBOARD_KEY = "rewify:leaderboard:global";

    public void updateScore(String username, double score) {
        redisTemplate.opsForZSet().incrementScore(LEADERBOARD_KEY, username, score);
    }

    public Set<LeaderboardEntry> getTopPlayers(int limit) {
        Set<ZSetOperations.TypedTuple<String>> topPlayers = redisTemplate.opsForZSet()
                .reverseRangeWithScores(LEADERBOARD_KEY, 0, limit - 1);

        if (topPlayers == null) return Set.of();

        return topPlayers.stream()
                .map(tuple -> new LeaderboardEntry(tuple.getValue(), tuple.getScore().intValue()))
                .collect(Collectors.toSet());
    }

    public record LeaderboardEntry(String username, int score) {}
}
