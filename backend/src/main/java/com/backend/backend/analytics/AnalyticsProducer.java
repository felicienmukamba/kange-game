package com.backend.backend.analytics;

import lombok.RequiredArgsConstructor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class AnalyticsProducer {

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private static final String ANALYTICS_TOPIC = "rewify:analytics:events";

    public void sendEvent(String eventType, Map<String, Object> data) {
        data.put("timestamp", System.currentTimeMillis());
        data.put("type", eventType);
        kafkaTemplate.send(ANALYTICS_TOPIC, data);
    }
}
