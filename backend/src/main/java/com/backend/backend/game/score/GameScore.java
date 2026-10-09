package com.backend.backend.game.score;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** One finished solo run of a catalogue game. */
@Entity
@Table(name = "game_scores", indexes = {
        @Index(columnList = "gameId, score"),
        @Index(columnList = "username, createdAt")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GameScore {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 32)
    private String username;

    @Column(nullable = false, length = 40)
    private String gameId;

    private long score;

    /** Performance on a 0-100 scale, used for rewards so every game pays out alike. */
    private int rating;

    private long durationMs;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
