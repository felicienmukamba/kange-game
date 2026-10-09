package com.backend.backend.quest;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.payment.WalletService;
import com.backend.backend.quest.domain.ActivityType;
import com.backend.backend.quest.domain.QuestClaim;
import com.backend.backend.quest.repository.QuestClaimRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/** Daily quests (reset at 00:00 UTC) and the daily login bonus with streak. */
@Service
@RequiredArgsConstructor
public class QuestService {

    static final int MAX_STREAK_BONUS_DAYS = 7;

    public record Quest(String id, String title, String description, String icon,
                        ActivityType activity, int target, int reward) {}

    public static final List<Quest> DAILY_QUESTS = List.of(
            new Quest("play3", "Échauffement", "Joue 3 parties", "🎮", ActivityType.GAME_PLAYED, 3, 50),
            new Quest("play10", "Marathonien", "Joue 10 parties", "🔥", ActivityType.GAME_PLAYED, 10, 150),
            new Quest("win1", "Victoire", "Gagne 1 partie multijoueur", "🏆", ActivityType.GAME_WON, 1, 80),
            new Quest("post1", "Social", "Publie 1 post dans le fil", "💬", ActivityType.POST_CREATED, 1, 30),
            new Quest("live1", "Spectateur", "Regarde un live", "📺", ActivityType.LIVE_WATCHED, 1, 30),
            new Quest("gift1", "Généreux", "Envoie un cadeau à un streamer", "🎁", ActivityType.GIFT_SENT, 1, 40)
    );

    public record QuestView(String id, String title, String description, String icon,
                            int target, int progress, int reward, boolean claimed) {}

    public record QuestBoard(LocalDate day, int streak, boolean dailyBonusAvailable, int dailyBonusAmount,
                             List<QuestView> quests, long coins) {}

    private final ActivityService activityService;
    private final QuestClaimRepository claimRepository;
    private final UserRepository userRepository;
    private final WalletService walletService;

    @Transactional(readOnly = true)
    public QuestBoard board(String username) {
        User user = load(username);
        LocalDate today = ActivityService.today();
        Map<ActivityType, Integer> counts = activityService.countsForToday(username);
        Set<String> claimed = claimRepository.findByUsernameAndDay(username, today).stream()
                .map(QuestClaim::getQuestId)
                .collect(Collectors.toSet());

        List<QuestView> quests = DAILY_QUESTS.stream()
                .map(q -> new QuestView(q.id(), q.title(), q.description(), q.icon(), q.target(),
                        Math.min(q.target(), counts.get(q.activity())), q.reward(), claimed.contains(q.id())))
                .toList();

        boolean bonusAvailable = !today.equals(user.getLastDailyBonus());
        return new QuestBoard(today, currentStreak(user, today), bonusAvailable,
                bonusAmount(nextStreak(user, today)), quests, user.getCoins());
    }

    @Transactional
    public QuestBoard claim(String username, String questId) {
        Quest quest = DAILY_QUESTS.stream().filter(q -> q.id().equals(questId)).findFirst()
                .orElseThrow(() -> ApiException.notFound("Unknown quest"));
        LocalDate today = ActivityService.today();
        if (claimRepository.existsByUsernameAndDayAndQuestId(username, today, questId)) {
            throw ApiException.conflict("Quest reward already collected");
        }
        int progress = activityService.countsForToday(username).get(quest.activity());
        if (progress < quest.target()) {
            throw ApiException.badRequest("Quest not completed yet");
        }
        claimRepository.save(QuestClaim.builder().username(username).day(today).questId(questId).build());
        walletService.processTransaction(username, quest.reward(), "QUEST");
        return board(username);
    }

    @Transactional
    public QuestBoard claimDailyBonus(String username) {
        User user = load(username);
        LocalDate today = ActivityService.today();
        if (today.equals(user.getLastDailyBonus())) {
            throw ApiException.conflict("Daily bonus already collected today");
        }
        int streak = nextStreak(user, today);
        user.setDailyStreak(streak);
        user.setLastDailyBonus(today);
        userRepository.save(user);
        walletService.processTransaction(username, bonusAmount(streak), "DAILY_BONUS");
        return board(username);
    }

    static int bonusAmount(int streak) {
        return 20 + 10 * Math.min(Math.max(streak, 1), MAX_STREAK_BONUS_DAYS);
    }

    /** Streak shown today: kept if the bonus was collected today or yesterday, otherwise broken. */
    private static int currentStreak(User user, LocalDate today) {
        LocalDate last = user.getLastDailyBonus();
        int streak = user.getDailyStreak() == null ? 0 : user.getDailyStreak();
        if (last == null) return 0;
        return last.equals(today) || last.equals(today.minusDays(1)) ? streak : 0;
    }

    private static int nextStreak(User user, LocalDate today) {
        LocalDate last = user.getLastDailyBonus();
        int streak = user.getDailyStreak() == null ? 0 : user.getDailyStreak();
        if (last != null && last.equals(today)) return streak;
        return last != null && last.equals(today.minusDays(1)) ? streak + 1 : 1;
    }

    private User load(String username) {
        return userRepository.findByUsername(username).orElseThrow(() -> ApiException.notFound("User not found"));
    }
}
