package com.backend.backend.stream;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.List;

/** Real-time interactions of a live: presence, reactions, polls and quizzes. */
@Controller
@RequiredArgsConstructor
public class LiveController {

    private final LiveService liveService;

    public record ReactPayload(String emoji) {}

    public record PollPayload(String question, List<String> options) {}

    public record VotePayload(int option) {}

    public record QuizPayload(String topic) {}

    @MessageMapping("/live/{room}/join")
    public void join(@DestinationVariable String room, Principal principal) {
        liveService.join(room, principal.getName());
    }

    @MessageMapping("/live/{room}/leave")
    public void leave(@DestinationVariable String room, Principal principal) {
        liveService.leave(room, principal.getName());
    }

    @MessageMapping("/live/{room}/react")
    public void react(@DestinationVariable String room, @Payload ReactPayload payload, Principal principal) {
        liveService.react(room, principal.getName(), payload.emoji());
    }

    @MessageMapping("/live/{room}/poll")
    public void poll(@DestinationVariable String room, @Payload PollPayload payload, Principal principal) {
        liveService.openPoll(room, principal.getName(), payload.question(), payload.options());
    }

    @MessageMapping("/live/{room}/poll/close")
    public void closePoll(@DestinationVariable String room, Principal principal) {
        liveService.closePoll(room, principal.getName());
    }

    @MessageMapping("/live/{room}/vote")
    public void vote(@DestinationVariable String room, @Payload VotePayload payload, Principal principal) {
        liveService.vote(room, principal.getName(), payload.option());
    }

    @MessageMapping("/live/{room}/quiz")
    public void quiz(@DestinationVariable String room, @Payload QuizPayload payload, Principal principal) {
        liveService.startQuiz(room, principal.getName(), payload.topic());
    }
}
