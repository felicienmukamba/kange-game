package com.backend.backend.reward;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RewardService {

    private final UserRepository userRepository;

    @Transactional
    public void grantReward(String username, long xpAmount, long coinsAmount) {
        userRepository.findByUsername(username).ifPresent(user -> {
            user.setXp(user.getXp() + xpAmount);
            user.setCoins(user.getCoins() + coinsAmount);
            
            // Level up logic
            if (user.getXp() >= user.getLevel() * 1000) {
                user.setLevel(user.getLevel() + 1);
            }
            
            userRepository.save(user);
        });
    }
}
