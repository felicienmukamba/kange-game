package com.backend.backend.game.controller;

import com.backend.backend.game.LeaderboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Set;

@RestController
@RequestMapping("/api/v1/leaderboard")
@RequiredArgsConstructor
public class LeaderboardController {

    private final LeaderboardService leaderboardService;

    @GetMapping("/global")
    public ResponseEntity<Set<LeaderboardService.LeaderboardEntry>> getGlobalLeaderboard(
            @RequestParam(defaultValue = "10") int limit
    ) {
        return ResponseEntity.ok(leaderboardService.getTopPlayers(limit));
    }
}
