package com.backend.backend.quest;

import com.backend.backend.quest.domain.ActivityType;
import com.backend.backend.quest.domain.DailyActivity;
import com.backend.backend.quest.repository.DailyActivityRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.EnumMap;
import java.util.Map;

/**
 * Counts what players do each (UTC) day. Recording never fails the caller: it runs in its own
 * transaction and errors are only logged, so gameplay is never blocked by quest bookkeeping.
 */
@Service
@Slf4j
public class ActivityService {

    private final DailyActivityRepository repository;
    private final TransactionTemplate tx;

    public ActivityService(DailyActivityRepository repository, PlatformTransactionManager transactionManager) {
        this.repository = repository;
        this.tx = new TransactionTemplate(transactionManager);
        this.tx.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    public static LocalDate today() {
        return LocalDate.now(ZoneOffset.UTC);
    }

    public void record(String username, ActivityType type) {
        record(username, type, 1);
    }

    public void record(String username, ActivityType type, int amount) {
        if (username == null || amount <= 0) return;
        try {
            tx.executeWithoutResult(status -> {
                LocalDate day = today();
                DailyActivity activity = repository.findByUsernameAndDayAndType(username, day, type)
                        .orElseGet(() -> DailyActivity.builder().username(username).day(day).type(type).build());
                activity.setCount(activity.getCount() + amount);
                repository.save(activity);
            });
        } catch (Exception ex) {
            log.warn("Could not record {} for {}: {}", type, username, ex.getMessage());
        }
    }

    public Map<ActivityType, Integer> countsForToday(String username) {
        Map<ActivityType, Integer> counts = new EnumMap<>(ActivityType.class);
        for (ActivityType t : ActivityType.values()) counts.put(t, 0);
        repository.findByUsernameAndDay(username, today()).forEach(a -> counts.put(a.getType(), a.getCount()));
        return counts;
    }
}
