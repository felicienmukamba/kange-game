package com.backend.backend.monitoring;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;

@Service
public class MetricsService {

    private final Counter gamesStartedCounter;
    private final Counter answersSubmittedCounter;
    private final Counter usersRegisteredCounter;

    public MetricsService(MeterRegistry registry) {
        this.gamesStartedCounter = Counter.builder("rewify.games.started")
                .description("Number of games started")
                .register(registry);
        this.answersSubmittedCounter = Counter.builder("rewify.answers.submitted")
                .description("Number of quiz answers submitted")
                .register(registry);
        this.usersRegisteredCounter = Counter.builder("rewify.users.registered")
                .description("Number of new users registered")
                .register(registry);
    }

    public void incrementGamesStarted() {
        gamesStartedCounter.increment();
    }

    public void incrementAnswersSubmitted() {
        answersSubmittedCounter.increment();
    }

    public void incrementUsersRegistered() {
        usersRegisteredCounter.increment();
    }
}
