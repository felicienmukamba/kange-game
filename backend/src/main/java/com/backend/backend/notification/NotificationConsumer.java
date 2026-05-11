package com.backend.backend.notification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class NotificationConsumer {

    private final NotificationService notificationService;

    @KafkaListener(topics = "rewify:notifications:events", groupId = "notification-group")
    public void consumeNotificationEvent(Map<String, Object> event) {
        String type = (String) event.get("type");
        String message = (String) event.get("message");
        String targetUser = (String) event.get("targetUser");

        if (targetUser != null) {
            notificationService.sendPrivateNotification(targetUser, message, type);
        } else {
            notificationService.broadcastGlobalNotification(message, type);
        }
    }
}
