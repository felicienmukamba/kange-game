package com.backend.backend.game.model;

import jakarta.persistence.Embeddable;
import lombok.Data;

@Data
@Embeddable
public class QuizQuestion {
    private String id;
    private String question;
    private String[] options;
    private int correctAnswerIndex;
    private int timeLimit; // seconds
}
