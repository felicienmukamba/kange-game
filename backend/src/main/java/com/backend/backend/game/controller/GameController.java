package com.backend.backend.game.controller;

import com.backend.backend.game.GameSessionService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
@RequiredArgsConstructor
public class GameController {

    private final GameSessionService gameSessionService;

    @Data
    public static class AnswerPayload {
        private int answerIndex;
    }

    @MessageMapping("/game/{roomId}/join")
    public void joinGame(@DestinationVariable String roomId, Principal principal) {
        gameSessionService.join(roomId, principal.getName());
    }

    @MessageMapping("/game/{roomId}/leave")
    public void leaveGame(@DestinationVariable String roomId, Principal principal) {
        gameSessionService.leave(roomId, principal.getName());
    }

    @MessageMapping("/game/{roomId}/start")
    public void startGame(@DestinationVariable String roomId, Principal principal) {
        gameSessionService.startSession(roomId, principal.getName());
    }

    @MessageMapping("/game/{roomId}/answer")
    public void submitAnswer(
            @DestinationVariable String roomId,
            @Payload AnswerPayload payload,
            Principal principal
    ) {
        gameSessionService.submitAnswer(roomId, principal.getName(), payload.getAnswerIndex());
    }
}
