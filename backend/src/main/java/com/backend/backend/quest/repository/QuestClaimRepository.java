package com.backend.backend.quest.repository;

import com.backend.backend.quest.domain.QuestClaim;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface QuestClaimRepository extends JpaRepository<QuestClaim, Long> {
    List<QuestClaim> findByUsernameAndDay(String username, LocalDate day);
    boolean existsByUsernameAndDayAndQuestId(String username, LocalDate day, String questId);
}
