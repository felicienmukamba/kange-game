package com.backend.backend.game.controller;

import com.backend.backend.game.GameSessionService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class GameController {

    private final GameSessionService gameSessionService;

    @Data
    public static class AnswerPayload {
        private int answerIndex;
    }

    @MessageMapping("/game/{roomId}/join")
    public void joinGame(@DestinationVariable String roomId, Authentication authentication) {
        // Just ensuring session exists for demo purposes
        if (gameSessionService.getSession(roomId) == null) {
            gameSessionService.createSession(roomId);
        }
    }

    @MessageMapping("/game/{roomId}/start")
    public void startGame(@DestinationVariable String roomId) {
        gameSessionService.startSession(roomId);
    }

    @MessageMapping("/game/{roomId}/answer")
    public void submitAnswer(
            @DestinationVariable String roomId,
            @Payload AnswerPayload payload,
            Authentication authentication
    ) {
        gameSessionService.submitAnswer(roomId, authentication.getName(), payload.getAnswerIndex());
    }
}
