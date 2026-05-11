package com.backend.backend.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final SimpMessagingTemplate messagingTemplate;

    public void sendPrivateNotification(String username, String message, String type) {
        Map<String, String> payload = Map.of(
            "message", message,
            "type", type
        );
        messagingTemplate.convertAndSendToUser(username, "/queue/notifications", payload);
    }

    public void broadcastGlobalNotification(String message, String type) {
        Map<String, String> payload = Map.of(
            "message", message,
            "type", type
        );
        messagingTemplate.convertAndSend("/topic/notifications", payload);
    }
}
