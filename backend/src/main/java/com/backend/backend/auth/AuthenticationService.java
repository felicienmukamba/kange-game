package com.backend.backend.auth;

import com.backend.backend.auth.dto.AuthenticationRequest;
import com.backend.backend.auth.dto.AuthenticationResponse;
import com.backend.backend.auth.dto.RegisterRequest;
import com.backend.backend.core.domain.Role;
import com.backend.backend.core.domain.User;
import com.backend.backend.core.dto.UserProfile;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.monitoring.MetricsService;
import com.backend.backend.notification.EmailService;
import com.backend.backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.Locale;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    /** Roles a user may pick at sign-up. MODERATOR / ADMIN are granted by an admin only. */
    private static final Set<Role> SELF_ASSIGNABLE_ROLES = EnumSet.of(Role.PLAYER, Role.STREAMER, Role.CREATOR);
    private static final long STARTER_COINS = 100L;

    private final UserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final MetricsService metricsService;
    private final EmailService emailService;

    @Transactional
    public AuthenticationResponse register(RegisterRequest request) {
        String username = request.getUsername().trim();
        String email = request.getEmail().trim().toLowerCase(Locale.ROOT);

        if (repository.existsByUsername(username)) {
            throw ApiException.conflict("Username is already taken");
        }
        if (repository.existsByEmail(email)) {
            throw ApiException.conflict("An account with this email already exists");
        }
        Role role = request.getRole() == null ? Role.PLAYER : request.getRole();
        if (!SELF_ASSIGNABLE_ROLES.contains(role)) {
            throw ApiException.badRequest("Role " + role + " cannot be self-assigned");
        }

        var user = User.builder()
                .username(username)
                .email(email)
                .password(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .coins(STARTER_COINS)
                .build();
        repository.save(user);
        metricsService.incrementUsersRegistered();
        emailService.sendWelcomeEmail(user.getEmail(), user.getUsername());

        return AuthenticationResponse.builder()
                .token(jwtService.generateToken(user))
                .user(UserProfile.of(user))
                .build();
    }

    public AuthenticationResponse authenticate(AuthenticationRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
        );
        var user = repository.findByUsername(request.getUsername())
                .orElseThrow(() -> ApiException.notFound("User not found"));
        return AuthenticationResponse.builder()
                .token(jwtService.generateToken(user))
                .user(UserProfile.of(user))
                .build();
    }
}
