package com.backend.backend.game.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity
@Table(name = "game_challenges")
@Data
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

    @ElementCollection
    private List<QuizQuestion> questions;

    @Builder.Default
    private boolean isPublic = true;
}
