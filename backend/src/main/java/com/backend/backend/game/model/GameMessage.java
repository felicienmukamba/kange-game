package com.backend.backend.game.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class GameMessage {
    private String type; // QUESTION, ANSWER, JOIN, LEAVE, LEADERBOARD
    private String sender;
    private Object content;
}
