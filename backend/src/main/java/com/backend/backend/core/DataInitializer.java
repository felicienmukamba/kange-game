package com.backend.backend.core;

import com.backend.backend.core.domain.Role;
import com.backend.backend.core.domain.User;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.payment.domain.Transaction;
import com.backend.backend.payment.repository.TransactionRepository;
import com.backend.backend.social.domain.Post;
import com.backend.backend.social.repository.PostRepository;
import com.backend.backend.tournament.domain.Tournament;
import com.backend.backend.tournament.repository.TournamentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PostRepository postRepository;
    private final TournamentRepository tournamentRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            log.info("Data already seeded. Skipping...");
            return;
        }

        log.info("Starting data seeding...");

        // 1. Seed Users
        User admin = User.builder()
                .username("admin")
                .email("admin@rewify.com")
                .password(passwordEncoder.encode("admin123"))
                .role(Role.ADMIN)
                .level(100)
                .xp(99999L)
                .coins(1000000L)
                .build();

        User gamer = User.builder()
                .username("gamer_pro")
                .email("gamer@rewify.com")
                .password(passwordEncoder.encode("gamer123"))
                .role(Role.PLAYER)
                .level(25)
                .xp(25000L)
                .coins(5000L)
                .build();

        User streamer = User.builder()
                .username("stream_queen")
                .email("stream@rewify.com")
                .password(passwordEncoder.encode("stream123"))
                .role(Role.STREAMER)
                .level(50)
                .xp(50000L)
                .coins(20000L)
                .build();

        userRepository.saveAll(List.of(admin, gamer, streamer));

        // 2. Seed Posts
        Post post1 = Post.builder()
                .author(streamer)
                .content("Live in 5 minutes for the ultimate trivia battle! 🎮 #rewify #gaming")
                .likes(150)
                .build();

        Post post2 = Post.builder()
                .author(gamer)
                .content("Just unlocked the Diamond Shield! Best tournament ever. 💎")
                .likes(45)
                .build();

        postRepository.saveAll(List.of(post1, post2));

        // 3. Seed Tournaments
        Tournament t1 = Tournament.builder()
                .title("Global Logic Challenge")
                .type("SINGLE_ELIMINATION")
                .status("UPCOMING")
                .prizePool(50000)
                .startsAt(LocalDateTime.now().plusDays(2))
                .participants(Set.of(gamer, streamer))
                .build();

        Tournament t2 = Tournament.builder()
                .title("Speed Quiz Championship")
                .type("LEAGUE")
                .status("ONGOING")
                .prizePool(100000)
                .startsAt(LocalDateTime.now().minusHours(5))
                .participants(Set.of(gamer))
                .build();

        tournamentRepository.saveAll(List.of(t1, t2));

        // 4. Seed Transactions
        Transaction tx1 = Transaction.builder()
                .user(gamer)
                .amount(500L)
                .type("DEBIT")
                .status("COMPLETED")
                .build();

        Transaction tx2 = Transaction.builder()
                .user(streamer)
                .amount(1000L)
                .type("CREDIT")
                .status("COMPLETED")
                .build();

        transactionRepository.saveAll(List.of(tx1, tx2));

        log.info("Data seeding completed successfully!");
    }
}
