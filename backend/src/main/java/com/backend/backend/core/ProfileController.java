package com.backend.backend.core;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.dto.UserProfile;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public ResponseEntity<UserProfile> getMyProfile(@AuthenticationPrincipal User principal) {
        return ResponseEntity.ok(UserProfile.of(reload(principal)));
    }

    @PutMapping("/update")
    @Transactional
    public ResponseEntity<UserProfile> updateProfile(
            @AuthenticationPrincipal User principal,
            @Valid @RequestBody ProfileUpdateRequest request
    ) {
        User user = reload(principal);
        if (request.avatar() != null) user.setAvatar(request.avatar().isBlank() ? null : request.avatar());
        if (request.bio() != null) user.setBio(request.bio().isBlank() ? null : request.bio().trim());
        return ResponseEntity.ok(UserProfile.of(userRepository.save(user)));
    }

    private User reload(User principal) {
        return userRepository.findById(principal.getId())
                .orElseThrow(() -> ApiException.notFound("User not found"));
    }

    public record ProfileUpdateRequest(
            @Size(max = 64) String avatar,
            @Size(max = 280) String bio
    ) {}
}
