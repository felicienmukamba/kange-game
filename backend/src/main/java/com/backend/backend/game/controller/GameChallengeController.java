package com.backend.backend.game.controller;

import com.backend.backend.game.model.GameChallenge;
import com.backend.backend.game.repository.GameChallengeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/challenges")
@RequiredArgsConstructor
public class GameChallengeController {

    private final GameChallengeRepository repository;

    @PostMapping
    public ResponseEntity<GameChallenge> createChallenge(
            @RequestBody GameChallenge challenge,
            Authentication authentication
    ) {
        challenge.setCreator(authentication.getName());
        return ResponseEntity.ok(repository.save(challenge));
    }

    @GetMapping("/my")
    public ResponseEntity<List<GameChallenge>> getMyChallenges(Authentication authentication) {
        return ResponseEntity.ok(repository.findByCreator(authentication.getName()));
    }

    @GetMapping
    public ResponseEntity<List<GameChallenge>> getAllChallenges() {
        return ResponseEntity.ok(repository.findAll());
    }
}
