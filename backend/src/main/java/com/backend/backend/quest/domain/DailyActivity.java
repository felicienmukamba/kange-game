package com.backend.backend.quest.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

/** How many times a user did something on a given day; drives daily quests. */
@Entity
@Table(name = "daily_activity",
        uniqueConstraints = @UniqueConstraint(columnNames = {"username", "activity_day", "activity_type"}),
        indexes = @Index(columnList = "username, activity_day"))
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyActivity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 32)
    private String username;

    @Column(name = "activity_day", nullable = false)
    private LocalDate day;

    @Enumerated(EnumType.STRING)
    @Column(name = "activity_type", nullable = false, length = 24)
    private ActivityType type;

    @Builder.Default
    @Column(name = "activity_count")
    private int count = 0;
}
