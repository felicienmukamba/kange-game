package com.backend.backend.game.controller;

import com.backend.backend.game.ChallengeService;
import com.backend.backend.game.GameSessionService;
import com.backend.backend.game.model.GameChallenge;
import com.backend.backend.game.repository.GameChallengeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/challenges")
@RequiredArgsConstructor
public class GameChallengeController {

    private final GameChallengeRepository repository;
    private final ChallengeService challengeService;
    private final GameSessionService gameSessionService;

    /** Public listing — never exposes answers. */
    public record ChallengeSummary(
            Long id, String title, String topic, String creator, int prizePool, int maxPlayers,
            int questionCount, String prizeWinner, String roomId, int playersInRoom, String roomStatus,
            LocalDateTime createdAt
    ) {}

    @PostMapping
    public ResponseEntity<GameChallenge> createChallenge(
            @RequestBody ChallengeService.CreateChallengeRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(challengeService.create(authentication.getName(), request));
    }

    /** The creator's own challenges, including questions and answers. */
    @GetMapping("/my")
    @Transactional(readOnly = true)
    public ResponseEntity<List<GameChallenge>> getMyChallenges(Authentication authentication) {
        return ResponseEntity.ok(repository.findByCreatorOrderByCreatedAtDesc(authentication.getName()));
    }

    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<List<ChallengeSummary>> getAllChallenges() {
        return ResponseEntity.ok(repository.findByPublicChallengeTrueOrderByCreatedAtDesc().stream()
                .map(this::summarize)
                .toList());
    }

    private ChallengeSummary summarize(GameChallenge c) {
        String roomId = "challenge-" + c.getId();
        var session = gameSessionService.getSession(roomId);
        return new ChallengeSummary(
                c.getId(), c.getTitle(), c.getTopic(), c.getCreator(),
                c.getPrizePool() == null ? 0 : c.getPrizePool(),
                c.getMaxPlayers() == null ? 0 : c.getMaxPlayers(),
                c.getQuestions().size(), c.getPrizeWinner(), roomId,
                session.map(s -> s.getPlayers().size()).orElse(0),
                session.map(s -> s.getStatus().name()).orElse("IDLE"),
                c.getCreatedAt()
        );
    }
}
