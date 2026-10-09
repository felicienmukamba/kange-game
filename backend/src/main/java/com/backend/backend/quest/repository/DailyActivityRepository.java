package com.backend.backend.quest.repository;

import com.backend.backend.quest.domain.ActivityType;
import com.backend.backend.quest.domain.DailyActivity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DailyActivityRepository extends JpaRepository<DailyActivity, Long> {
    Optional<DailyActivity> findByUsernameAndDayAndType(String username, LocalDate day, ActivityType type);
    List<DailyActivity> findByUsernameAndDay(String username, LocalDate day);
}
