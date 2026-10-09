package com.backend.backend.game;

import com.backend.backend.game.model.QuizQuestion;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Built-in French question bank ({@code content/quiz.json}, the same file the mobile app ships)
 * used when no AI model is configured and for the always-available rooms.
 * Math questions are generated on the fly.
 */
@Component
public class QuestionBank {

    public static final int DEFAULT_TIME_LIMIT = 15;
    private static final int MATH_TIME_LIMIT = 10;
    private static final String DEFAULT_TOPIC = "culture";

    /** Topic names used by the web app and older room ids, mapped onto the French bank. */
    private static final Map<String, String> ALIASES = Map.of(
            "trivia", "culture",
            "words", "langue",
            "foot", "football",
            "quiz", "culture",
            "challenge", "culture"
    );

    record Q(String q, List<String> o, int a) {}

    private final Map<String, List<Q>> bank;

    public QuestionBank() {
        try (InputStream in = new ClassPathResource("content/quiz.json").getInputStream()) {
            this.bank = Map.copyOf(JsonMapper.builder().build().readValue(in, new TypeReference<Map<String, List<Q>>>() {}));
        } catch (IOException ex) {
            throw new UncheckedIOException("Cannot load content/quiz.json", ex);
        }
    }

    public static boolean isMathTopic(String topic) {
        String t = topic == null ? "" : topic.toLowerCase(Locale.ROOT);
        return t.contains("math") || t.contains("speed") || t.contains("arithmetic") || t.contains("calcul");
    }

    public List<String> topics() {
        return bank.keySet().stream().sorted().toList();
    }

    String bankKey(String topic) {
        String t = topic == null ? "" : topic.toLowerCase(Locale.ROOT).trim();
        t = ALIASES.getOrDefault(t, t);
        if (bank.containsKey(t)) return t;
        if (t.contains("game")) return "gaming";
        return DEFAULT_TOPIC;
    }

    public List<QuizQuestion> questionsFor(String topic, int count) {
        if (isMathTopic(topic)) return mathQuestions(count);

        List<Q> pool = new ArrayList<>(bank.get(bankKey(topic)));
        Collections.shuffle(pool);
        List<QuizQuestion> result = new ArrayList<>();
        for (int i = 0; i < Math.min(count, pool.size()); i++) {
            Q q = pool.get(i);
            // Shuffle options so the answer position can't be memorised.
            List<String> options = new ArrayList<>(q.o());
            String correct = options.get(q.a());
            Collections.shuffle(options);
            result.add(toQuestion(q.q(), options.toArray(String[]::new), options.indexOf(correct), DEFAULT_TIME_LIMIT));
        }
        return result;
    }

    private List<QuizQuestion> mathQuestions(int count) {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        List<QuizQuestion> result = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            int a = rnd.nextInt(2, 50);
            int b = rnd.nextInt(2, 20);
            int op = rnd.nextInt(3);
            String symbol = switch (op) { case 0 -> "+"; case 1 -> "−"; default -> "×"; };
            int answer = switch (op) { case 0 -> a + b; case 1 -> a - b; default -> a * b; };

            List<Integer> options = new ArrayList<>(List.of(answer));
            while (options.size() < 4) {
                int candidate = answer + rnd.nextInt(-10, 11);
                if (candidate != answer && !options.contains(candidate)) options.add(candidate);
            }
            Collections.shuffle(options);
            String[] labels = options.stream().map(String::valueOf).toArray(String[]::new);
            result.add(toQuestion(a + " " + symbol + " " + b + " = ?", labels, options.indexOf(answer), MATH_TIME_LIMIT));
        }
        return result;
    }

    private static QuizQuestion toQuestion(String text, String[] options, int correct, int timeLimit) {
        QuizQuestion q = new QuizQuestion();
        q.setId(UUID.randomUUID().toString());
        q.setQuestion(text);
        q.setOptions(options.clone());
        q.setCorrectAnswerIndex(correct);
        q.setTimeLimit(timeLimit);
        return q;
    }
}
