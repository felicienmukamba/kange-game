package com.backend.backend.stream;

import com.backend.backend.core.domain.Role;
import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.EnumSet;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/stream")
@RequiredArgsConstructor
public class StreamController {

    private static final EnumSet<Role> BROADCASTER_ROLES = EnumSet.of(Role.STREAMER, Role.CREATOR, Role.ADMIN);

    private final StreamService streamService;
    private final LiveService liveService;

    public record GiftRequest(Long amount, String emoji) {}

    @GetMapping("/config")
    public ResponseEntity<Map<String, Object>> getConfig() {
        return ResponseEntity.ok(Map.of(
                "enabled", streamService.isEnabled(),
                "url", streamService.isEnabled() ? streamService.getUrl() : ""
        ));
    }

    @GetMapping("/token")
    public ResponseEntity<Map<String, String>> getToken(
            @RequestParam String room,
            @AuthenticationPrincipal User user
    ) {
        // Only the owner of a live room may publish in it; everyone else watches.
        boolean ownsRoom = room.equals("live-" + user.getUsername());
        boolean canPublish = BROADCASTER_ROLES.contains(user.getRole()) && (ownsRoom || !room.startsWith("live-"));
        String token = streamService.createToken(room, user.getUsername(), canPublish);
        return ResponseEntity.ok(Map.of("token", token, "url", streamService.getUrl()));
    }

    @GetMapping("/live")
    public ResponseEntity<List<LiveService.LiveView>> lives() {
        return ResponseEntity.ok(liveService.list());
    }

    @GetMapping("/live/{room}")
    public ResponseEntity<LiveService.LiveView> live(@PathVariable String room) {
        return ResponseEntity.ok(liveService.find(room).orElseThrow(() -> ApiException.notFound("Ce live est terminé")));
    }

    @PostMapping("/live")
    public ResponseEntity<LiveService.LiveView> goLive(
            @RequestBody(required = false) LiveService.StartLive request,
            @AuthenticationPrincipal User user
    ) {
        if (!BROADCASTER_ROLES.contains(user.getRole())) throw LiveService.forbidden();
        return ResponseEntity.ok(liveService.start(user, request));
    }

    @DeleteMapping("/live")
    public ResponseEntity<Void> endLive(@AuthenticationPrincipal User user) {
        liveService.end(user.getUsername());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/live/{room}/gift")
    public ResponseEntity<Map<String, Object>> gift(
            @PathVariable String room,
            @RequestBody GiftRequest request,
            @AuthenticationPrincipal User user
    ) {
        long amount = request.amount() == null ? 0 : request.amount();
        return ResponseEntity.ok(liveService.gift(room, user.getUsername(), amount, request.emoji()));
    }
}
