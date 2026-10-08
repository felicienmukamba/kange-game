package com.backend.backend.game.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.Data;

@Data
@Embeddable
public class QuizQuestion {
    @Column(name = "question_uid")
    private String id;
    @Column(length = 500)
    private String question;
    private String[] options;
    private int correctAnswerIndex;
    private int timeLimit; // seconds
}
