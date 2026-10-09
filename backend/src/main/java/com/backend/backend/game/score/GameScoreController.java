package com.backend.backend.game.score;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/games")
@RequiredArgsConstructor
public class GameScoreController {

    private final GameScoreService scoreService;

    @PostMapping("/scores")
    public ResponseEntity<GameScoreService.ScoreResult> submit(@RequestBody GameScoreService.SubmitScore request,
                                                               Authentication auth) {
        return ResponseEntity.ok(scoreService.submit(auth.getName(), request));
    }

    @GetMapping("/{gameId}/leaderboard")
    public ResponseEntity<List<GameScoreService.ScoreEntry>> leaderboard(@PathVariable String gameId,
                                                                         @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(scoreService.leaderboard(gameId, limit));
    }

    @GetMapping("/stats/me")
    public ResponseEntity<List<GameScoreService.GameStat>> myStats(Authentication auth) {
        return ResponseEntity.ok(scoreService.statsFor(auth.getName()));
    }
}
