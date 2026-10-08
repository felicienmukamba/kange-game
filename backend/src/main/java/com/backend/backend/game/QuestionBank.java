package com.backend.backend.game;

import com.backend.backend.game.model.QuizQuestion;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Built-in questions used when no AI model is configured, and for the
 * always-available quick-play rooms. Math questions are generated on the fly.
 */
@Component
public class QuestionBank {

    public static final int DEFAULT_TIME_LIMIT = 15;
    private static final int MATH_TIME_LIMIT = 10;

    private record Q(String question, int correct, String... options) {}

    private static final Map<String, List<Q>> BANK = Map.of(
            "trivia", List.of(
                    new Q("What is the capital of France?", 2, "London", "Berlin", "Paris", "Madrid"),
                    new Q("Which planet is known as the Red Planet?", 1, "Venus", "Mars", "Jupiter", "Saturn"),
                    new Q("How many continents are there on Earth?", 3, "5", "6", "8", "7"),
                    new Q("What is the largest ocean on Earth?", 0, "Pacific", "Atlantic", "Indian", "Arctic"),
                    new Q("Which gas do plants absorb from the air?", 1, "Oxygen", "Carbon dioxide", "Nitrogen", "Helium"),
                    new Q("Who painted the Mona Lisa?", 2, "Van Gogh", "Picasso", "Leonardo da Vinci", "Rembrandt"),
                    new Q("What is the longest river in Africa?", 0, "Nile", "Congo", "Niger", "Zambezi"),
                    new Q("How many sides does a hexagon have?", 1, "5", "6", "7", "8"),
                    new Q("What is the hardest natural substance?", 3, "Gold", "Iron", "Quartz", "Diamond"),
                    new Q("Which country is home to the kangaroo?", 0, "Australia", "Brazil", "Kenya", "India"),
                    new Q("What is the chemical symbol for water?", 2, "O2", "HO", "H2O", "CO2"),
                    new Q("Which is the smallest prime number?", 1, "1", "2", "3", "5"),
                    new Q("What is the capital of the DR Congo?", 3, "Lubumbashi", "Goma", "Brazzaville", "Kinshasa"),
                    new Q("Which instrument has 88 keys?", 0, "Piano", "Guitar", "Violin", "Flute"),
                    new Q("What is the fastest land animal?", 2, "Lion", "Horse", "Cheetah", "Gazelle")
            ),
            "gaming", List.of(
                    new Q("Which company created the PlayStation?", 1, "Nintendo", "Sony", "Microsoft", "Sega"),
                    new Q("What is the name of Mario's brother?", 0, "Luigi", "Wario", "Toad", "Yoshi"),
                    new Q("In Minecraft, what material do you need to make a Nether portal?", 3, "Stone", "Iron", "Gold", "Obsidian"),
                    new Q("Which game features the character Master Chief?", 2, "Gears of War", "Destiny", "Halo", "Doom"),
                    new Q("What colour is Sonic the Hedgehog?", 1, "Red", "Blue", "Green", "Yellow"),
                    new Q("Which game popularised the 'battle royale' genre in 2017?", 0, "PUBG", "Tetris", "FIFA", "The Sims"),
                    new Q("In Pac-Man, what do you eat to chase the ghosts?", 2, "Cherries", "Keys", "Power pellets", "Stars"),
                    new Q("Which company makes the Xbox?", 3, "Sony", "Valve", "Nintendo", "Microsoft")
            ),
            "words", List.of(
                    new Q("Which word is a synonym of 'rapid'?", 0, "Fast", "Slow", "Heavy", "Quiet"),
                    new Q("What is the opposite of 'ancient'?", 2, "Old", "Historic", "Modern", "Ruined"),
                    new Q("Which word is spelled correctly?", 1, "Recieve", "Receive", "Receeve", "Receve"),
                    new Q("What is the plural of 'mouse'?", 3, "Mouses", "Meese", "Mousen", "Mice"),
                    new Q("Which word means 'very happy'?", 0, "Elated", "Gloomy", "Weary", "Anxious"),
                    new Q("Which of these is a verb?", 2, "Blue", "Quickly", "Run", "Table"),
                    new Q("What is an antonym of 'generous'?", 1, "Kind", "Stingy", "Giving", "Warm"),
                    new Q("Which word is a noun?", 3, "Beautiful", "Slowly", "Jump", "Happiness")
            )
    );

    public static boolean isMathTopic(String topic) {
        String t = topic == null ? "" : topic.toLowerCase(Locale.ROOT);
        return t.contains("math") || t.contains("speed") || t.contains("arithmetic");
    }

    private static String bankKey(String topic) {
        String t = topic == null ? "" : topic.toLowerCase(Locale.ROOT);
        if (t.contains("game") || t.contains("gaming")) return "gaming";
        if (t.contains("word") || t.contains("vocab") || t.contains("language")) return "words";
        return "trivia";
    }

    public List<QuizQuestion> questionsFor(String topic, int count) {
        if (isMathTopic(topic)) return mathQuestions(count);

        List<Q> pool = new ArrayList<>(BANK.get(bankKey(topic)));
        Collections.shuffle(pool);
        List<QuizQuestion> result = new ArrayList<>();
        for (int i = 0; i < Math.min(count, pool.size()); i++) {
            Q q = pool.get(i);
            result.add(toQuestion(q.question(), q.options(), q.correct(), DEFAULT_TIME_LIMIT));
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
