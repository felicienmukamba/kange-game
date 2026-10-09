package com.backend.backend.room;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.Map;

@Controller
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    public record JoinPayload(String gameId, Integer maxPlayers) {}

    public record ActionPayload(String type, Map<String, Object> data) {}

    public record FinishPayload(Map<String, Integer> scores) {}

    @MessageMapping("/room/{roomId}/join")
    public void join(@DestinationVariable String roomId, @Payload(required = false) JoinPayload payload, Principal principal) {
        roomService.join(roomId, principal.getName(),
                payload == null ? null : payload.gameId(),
                payload == null ? null : payload.maxPlayers());
    }

    @MessageMapping("/room/{roomId}/leave")
    public void leave(@DestinationVariable String roomId, Principal principal) {
        roomService.leave(roomId, principal.getName());
    }

    @MessageMapping("/room/{roomId}/start")
    public void start(@DestinationVariable String roomId, Principal principal) {
        roomService.start(roomId, principal.getName());
    }

    @MessageMapping("/room/{roomId}/action")
    public void action(@DestinationVariable String roomId, @Payload ActionPayload payload, Principal principal) {
        roomService.action(roomId, principal.getName(), payload.type(), payload.data());
    }

    @MessageMapping("/room/{roomId}/finish")
    public void finish(@DestinationVariable String roomId, @Payload FinishPayload payload, Principal principal) {
        roomService.finish(roomId, principal.getName(), payload.scores());
    }
}
