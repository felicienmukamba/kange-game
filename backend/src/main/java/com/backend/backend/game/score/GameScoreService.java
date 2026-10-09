package com.backend.backend.game.score;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.quest.ActivityService;
import com.backend.backend.quest.domain.ActivityType;
import com.backend.backend.reward.RewardService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GameScoreService {

    /** Runs per UTC day that still earn XP / coins; later runs are recorded but not rewarded. */
    public static final int DAILY_REWARDED_RUNS = 60;
    /** Runs shorter than this can't be real games and are not rewarded. */
    private static final long MIN_DURATION_MS = 2_000;
    private static final Pattern GAME_ID = Pattern.compile("^[A-Za-z0-9_-]{1,40}$");

    public record SubmitScore(String gameId, Long score, Integer rating, Long durationMs) {}

    public record ScoreResult(long score, long best, boolean newRecord, long xpGained, long coinsGained,
                              long rank, long coins, long xp, int level) {}

    public record ScoreEntry(long rank, String username, String avatar, int level, long score) {}

    public record GameStat(String gameId, long plays, long best) {}

    private final GameScoreRepository repository;
    private final UserRepository userRepository;
    private final RewardService rewardService;
    private final ActivityService activityService;

    @Transactional
    public ScoreResult submit(String username, SubmitScore req) {
        if (req.gameId() == null || !GAME_ID.matcher(req.gameId()).matches()) {
            throw ApiException.badRequest("Invalid game id");
        }
        long score = Math.clamp(req.score() == null ? 0 : req.score(), 0, 100_000_000L);
        int rating = Math.clamp(req.rating() == null ? 0 : req.rating(), 0, 100);
        long duration = Math.max(0, req.durationMs() == null ? 0 : req.durationMs());

        Long previousBest = repository.bestFor(req.gameId(), username);
        long todayRuns = repository.countByUsernameAndCreatedAtAfter(username,
                ActivityService.today().atStartOfDay(ZoneOffset.UTC).toLocalDateTime());

        repository.save(GameScore.builder()
                .username(username).gameId(req.gameId()).score(score).rating(rating).durationMs(duration)
                .build());

        boolean rewarded = todayRuns < DAILY_REWARDED_RUNS && duration >= MIN_DURATION_MS;
        RewardService.Reward reward = rewardService.grantSoloReward(username, rating, rewarded);
        activityService.record(username, ActivityType.GAME_PLAYED);

        long best = previousBest == null ? score : Math.max(previousBest, score);
        User user = userRepository.findByUsername(username).orElseThrow(() -> ApiException.notFound("User not found"));
        return new ScoreResult(score, best, previousBest == null || score > previousBest,
                reward.xp(), reward.coins(), rankOf(req.gameId(), best),
                user.getCoins(), user.getXp(), user.getLevel());
    }

    @Transactional(readOnly = true)
    public List<ScoreEntry> leaderboard(String gameId, int limit) {
        List<GameScoreRepository.BestScore> top = repository.topScores(gameId, PageRequest.of(0, Math.clamp(limit, 1, 100)));
        Map<String, User> users = userRepository.findByUsernameIn(top.stream().map(GameScoreRepository.BestScore::getUsername).toList())
                .stream().collect(Collectors.toMap(User::getUsername, Function.identity()));
        return java.util.stream.IntStream.range(0, top.size())
                .mapToObj(i -> {
                    var s = top.get(i);
                    User u = users.get(s.getUsername());
                    return new ScoreEntry(i + 1, s.getUsername(), u == null ? null : u.getAvatar(),
                            u == null ? 1 : u.getLevel(), s.getBest());
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public List<GameStat> statsFor(String username) {
        return repository.statsFor(username, PageRequest.of(0, 50)).stream()
                .map(s -> new GameStat(s.getGameId(), s.getPlays(), s.getBest()))
                .toList();
    }

    private long rankOf(String gameId, long best) {
        // Players whose best beats ours; small per-game tables make this cheap.
        return repository.topScores(gameId, PageRequest.of(0, 1000)).stream()
                .filter(s -> s.getBest() > best)
                .count() + 1;
    }
}
