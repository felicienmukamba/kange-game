package com.backend.backend.core;

import com.backend.backend.core.domain.Role;
import com.backend.backend.core.domain.User;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.payment.domain.MarketplaceItem;
import com.backend.backend.payment.domain.Transaction;
import com.backend.backend.payment.repository.MarketplaceItemRepository;
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
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Seeds demo data on an empty database. Demo accounts (password = username + "123"):
 * admin, gamer_pro, stream_queen.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PostRepository postRepository;
    private final TournamentRepository tournamentRepository;
    private final TransactionRepository transactionRepository;
    private final MarketplaceItemRepository marketplaceItemRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) {
        if (marketplaceItemRepository.count() == 0) {
            seedMarketplace();
        }
        if (userRepository.count() > 0) {
            log.info("Data already seeded. Skipping...");
            return;
        }

        log.info("Starting data seeding...");

        User admin = User.builder()
                .username("admin")
                .email("admin@rewify.com")
                .password(passwordEncoder.encode("admin123"))
                .role(Role.ADMIN)
                .avatar("🧙")
                .level(100)
                .xp(99_500L)
                .coins(1_000_000L)
                .build();

        User gamer = User.builder()
                .username("gamer_pro")
                .email("gamer@rewify.com")
                .password(passwordEncoder.encode("gamer123"))
                .role(Role.PLAYER)
                .avatar("🥷")
                .level(26)
                .xp(25_000L)
                .coins(5_000L)
                .gamesPlayed(140)
                .wins(62)
                .build();

        User streamer = User.builder()
                .username("stream_queen")
                .email("stream@rewify.com")
                .password(passwordEncoder.encode("stream123"))
                .role(Role.STREAMER)
                .avatar("🦅")
                .level(51)
                .xp(50_000L)
                .coins(20_000L)
                .gamesPlayed(310)
                .wins(151)
                .build();

        userRepository.saveAll(List.of(admin, gamer, streamer));

        postRepository.saveAll(List.of(
                Post.builder()
                        .author(streamer)
                        .content("Live in 5 minutes for the ultimate trivia battle! 🎮 #rewify #gaming")
                        .mediaUrl("/images/streaming.png")
                        .likes(150)
                        .createdAt(LocalDateTime.now().minusMinutes(20))
                        .build(),
                Post.builder()
                        .author(gamer)
                        .content("Just unlocked the Diamond Crown! Best tournament ever. 💎")
                        .mediaUrl("/images/marketplace.png")
                        .likes(45)
                        .createdAt(LocalDateTime.now().minusHours(2))
                        .build()
        ));

        tournamentRepository.saveAll(List.of(
                Tournament.builder()
                        .title("Global Logic Challenge")
                        .type("SINGLE_ELIMINATION")
                        .status("UPCOMING")
                        .topic("trivia")
                        .prizePool(50_000)
                        .startsAt(LocalDateTime.now().plusDays(2))
                        .participants(new HashSet<>(Set.of(gamer, streamer)))
                        .build(),
                Tournament.builder()
                        .title("Speed Math Championship")
                        .type("LEAGUE")
                        .status("ONGOING")
                        .topic("math")
                        .prizePool(100_000)
                        .startsAt(LocalDateTime.now().minusHours(5))
                        .participants(new HashSet<>(Set.of(gamer)))
                        .build()
        ));

        transactionRepository.saveAll(List.of(
                Transaction.builder().user(gamer).amount(-500L).type("PURCHASE").status("COMPLETED").build(),
                Transaction.builder().user(streamer).amount(1000L).type("CREDIT").status("COMPLETED").build()
        ));

        log.info("Data seeding completed successfully!");
    }

    private void seedMarketplace() {
        marketplaceItemRepository.saveAll(List.of(
                item("Dragon Blade", "A legendary blade forged in dragon fire.", 250, "WEAPON", "LEGENDARY", "⚔️"),
                item("Neon Shield", "Deflects bad vibes and wrong answers.", 120, "SHIELD", "EPIC", "🛡️"),
                item("Diamond Crown", "For the undisputed champion of the arena.", 500, "CROWN", "LEGENDARY", "👑"),
                item("Shadow Cloak", "Move unseen through the leaderboard.", 180, "AVATAR", "RARE", "🥷"),
                item("Phoenix Wings", "Rise again after every defeat.", 320, "EFFECT", "LEGENDARY", "🦅"),
                item("Thunder Bolt", "Strike fast, answer faster.", 95, "WEAPON", "COMMON", "⚡"),
                item("Ice Crystal", "A frosty aura around your profile.", 145, "EFFECT", "RARE", "❄️"),
                item("Gold Avatar", "A shiny golden robot persona.", 200, "AVATAR", "EPIC", "🤖")
        ));
    }

    private static MarketplaceItem item(String name, String description, long price, String type, String rarity, String icon) {
        return MarketplaceItem.builder()
                .name(name)
                .description(description)
                .price(price)
                .type(type)
                .rarity(rarity)
                .icon(icon)
                .build();
    }
}
