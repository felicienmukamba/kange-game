package com.backend.backend.quest.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

/** A daily quest reward that was already collected. */
@Entity
@Table(name = "quest_claims", uniqueConstraints = @UniqueConstraint(columnNames = {"username", "claim_day", "quest_id"}))
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuestClaim {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 32)
    private String username;

    @Column(name = "claim_day", nullable = false)
    private LocalDate day;

    @Column(name = "quest_id", nullable = false, length = 32)
    private String questId;
}
