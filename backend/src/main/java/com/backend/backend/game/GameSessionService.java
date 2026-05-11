package com.backend.backend.game;

import com.backend.backend.game.model.QuizQuestion;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;

@Service
@RequiredArgsConstructor
public class GameSessionService {

    @Data
    public static class Session {
        private String id;
        private List<QuizQuestion> questions = new ArrayList<>();
        private int currentQuestionIndex = -1;
        private Map<String, Integer> scores = new ConcurrentHashMap<>();
        private String status = "WAITING"; // WAITING, ACTIVE, FINISHED
        private Instant nextEventAt;
    }

    private final Map<String, Session> sessions = new ConcurrentHashMap<>();
    private final Map<String, ScheduledFuture<?>> tasks = new ConcurrentHashMap<>();
    
    private final SimpMessagingTemplate messagingTemplate;
    private final TaskScheduler taskScheduler;
    private final com.backend.backend.reward.RewardService rewardService;
    private final LeaderboardService leaderboardService;

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

        QuizQuestion q2 = new QuizQuestion();
        q2.setId("2");
        q2.setQuestion("Which planet is known as the Red Planet?");
        q2.setOptions(new String[]{"Venus", "Mars", "Jupiter", "Saturn"});
        q2.setCorrectAnswerIndex(1);
        q2.setTimeLimit(15);
        
        session.getQuestions().add(q1);
        session.getQuestions().add(q2);
        sessions.put(sessionId, session);
        return session;
    }

    public void startSession(String sessionId) {
        Session session = sessions.get(sessionId);
        if (session != null && session.getStatus().equals("WAITING")) {
            session.setStatus("ACTIVE");
            nextQuestion(sessionId);
        }
    }

    private void nextQuestion(String sessionId) {
        Session session = sessions.get(sessionId);
        if (session == null) return;

        session.setCurrentQuestionIndex(session.getCurrentQuestionIndex() + 1);
        
        if (session.getCurrentQuestionIndex() < session.getQuestions().size()) {
            QuizQuestion question = session.getQuestions().get(session.getCurrentQuestionIndex());
            session.setNextEventAt(Instant.now().plusSeconds(question.getTimeLimit()));
            
            // Broadcast question
            messagingTemplate.convertAndSend("/topic/game/" + sessionId, Map.of(
                "type", "QUESTION",
                "data", question,
                "nextEventAt", session.getNextEventAt()
            ));

            // Schedule next event
            tasks.put(sessionId, taskScheduler.schedule(() -> nextQuestion(sessionId), session.getNextEventAt()));
        } else {
            finishSession(sessionId);
        }
    }

    public void submitAnswer(String sessionId, String username, int answerIndex) {
        Session session = sessions.get(sessionId);
        if (session != null && session.getStatus().equals("ACTIVE")) {
            QuizQuestion current = session.getQuestions().get(session.getCurrentQuestionIndex());
            if (current.getCorrectAnswerIndex() == answerIndex) {
                session.getScores().merge(username, 10, Integer::sum);
                // Notify user of success
                messagingTemplate.convertAndSendToUser(username, "/queue/game", Map.of("type", "CORRECT"));
            }
        }
    }

    public Session getSession(String sessionId) {
        return sessions.get(sessionId);
    }

    public void finishSession(String sessionId) {
        Session session = sessions.get(sessionId);
        if (session != null) {
            session.setStatus("FINISHED");
            messagingTemplate.convertAndSend("/topic/game/" + sessionId, Map.of(
                "type", "FINISHED",
                "scores", session.getScores()
            ));

            session.getScores().forEach((username, score) -> {
                rewardService.grantReward(username, score * 10L, score * 5L);
                leaderboardService.updateScore(username, score);
            });
            
            sessions.remove(sessionId);
            tasks.remove(sessionId);
        }
    }
}
