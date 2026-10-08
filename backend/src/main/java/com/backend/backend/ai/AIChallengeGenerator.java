package com.backend.backend.ai;

import com.backend.backend.game.QuestionBank;
import com.backend.backend.game.model.QuizQuestion;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Generates quiz questions for a topic. Uses the configured LLM with structured
 * output when available; otherwise (or on failure) uses the built-in question bank.
 */
@Service
@Slf4j
public class AIChallengeGenerator {

    public static final int MAX_QUESTIONS = 20;

    private final ChatClient chatClient;
    private final QuestionBank questionBank;

    public AIChallengeGenerator(ObjectProvider<ChatModel> chatModel, QuestionBank questionBank) {
        ChatModel model = chatModel.getIfAvailable();
        this.chatClient = model != null ? ChatClient.create(model) : null;
        this.questionBank = questionBank;
    }

    public boolean isAiEnabled() {
        return chatClient != null;
    }

    public List<QuizQuestion> generateQuiz(String topic, int count) {
        int n = Math.clamp(count, 1, MAX_QUESTIONS);

        if (chatClient != null && !QuestionBank.isMathTopic(topic)) {
            try {
                List<QuizQuestion> questions = chatClient.prompt()
                        .user(u -> u.text("""
                                Generate {count} multiple-choice quiz questions about "{topic}".
                                Each question must have exactly 4 options, exactly one correct answer,
                                and correctAnswerIndex must be the 0-based index of that answer.
                                Keep questions short enough to read in a few seconds.
                                """)
                                .param("count", n)
                                .param("topic", topic))
                        .call()
                        .entity(new ParameterizedTypeReference<List<QuizQuestion>>() {});
                List<QuizQuestion> valid = sanitize(questions);
                if (!valid.isEmpty()) return valid;
            } catch (Exception ex) {
                log.warn("AI quiz generation failed for topic '{}', using question bank: {}", topic, ex.getMessage());
            }
        }
        return questionBank.questionsFor(topic, n);
    }

    private List<QuizQuestion> sanitize(List<QuizQuestion> questions) {
        if (questions == null) return List.of();
        return questions.stream()
                .filter(q -> q.getQuestion() != null && q.getOptions() != null && q.getOptions().length == 4)
                .filter(q -> q.getCorrectAnswerIndex() >= 0 && q.getCorrectAnswerIndex() < 4)
                .limit(MAX_QUESTIONS)
                .peek(q -> {
                    q.setId(UUID.randomUUID().toString());
                    if (q.getTimeLimit() <= 0) q.setTimeLimit(QuestionBank.DEFAULT_TIME_LIMIT);
                })
                .toList();
    }
}
