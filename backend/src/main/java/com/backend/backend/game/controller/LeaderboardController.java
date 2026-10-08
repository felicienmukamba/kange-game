package com.backend.backend.game.controller;

import com.backend.backend.core.domain.User;
import com.backend.backend.game.LeaderboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/leaderboard")
@RequiredArgsConstructor
public class LeaderboardController {

    private final LeaderboardService leaderboardService;

    @GetMapping("/global")
    public ResponseEntity<List<LeaderboardService.LeaderboardEntry>> getGlobalLeaderboard(
            @RequestParam(defaultValue = "10") int limit
    ) {
        return ResponseEntity.ok(leaderboardService.getTopPlayers(limit));
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Long>> getMyRank(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(Map.of("rank", leaderboardService.getRank(user)));
    }
}
