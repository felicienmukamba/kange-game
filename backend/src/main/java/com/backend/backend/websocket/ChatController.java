package com.backend.backend.websocket;

import com.backend.backend.ai.AIModerationService;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.time.Instant;

@Controller
@RequiredArgsConstructor
public class ChatController {

    private static final int MAX_LENGTH = 500;

    private final AIModerationService moderationService;

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
            @Payload ChatMessage message,
            Principal principal
    ) {
        String text = message.getText() == null ? "" : message.getText().trim();
        if (text.length() > MAX_LENGTH) text = text.substring(0, MAX_LENGTH);

        // Never trust the client-supplied sender name
        message.setSender(principal.getName());
        message.setText(text);
        message.setTimestamp(Instant.now());

        if (!moderationService.isContentSafe(text)) {
            message.setSender("System");
            message.setText("🚫 This message was removed for violating community guidelines.");
        }
        return message;
    }
}
