package com.backend.backend.game.controller;

import com.backend.backend.game.model.GameMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class GameSocketController {

    private final SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/game.join")
    @SendTo("/topic/public")
    public GameMessage joinGame(@Payload GameMessage gameMessage, SimpMessageHeaderAccessor headerAccessor) {
        headerAccessor.getSessionAttributes().put("username", gameMessage.getSender());
        return gameMessage;
    }

    @MessageMapping("/game.sendAnswer")
    public void sendAnswer(@Payload GameMessage gameMessage) {
        // Logic to validate answer and update score
        // Then broadcast updated leaderboard
        messagingTemplate.convertAndSend("/topic/public", gameMessage);
    }
    
    @MessageMapping("/chat.sendMessage")
    @SendTo("/topic/public")
    public GameMessage sendMessage(@Payload GameMessage gameMessage) {
        return gameMessage;
    }
}
