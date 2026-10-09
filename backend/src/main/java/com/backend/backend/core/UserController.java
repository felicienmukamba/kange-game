package com.backend.backend.core;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.game.LeaderboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

/** Public profiles: no email, no coin balance. */
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final LeaderboardService leaderboardService;

    public record PublicProfile(Long id, String username, String role, String avatar, String bio, int level,
                                long xp, int gamesPlayed, int wins, long rank, LocalDateTime createdAt) {}

    @GetMapping("/{username}")
    @Transactional(readOnly = true)
    public ResponseEntity<PublicProfile> profile(@PathVariable String username) {
        User u = userRepository.findByUsername(username).orElseThrow(() -> ApiException.notFound("Joueur introuvable"));
        return ResponseEntity.ok(new PublicProfile(u.getId(), u.getUsername(), u.getRole().name(), u.getAvatar(),
                u.getBio(), u.getLevel(), u.getXp(), u.getGamesPlayed(), u.getWins(),
                leaderboardService.getRank(u), u.getCreatedAt()));
    }
}
