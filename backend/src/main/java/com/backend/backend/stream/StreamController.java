package com.backend.backend.stream;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/stream")
@RequiredArgsConstructor
public class StreamController {

    private final StreamService streamService;

    @GetMapping("/token")
    public ResponseEntity<Map<String, String>> getToken(
            @RequestParam String room,
            Authentication authentication
    ) {
        String identity = authentication.getName();
        String token = streamService.createToken(room, identity);
        return ResponseEntity.ok(Map.of("token", token));
    }
}
