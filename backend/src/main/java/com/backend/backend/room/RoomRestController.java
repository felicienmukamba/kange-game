package com.backend.backend.room;

import com.backend.backend.core.exception.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/rooms")
@RequiredArgsConstructor
public class RoomRestController {

    private final RoomService roomService;

    public record QuickMatchRequest(String gameId) {}

    /** Waiting rooms with free seats, optionally for a single game. */
    @GetMapping
    public ResponseEntity<List<RoomService.RoomView>> open(@RequestParam(required = false) String gameId) {
        return ResponseEntity.ok(roomService.openRooms(gameId));
    }

    @PostMapping("/quick-match")
    public ResponseEntity<Map<String, String>> quickMatch(@RequestBody QuickMatchRequest request, Authentication auth) {
        try {
            return ResponseEntity.ok(Map.of("roomId", roomService.quickMatch(request.gameId(), auth.getName())));
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest(ex.getMessage());
        }
    }
}
