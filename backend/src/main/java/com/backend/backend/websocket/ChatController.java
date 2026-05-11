package com.backend.backend.websocket;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import java.time.Instant;

@Controller
public class ChatController {

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ChatMessage {
        private String sender;
        private String text;
        private Instant timestamp;
    }

    @MessageMapping("/chat/{roomId}")
    @SendTo("/topic/chat/{roomId}")
    public ChatMessage sendMessage(
            @DestinationVariable String roomId,
            @Payload ChatMessage message
    ) {
        message.setTimestamp(Instant.now());
        return message;
    }
}
