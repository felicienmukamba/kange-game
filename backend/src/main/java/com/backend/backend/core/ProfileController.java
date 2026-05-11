package com.backend.backend.core;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public ResponseEntity<User> getMyProfile(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(user);
    }

    @PutMapping("/update")
    public ResponseEntity<User> updateProfile(
            @AuthenticationPrincipal User user,
            @RequestBody ProfileUpdateRequest request
    ) {
        user.setAvatar(request.avatar());
        // Other update logic
        return ResponseEntity.ok(userRepository.save(user));
    }

    public record ProfileUpdateRequest(String avatar) {}
}
