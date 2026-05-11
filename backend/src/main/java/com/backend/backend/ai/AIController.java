package com.backend.backend.ai;

import com.backend.backend.game.model.QuizQuestion;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
public class AIController {

    private final AIChallengeGenerator aiChallengeGenerator;

    @GetMapping("/generate-quiz")
    public ResponseEntity<List<QuizQuestion>> generateQuiz(
            @RequestParam String topic,
            @RequestParam(defaultValue = "5") int count
    ) {
        return ResponseEntity.ok(aiChallengeGenerator.generateQuiz(topic, count));
    }
}
