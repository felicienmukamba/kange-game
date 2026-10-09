package com.backend.backend.stream;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.payment.WalletService;
import com.backend.backend.quest.ActivityService;
import com.backend.backend.quest.domain.ActivityType;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Pattern;

/**
 * Live sessions directory and the interactive layer on top of the video:
 * viewers, reactions, gifts, polls and quizzes started from the live.
 *
 * <p>High-frequency events (reactions, votes) are aggregated and flushed every
 * {@link #FLUSH_INTERVAL} instead of being re-broadcast one by one, so a live with
 * thousands of viewers costs a few messages per second.</p>
 *
 * <p>Broadcasts on {@code /topic/live/<room>}: VIEWERS, REACTIONS, GIFT, POLL, QUIZ, ENDED.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LiveService {

    static final Duration FLUSH_INTERVAL = Duration.ofMillis(500);
    static final Duration HOST_GRACE = Duration.ofSeconds(90);
    private static final int MAX_REACTIONS_PER_SECOND = 10;
    private static final Set<String> REACTIONS = Set.of("❤️", "🔥", "😂", "👏", "😮", "🎉", "💯", "👑");
    private static final Pattern QUIZ_TOPIC = Pattern.compile("^[a-z]{2,20}$");

    public record LiveView(String room, String host, String hostAvatar, String title, String category,
                           int viewers, Instant startedAt, String quizRoomId, PollView poll) {}

    public record PollView(String id, String question, List<String> options, List<Integer> votes, boolean open) {}

    public record StartLive(String title, String category) {}

    static final class Live {
        final String room;
        final String host;
        final String hostAvatar;
        final String title;
        final String category;
        final Instant startedAt = Instant.now();
        final Set<String> viewers = ConcurrentHashMap.newKeySet();
        final Map<String, AtomicInteger> pendingReactions = new ConcurrentHashMap<>();
        final Map<String, long[]> rate = new ConcurrentHashMap<>();
        volatile Instant hostGoneSince;
        volatile String quizRoomId;
        volatile Poll poll;
        volatile boolean viewersDirty;
        int quizCounter;

        Live(String room, String host, String hostAvatar, String title, String category) {
            this.room = room;
            this.host = host;
            this.hostAvatar = hostAvatar;
            this.title = title;
            this.category = category;
        }

        LiveView view() {
            Poll p = poll;
            return new LiveView(room, host, hostAvatar, title, category, viewers.size(), startedAt, quizRoomId,
                    p == null ? null : p.view());
        }
    }

    static final class Poll {
        final String id = UUID.randomUUID().toString();
        final String question;
        final List<String> options;
        final Map<String, Integer> votes = new ConcurrentHashMap<>();
        volatile boolean open = true;
        volatile boolean dirty;

        Poll(String question, List<String> options) {
            this.question = question;
            this.options = options;
        }

        PollView view() {
            int[] counts = new int[options.size()];
            votes.values().forEach(v -> counts[v]++);
            return new PollView(id, question, options, Arrays.stream(counts).boxed().toList(), open);
        }
    }

    private final Map<String, Live> lives = new ConcurrentHashMap<>();
    private final SimpMessagingTemplate messaging;
    private final TaskScheduler taskScheduler;
    private final UserRepository userRepository;
    private final WalletService walletService;
    private final ActivityService activityService;
    private ScheduledFuture<?> flushTask;

    @PostConstruct
    void startFlushing() {
        flushTask = taskScheduler.scheduleAtFixedRate(this::flush, FLUSH_INTERVAL);
    }

    @PreDestroy
    void stopFlushing() {
        if (flushTask != null) flushTask.cancel(false);
    }

    public List<LiveView> list() {
        return lives.values().stream()
                .map(Live::view)
                .sorted(Comparator.comparingInt(LiveView::viewers).reversed())
                .toList();
    }

    public Optional<LiveView> find(String room) {
        return Optional.ofNullable(lives.get(room)).map(Live::view);
    }

    public LiveView start(User host, StartLive request) {
        String title = request == null || request.title() == null || request.title().isBlank()
                ? "Live de " + host.getUsername()
                : request.title().trim();
        if (title.length() > 80) title = title.substring(0, 80);
        String category = request == null || request.category() == null ? "Jeux" : request.category().trim();
        String room = "live-" + host.getUsername();
        Live live = new Live(room, host.getUsername(), host.getAvatar(), title, category);
        Live previous = lives.put(room, live);
        if (previous != null) live.viewers.addAll(previous.viewers);
        return live.view();
    }

    public void end(String username) {
        Live live = lives.remove("live-" + username);
        if (live != null) broadcast(live.room, Map.of("type", "ENDED"));
    }

    public void join(String room, String user) {
        Live live = lives.get(room);
        if (live == null) {
            messaging.convertAndSendToUser(user, "/queue/live", Map.of("type", "ENDED", "room", room));
            return;
        }
        if (user.equals(live.host)) {
            live.hostGoneSince = null;
        } else if (live.viewers.add(user)) {
            live.viewersDirty = true;
            activityService.record(user, ActivityType.LIVE_WATCHED);
        }
        messaging.convertAndSendToUser(user, "/queue/live", Map.of("type", "STATE", "live", live.view()));
    }

    public void leave(String room, String user) {
        Live live = lives.get(room);
        if (live != null && live.viewers.remove(user)) live.viewersDirty = true;
    }

    /** On disconnect: viewers leave; a host gets a grace period to reconnect before the live ends. */
    public void disconnected(String user) {
        lives.values().forEach(live -> {
            if (live.viewers.remove(user)) live.viewersDirty = true;
            if (user.equals(live.host)) live.hostGoneSince = Instant.now();
        });
    }

    public void react(String room, String user, String emoji) {
        Live live = lives.get(room);
        if (live == null || emoji == null || !REACTIONS.contains(emoji) || !allow(live, user)) return;
        live.pendingReactions.computeIfAbsent(emoji, e -> new AtomicInteger()).incrementAndGet();
    }

    public void openPoll(String room, String user, String question, List<String> options) {
        Live live = hostedBy(room, user);
        if (live == null) return;
        if (question == null || question.isBlank() || options == null) return;
        List<String> clean = options.stream().filter(o -> o != null && !o.isBlank())
                .map(o -> o.trim().length() > 40 ? o.trim().substring(0, 40) : o.trim())
                .limit(4).toList();
        if (clean.size() < 2) return;
        String q = question.trim().length() > 120 ? question.trim().substring(0, 120) : question.trim();
        live.poll = new Poll(q, clean);
        broadcast(room, Map.of("type", "POLL", "poll", live.poll.view()));
    }

    public void vote(String room, String user, int option) {
        Live live = lives.get(room);
        Poll poll = live == null ? null : live.poll;
        if (poll == null || !poll.open || option < 0 || option >= poll.options.size()) return;
        if (poll.votes.putIfAbsent(user, option) == null) poll.dirty = true;
    }

    public void closePoll(String room, String user) {
        Live live = hostedBy(room, user);
        if (live == null || live.poll == null) return;
        live.poll.open = false;
        broadcast(room, Map.of("type", "POLL", "poll", live.poll.view()));
    }

    /** Opens a quiz room tied to this live; viewers join it with the regular quiz protocol. */
    public void startQuiz(String room, String user, String topic) {
        Live live = hostedBy(room, user);
        if (live == null) return;
        String t = topic != null && QUIZ_TOPIC.matcher(topic).matches() ? topic : "culture";
        synchronized (live) {
            live.quizRoomId = t + "-live-" + live.host + "-" + (++live.quizCounter);
        }
        broadcast(room, Map.of("type", "QUIZ", "roomId", live.quizRoomId));
    }

    @Transactional
    public Map<String, Object> gift(String room, String sender, long amount, String emoji) {
        Live live = lives.get(room);
        if (live == null) throw ApiException.notFound("Ce live est terminé");
        if (live.host.equals(sender)) throw ApiException.badRequest("Tu ne peux pas t'envoyer un cadeau");
        if (amount < 1 || amount > 10_000) throw ApiException.badRequest("Montant invalide (1 à 10 000 coins)");
        User from = walletService.processTransaction(sender, -amount, "GIFT_SENT");
        walletService.processTransaction(live.host, amount, "GIFT_RECEIVED");
        activityService.record(sender, ActivityType.GIFT_SENT);
        String icon = emoji == null || emoji.isBlank() || emoji.length() > 8 ? "🎁" : emoji;
        broadcast(room, Map.of("type", "GIFT", "from", sender, "amount", amount, "emoji", icon));
        return Map.of("coins", from.getCoins());
    }

    private Live hostedBy(String room, String user) {
        Live live = lives.get(room);
        if (live == null || !live.host.equals(user)) return null;
        return live;
    }

    private static boolean allow(Live live, String user) {
        long now = System.currentTimeMillis();
        long[] w = live.rate.computeIfAbsent(user, u -> new long[]{now, 0});
        synchronized (w) {
            if (now - w[0] >= 1_000) {
                w[0] = now;
                w[1] = 0;
            }
            return ++w[1] <= MAX_REACTIONS_PER_SECOND;
        }
    }

    void flush() {
        Instant now = Instant.now();
        for (Live live : lives.values()) {
            try {
                if (live.hostGoneSince != null && live.hostGoneSince.plus(HOST_GRACE).isBefore(now)) {
                    lives.remove(live.room, live);
                    broadcast(live.room, Map.of("type", "ENDED"));
                    continue;
                }
                if (!live.pendingReactions.isEmpty()) {
                    Map<String, Integer> counts = new HashMap<>();
                    live.pendingReactions.forEach((emoji, n) -> {
                        int c = n.getAndSet(0);
                        if (c > 0) counts.put(emoji, c);
                    });
                    live.pendingReactions.values().removeIf(n -> n.get() == 0);
                    if (!counts.isEmpty()) broadcast(live.room, Map.of("type", "REACTIONS", "counts", counts));
                }
                if (live.viewersDirty) {
                    live.viewersDirty = false;
                    broadcast(live.room, Map.of("type", "VIEWERS", "count", live.viewers.size()));
                }
                Poll poll = live.poll;
                if (poll != null && poll.dirty) {
                    poll.dirty = false;
                    broadcast(live.room, Map.of("type", "POLL", "poll", poll.view()));
                }
            } catch (Exception ex) {
                log.warn("Live flush failed for {}: {}", live.room, ex.getMessage());
            }
        }
    }

    private void broadcast(String room, Object payload) {
        messaging.convertAndSend("/topic/live/" + room, payload);
    }

    /** Raised when a non-broadcaster tries to go live. */
    static ApiException forbidden() {
        return new ApiException(HttpStatus.FORBIDDEN, "Seuls les streamers et créateurs peuvent lancer un live");
    }
}
