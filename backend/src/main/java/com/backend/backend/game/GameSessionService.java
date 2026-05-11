package com.backend.backend.game;

import com.backend.backend.game.model.QuizQuestion;
import lombok.Data;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class GameSessionService {

    @Data
    public static class Session {
        private String id;
        private List<QuizQuestion> questions = new ArrayList<>();
        private int currentQuestionIndex = -1;
        private Map<String, Integer> scores = new ConcurrentHashMap<>();
        private String status = "WAITING"; // WAITING, ACTIVE, FINISHED
    }

    private final Map<String, Session> sessions = new ConcurrentHashMap<>();

    public Session createSession(String sessionId) {
        Session session = new Session();
        session.setId(sessionId);
        
        // Add mock questions
        QuizQuestion q1 = new QuizQuestion();
        q1.setId("1");
        q1.setQuestion("What is the capital of France?");
        q1.setOptions(new String[]{"London", "Berlin", "Paris", "Madrid"});
        q1.setCorrectAnswerIndex(2);
        q1.setTimeLimit(15);
        
        session.getQuestions().add(q1);
        sessions.put(sessionId, session);
        return session;
    }

    public Session getSession(String sessionId) {
        return sessions.get(sessionId);
    }

    private final com.backend.backend.reward.RewardService rewardService;

    public void finishSession(String sessionId) {
        Session session = sessions.get(sessionId);
        if (session != null) {
            session.setStatus("FINISHED");
            session.getScores().forEach((username, score) -> {
                // Logic: 10 XP and 5 Coins per point
                rewardService.grantReward(username, score * 10L, score * 5L);
            });
        }
    }
}
