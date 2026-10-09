package com.backend.backend.quest;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/quests")
@RequiredArgsConstructor
public class QuestController {

    private final QuestService questService;

    @GetMapping
    public ResponseEntity<QuestService.QuestBoard> board(Authentication auth) {
        return ResponseEntity.ok(questService.board(auth.getName()));
    }

    @PostMapping("/{questId}/claim")
    public ResponseEntity<QuestService.QuestBoard> claim(@PathVariable String questId, Authentication auth) {
        return ResponseEntity.ok(questService.claim(auth.getName(), questId));
    }

    @PostMapping("/daily-bonus")
    public ResponseEntity<QuestService.QuestBoard> dailyBonus(Authentication auth) {
        return ResponseEntity.ok(questService.claimDailyBonus(auth.getName()));
    }
}
