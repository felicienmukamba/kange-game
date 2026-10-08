package com.backend.backend.game.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "game_challenges")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GameChallenge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String topic;
    private String creator;

    @Builder.Default
    private Integer prizePool = 0;

    @Builder.Default
    private Integer maxPlayers = 50;

    /** Username of the player who won the prize pool, once awarded. */
    private String prizeWinner;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "game_challenge_questions", joinColumns = @JoinColumn(name = "challenge_id"))
    @OrderColumn(name = "position")
    @Builder.Default
    private List<QuizQuestion> questions = new ArrayList<>();

    @Builder.Default
    private boolean publicChallenge = true;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
