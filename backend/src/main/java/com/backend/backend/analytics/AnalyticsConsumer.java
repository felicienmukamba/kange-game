package com.backend.backend.analytics;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@Slf4j
public class AnalyticsConsumer {

    @KafkaListener(topics = "rewify:analytics:events", groupId = "analytics-group")
    public void consumeEvent(Map<String, Object> event) {
        log.info("Processing analytics event: type={}, timestamp={}", event.get("type"), event.get("timestamp"));
        
        // Here we would typically save to a time-series database like ClickHouse or InfluxDB
        // For the MVP, we just log the event.
    }
}
