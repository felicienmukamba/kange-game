package com.backend.backend.ai;

import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;

/**
 * Moderates user-generated text. Uses the configured LLM when available and
 * falls back to a local blocklist otherwise (or if the model call fails).
 */
@Service
@Slf4j
public class AIModerationService {

    private static final List<String> BLOCKLIST = List.of(
            "kill yourself", "kys", "nigger", "faggot", "retard"
    );

    private final ChatClient chatClient;

    public AIModerationService(ObjectProvider<ChatModel> chatModel) {
        ChatModel model = chatModel.getIfAvailable();
        this.chatClient = model != null ? ChatClient.create(model) : null;
    }

    public boolean isContentSafe(String content) {
        if (content == null || content.isBlank()) return true;
        if (!passesBlocklist(content)) return false;
        if (chatClient == null) return true;

        try {
            String response = chatClient.prompt()
                    .system("You are a content moderator for a gaming community. " +
                            "Reply ONLY with 'SAFE' or 'UNSAFE'. Mark as UNSAFE only hate speech, harassment, threats, sexual content or spam.")
                    .user(content)
                    .call()
                    .content();
            return response == null || !response.trim().toUpperCase(Locale.ROOT).startsWith("UNSAFE");
        } catch (Exception ex) {
            log.warn("AI moderation unavailable, falling back to blocklist: {}", ex.getMessage());
            return true;
        }
    }

    private boolean passesBlocklist(String content) {
        String lower = content.toLowerCase(Locale.ROOT);
        return BLOCKLIST.stream().noneMatch(lower::contains);
    }
}
