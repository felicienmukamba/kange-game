package com.backend.backend.reward;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RewardService {

    /** XP needed per level; level N is reached at (N - 1) * XP_PER_LEVEL total XP. */
    public static final long XP_PER_LEVEL = 1000;
    private static final long XP_PER_POINT = 10;
    private static final long COINS_PER_POINT = 1;
    private static final long WIN_BONUS_COINS = 50;

    private final UserRepository userRepository;

    @Transactional
    public void grantReward(String username, long xpAmount, long coinsAmount) {
        userRepository.findByUsername(username).ifPresent(user -> {
            applyReward(user, xpAmount, coinsAmount);
            userRepository.save(user);
        });
    }

    @Transactional
    public void grantGameReward(String username, int score, boolean won) {
        userRepository.findByUsername(username).ifPresent(user -> {
            long coins = score * COINS_PER_POINT + (won ? WIN_BONUS_COINS : 0);
            applyReward(user, score * XP_PER_POINT, coins);
            user.setGamesPlayed(user.getGamesPlayed() + 1);
            if (won) user.setWins(user.getWins() + 1);
            userRepository.save(user);
        });
    }

    public record Reward(long xp, long coins) {}

    /** Solo runs pay on a 0-100 performance rating: up to 200 XP and 10 coins. */
    @Transactional
    public Reward grantSoloReward(String username, int rating, boolean rewarded) {
        int r = Math.clamp(rating, 0, 100);
        Reward reward = rewarded ? new Reward(r * 2L, r / 10) : new Reward(0, 0);
        userRepository.findByUsername(username).ifPresent(user -> {
            applyReward(user, reward.xp(), reward.coins());
            user.setGamesPlayed(user.getGamesPlayed() + 1);
            userRepository.save(user);
        });
        return reward;
    }

    private void applyReward(User user, long xpAmount, long coinsAmount) {
        user.setXp(user.getXp() + xpAmount);
        user.setCoins(user.getCoins() + coinsAmount);
        user.setLevel(levelForXp(user.getXp()));
    }

    public static int levelForXp(long xp) {
        return (int) (xp / XP_PER_LEVEL) + 1;
    }
}
