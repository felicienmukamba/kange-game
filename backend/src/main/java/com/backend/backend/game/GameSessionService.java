package com.backend.backend.game;

import com.backend.backend.game.model.GameChallenge;
import com.backend.backend.game.model.QuizQuestion;
import com.backend.backend.game.repository.GameChallengeRepository;
import com.backend.backend.monitoring.MetricsService;
import com.backend.backend.reward.RewardService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;

/**
 * Runs synchronized quiz rooms over STOMP.
 *
 * <p>Room ids select the question source: {@code challenge-<id>} plays a saved
 * challenge; {@code math-*}, {@code words-*}, {@code gaming-*} and anything else
 * (trivia) play from the built-in question bank.</p>
 *
 * <p>Broadcasts on {@code /topic/game/<roomId>}: LOBBY, QUESTION, REVEAL, FINISHED.
 * Private feedback goes to {@code /user/queue/game}.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GameSessionService {

    public static final int BASE_POINTS = 10;
    public static final int MAX_SPEED_BONUS = 10;
    private static final Duration REVEAL_PAUSE = Duration.ofSeconds(4);
    private static final int DEFAULT_QUESTION_COUNT = 5;
    private static final int MATH_QUESTION_COUNT = 10;

    public enum Status { WAITING, ACTIVE, FINISHED }

    @Getter
    public static class Session {
        private final String id;
        private final String title;
        private final String host;
        private final List<QuizQuestion> questions;
        private final Set<String> players = ConcurrentHashMap.newKeySet();
        private final Map<String, Integer> scores = new ConcurrentHashMap<>();
        private final Set<String> answeredCurrent = ConcurrentHashMap.newKeySet();
        private volatile int currentQuestionIndex = -1;
        private volatile Status status = Status.WAITING;
        private volatile Instant questionEndsAt;

        Session(String id, String title, String host, List<QuizQuestion> questions) {
            this.id = id;
            this.title = title;
            this.host = host;
            this.questions = List.copyOf(questions);
        }
    }

    /** What players see: never includes the correct answer. */
    public record PublicQuestion(String id, String question, String[] options, int timeLimit, int index, int total) {}

    private final Map<String, Session> sessions = new ConcurrentHashMap<>();
    private final Map<String, ScheduledFuture<?>> tasks = new ConcurrentHashMap<>();

    private final SimpMessagingTemplate messagingTemplate;
    private final TaskScheduler taskScheduler;
    private final RewardService rewardService;
    private final QuestionBank questionBank;
    private final GameChallengeRepository challengeRepository;
    private final MetricsService metricsService;
    private final ChallengeService challengeService;

    public Session join(String roomId, String username) {
        Session session = sessions.computeIfAbsent(roomId, id -> createSession(id, username));
        session.getPlayers().add(username);
        session.getScores().putIfAbsent(username, 0);
        broadcastLobby(session);
        if (session.getStatus() == Status.ACTIVE) {
            sendCurrentQuestionTo(session, username);
        }
        return session;
    }

    public void leave(String roomId, String username) {
        Session session = sessions.get(roomId);
        if (session == null) return;
        session.getPlayers().remove(username);
        broadcastLobby(session);
    }

    public void startSession(String roomId, String username) {
        Session session = sessions.get(roomId);
        if (session == null || !session.getPlayers().contains(username)) return;
        synchronized (session) {
            if (session.getStatus() != Status.WAITING) return;
            session.status = Status.ACTIVE;
        }
        metricsService.incrementGamesStarted();
        nextQuestion(roomId);
    }

    public void submitAnswer(String roomId, String username, int answerIndex) {
        Session session = sessions.get(roomId);
        if (session == null || session.getStatus() != Status.ACTIVE) return;

        QuizQuestion current;
        synchronized (session) {
            int idx = session.getCurrentQuestionIndex();
            if (idx < 0 || idx >= session.getQuestions().size()) return;
            if (Instant.now().isAfter(session.getQuestionEndsAt())) return;
            // One answer per player per question
            if (!session.getAnsweredCurrent().add(username)) return;
            current = session.getQuestions().get(idx);
        }
        metricsService.incrementAnswersSubmitted();
        session.getPlayers().add(username);

        boolean correct = current.getCorrectAnswerIndex() == answerIndex;
        int points = 0;
        if (correct) {
            long msLeft = Math.max(0, Duration.between(Instant.now(), session.getQuestionEndsAt()).toMillis());
            int bonus = (int) Math.round(MAX_SPEED_BONUS * (msLeft / (current.getTimeLimit() * 1000.0)));
            points = BASE_POINTS + Math.min(bonus, MAX_SPEED_BONUS);
            session.getScores().merge(username, points, Integer::sum);
        } else {
            session.getScores().putIfAbsent(username, 0);
        }
        sendToUser(username, Map.of(
                "type", correct ? "CORRECT" : "WRONG",
                "points", points
        ));

        // Everyone answered: reveal early instead of waiting for the timer
        if (session.getAnsweredCurrent().containsAll(session.getPlayers())) {
            ScheduledFuture<?> pending = tasks.remove(roomId);
            if (pending != null && pending.cancel(false)) {
                revealAnswer(roomId);
            }
        }
    }

    public Optional<Session> getSession(String roomId) {
        return Optional.ofNullable(sessions.get(roomId));
    }

    private Session createSession(String roomId, String firstPlayer) {
        if (roomId.startsWith("challenge-")) {
            Long challengeId = parseChallengeId(roomId);
            GameChallenge challenge = challengeId == null ? null : challengeRepository.findById(challengeId).orElse(null);
            if (challenge != null && challenge.getQuestions() != null && !challenge.getQuestions().isEmpty()) {
                return new Session(roomId, challenge.getTitle(), challenge.getCreator(), challenge.getQuestions());
            }
        }
        String topic = roomId.split("-")[0];
        if ("challenge".equals(topic)) topic = "trivia";
        int count = QuestionBank.isMathTopic(topic) ? MATH_QUESTION_COUNT : DEFAULT_QUESTION_COUNT;
        return new Session(roomId, titleFor(topic), firstPlayer, questionBank.questionsFor(topic, count));
    }

    private static Long parseChallengeId(String roomId) {
        try {
            return Long.parseLong(roomId.substring("challenge-".length()));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static String titleFor(String topic) {
        if (QuestionBank.isMathTopic(topic)) return "Speed Math";
        return switch (topic.toLowerCase(Locale.ROOT)) {
            case "words" -> "Word Rush";
            case "gaming" -> "Gamer Trivia";
            default -> "Quiz Battle";
        };
    }

    private void nextQuestion(String roomId) {
        Session session = sessions.get(roomId);
        if (session == null) return;

        int idx;
        synchronized (session) {
            idx = session.getCurrentQuestionIndex() + 1;
            session.currentQuestionIndex = idx;
            session.getAnsweredCurrent().clear();
            if (idx < session.getQuestions().size()) {
                session.questionEndsAt = Instant.now().plusSeconds(session.getQuestions().get(idx).getTimeLimit());
            }
        }

        if (idx >= session.getQuestions().size()) {
            finishSession(roomId);
            return;
        }

        broadcast(roomId, questionPayload(session));
        tasks.put(roomId, taskScheduler.schedule(() -> revealAnswer(roomId), session.getQuestionEndsAt()));
    }

    private void revealAnswer(String roomId) {
        Session session = sessions.get(roomId);
        if (session == null) return;
        QuizQuestion q = session.getQuestions().get(session.getCurrentQuestionIndex());
        broadcast(roomId, Map.of(
                "type", "REVEAL",
                "questionId", q.getId(),
                "correctAnswerIndex", q.getCorrectAnswerIndex(),
                "scores", session.getScores()
        ));
        tasks.put(roomId, taskScheduler.schedule(() -> nextQuestion(roomId), Instant.now().plus(REVEAL_PAUSE)));
    }

    private void finishSession(String roomId) {
        Session session = sessions.remove(roomId);
        tasks.remove(roomId);
        if (session == null) return;
        session.status = Status.FINISHED;

        broadcast(roomId, Map.of(
                "type", "FINISHED",
                "scores", session.getScores()
        ));

        int best = session.getScores().values().stream().max(Integer::compare).orElse(0);
        session.getScores().forEach((username, score) -> {
            try {
                boolean won = score > 0 && score == best;
                rewardService.grantGameReward(username, score, won);
            } catch (Exception ex) {
                log.error("Failed to grant reward to {}: {}", username, ex.getMessage());
            }
        });

        Long challengeId = roomId.startsWith("challenge-") ? parseChallengeId(roomId) : null;
        if (challengeId != null && best > 0) {
            // Ties go to the player who reached the top score first in iteration order
            session.getScores().entrySet().stream()
                    .filter(e -> e.getValue() == best)
                    .map(Map.Entry::getKey)
                    .findFirst()
                    .ifPresent(winner -> {
                        try {
                            challengeService.awardPrize(challengeId, winner);
                        } catch (Exception ex) {
                            log.error("Failed to award challenge {} prize: {}", challengeId, ex.getMessage());
                        }
                    });
        }
    }

    private Map<String, Object> questionPayload(Session session) {
        int idx = session.getCurrentQuestionIndex();
        QuizQuestion q = session.getQuestions().get(idx);
        return Map.of(
                "type", "QUESTION",
                "data", new PublicQuestion(q.getId(), q.getQuestion(), q.getOptions(), q.getTimeLimit(), idx, session.getQuestions().size()),
                "endsAt", session.getQuestionEndsAt().toEpochMilli()
        );
    }

    private void sendCurrentQuestionTo(Session session, String username) {
        int idx = session.getCurrentQuestionIndex();
        if (idx < 0 || idx >= session.getQuestions().size()) return;
        sendToUser(username, questionPayload(session));
    }

    private void broadcastLobby(Session session) {
        broadcast(session.getId(), Map.of(
                "type", "LOBBY",
                "title", session.getTitle(),
                "host", session.getHost() == null ? "" : session.getHost(),
                "status", session.getStatus().name(),
                "players", List.copyOf(session.getPlayers()),
                "scores", session.getScores(),
                "totalQuestions", session.getQuestions().size()
        ));
    }

    private void broadcast(String roomId, Object payload) {
        messagingTemplate.convertAndSend("/topic/game/" + roomId, payload);
    }

    private void sendToUser(String username, Object payload) {
        messagingTemplate.convertAndSendToUser(username, "/queue/game", payload);
    }
}
