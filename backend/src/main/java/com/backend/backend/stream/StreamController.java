package com.backend.backend.stream;

import com.backend.backend.core.domain.Role;
import com.backend.backend.core.domain.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.EnumSet;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/stream")
@RequiredArgsConstructor
public class StreamController {

    private static final EnumSet<Role> BROADCASTER_ROLES = EnumSet.of(Role.STREAMER, Role.CREATOR, Role.ADMIN);

    private final StreamService streamService;

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
        boolean canPublish = BROADCASTER_ROLES.contains(user.getRole());
        String token = streamService.createToken(room, user.getUsername(), canPublish);
        return ResponseEntity.ok(Map.of("token", token, "url", streamService.getUrl()));
    }
}
