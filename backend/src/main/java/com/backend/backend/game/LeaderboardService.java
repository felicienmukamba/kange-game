package com.backend.backend.game;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/** Global ranking by total XP, backed by the users table. */
@Service
@RequiredArgsConstructor
public class LeaderboardService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<LeaderboardEntry> getTopPlayers(int limit) {
        List<User> users = userRepository.findAllByOrderByXpDescIdAsc(PageRequest.of(0, Math.clamp(limit, 1, 100)));
        List<LeaderboardEntry> entries = new ArrayList<>(users.size());
        for (int i = 0; i < users.size(); i++) {
            entries.add(LeaderboardEntry.of(i + 1, users.get(i)));
        }
        return entries;
    }

    @Transactional(readOnly = true)
    public long getRank(User user) {
        return userRepository.countByXpGreaterThan(user.getXp()) + 1;
    }

    public record LeaderboardEntry(
            long rank, Long userId, String username, String avatar,
            long score, int level, int wins, int gamesPlayed
    ) {
        static LeaderboardEntry of(long rank, User u) {
            return new LeaderboardEntry(rank, u.getId(), u.getUsername(), u.getAvatar(),
                    u.getXp(), u.getLevel(), u.getWins(), u.getGamesPlayed());
        }
    }
}
