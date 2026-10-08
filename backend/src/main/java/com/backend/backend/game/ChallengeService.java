package com.backend.backend.game;

import com.backend.backend.ai.AIChallengeGenerator;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.game.model.GameChallenge;
import com.backend.backend.game.model.QuizQuestion;
import com.backend.backend.game.repository.GameChallengeRepository;
import com.backend.backend.payment.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChallengeService {

    private final GameChallengeRepository repository;
    private final AIChallengeGenerator generator;
    private final WalletService walletService;

    public record CreateChallengeRequest(
            String title, String topic, Integer prizePool, Integer maxPlayers,
            Integer questionCount, List<QuizQuestion> questions
    ) {}

    /** Creates a challenge; the prize pool is escrowed from the creator's balance. */
    @Transactional
    public GameChallenge create(String creator, CreateChallengeRequest req) {
        if (req.title() == null || req.title().isBlank()) throw ApiException.badRequest("Title is required");
        String topic = req.topic() == null || req.topic().isBlank() ? "trivia" : req.topic().trim();
        int prize = req.prizePool() == null ? 0 : req.prizePool();
        int maxPlayers = req.maxPlayers() == null ? 50 : req.maxPlayers();
        if (prize < 0) throw ApiException.badRequest("Prize pool cannot be negative");
        if (maxPlayers < 2 || maxPlayers > 500) throw ApiException.badRequest("Max players must be between 2 and 500");

        List<QuizQuestion> questions = req.questions() != null && !req.questions().isEmpty()
                ? validate(req.questions())
                : generator.generateQuiz(topic, req.questionCount() == null ? 5 : req.questionCount());

        if (prize > 0) walletService.processTransaction(creator, -prize, "PRIZE_ESCROW");

        return repository.save(GameChallenge.builder()
                .title(req.title().trim())
                .topic(topic)
                .creator(creator)
                .prizePool(prize)
                .maxPlayers(maxPlayers)
                .questions(questions)
                .build());
    }

    /** Pays the prize pool to the first winner of a challenge room (once). */
    @Transactional
    public void awardPrize(Long challengeId, String winner) {
        repository.findById(challengeId).ifPresent(c -> {
            if (c.getPrizeWinner() != null || c.getPrizePool() == null || c.getPrizePool() <= 0) return;
            c.setPrizeWinner(winner);
            repository.save(c);
            walletService.processTransaction(winner, c.getPrizePool(), "PRIZE");
            log.info("Challenge {} prize of {} coins awarded to {}", challengeId, c.getPrizePool(), winner);
        });
    }

    private static List<QuizQuestion> validate(List<QuizQuestion> questions) {
        if (questions.size() > AIChallengeGenerator.MAX_QUESTIONS) {
            throw ApiException.badRequest("A challenge can have at most " + AIChallengeGenerator.MAX_QUESTIONS + " questions");
        }
        for (QuizQuestion q : questions) {
            if (q.getQuestion() == null || q.getQuestion().isBlank()) throw ApiException.badRequest("Every question needs text");
            if (q.getOptions() == null || q.getOptions().length < 2 || q.getOptions().length > 4) {
                throw ApiException.badRequest("Every question needs 2 to 4 options");
            }
            if (q.getCorrectAnswerIndex() < 0 || q.getCorrectAnswerIndex() >= q.getOptions().length) {
                throw ApiException.badRequest("Invalid correct answer for: " + q.getQuestion());
            }
            if (q.getId() == null) q.setId(UUID.randomUUID().toString());
            if (q.getTimeLimit() < 5 || q.getTimeLimit() > 60) q.setTimeLimit(QuestionBank.DEFAULT_TIME_LIMIT);
        }
        return questions;
    }
}
