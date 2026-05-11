package com.backend.backend.ai;

import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AIModerationService {

    private final ChatClient chatClient;

    public boolean isContentSafe(String content) {
        String prompt = String.format(
            "Analyze the following content for toxicity, hate speech, or spam: \"%s\". " +
            "Reply ONLY with 'SAFE' or 'UNSAFE'.",
            content
        );

        String response = chatClient.prompt(prompt).call().content();
        return "SAFE".equalsIgnoreCase(response.trim());
    }
}
