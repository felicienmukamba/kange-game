package com.backend.backend.ai;

import com.backend.backend.game.model.QuizQuestion;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AIChallengeGenerator {

    private final ChatClient chatClient;

    public List<QuizQuestion> generateQuiz(String topic, int count) {
        String prompt = String.format(
            "Generate a JSON list of %d quiz questions about %s. " +
            "Each question should have a 'question' string, an 'options' array of 4 strings, " +
            "and a 'correctAnswerIndex' integer (0-3).",
            count, topic
        );

        // This is a simplified version. In a real app, we'd use Structured Output.
        String response = chatClient.prompt(prompt).call().content();
        
        // For the sake of the MVP and potential lack of API keys, we'll return mock data
        // but the above code shows the actual implementation.
        return generateMockQuestions(topic, count);
    }

    private List<QuizQuestion> generateMockQuestions(String topic, int count) {
        List<QuizQuestion> questions = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            QuizQuestion q = new QuizQuestion();
            q.setId(String.valueOf(System.currentTimeMillis() + i));
            q.setQuestion("AI Generated Question about " + topic + " #" + (i + 1) + "?");
            q.setOptions(new String[]{"Option A", "Option B", "Option C", "Option D"});
            q.setCorrectAnswerIndex(0);
            q.setTimeLimit(15);
            questions.add(q);
        }
        return questions;
    }
}
