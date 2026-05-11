package com.backend.backend.game.model;

import lombok.Data;

@Data
public class QuizQuestion {
    private String id;
    private String question;
    private String[] options;
    private int correctAnswerIndex;
    private int timeLimit; // seconds
}
