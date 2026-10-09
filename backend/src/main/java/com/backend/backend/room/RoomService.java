package com.backend.backend.room;

import com.backend.backend.quest.ActivityService;
import com.backend.backend.quest.domain.ActivityType;
import com.backend.backend.reward.RewardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Pattern;

/**
 * Generic multiplayer rooms for every non-quiz game, using deterministic lockstep.
 *
 * <p>The server does not know the rules of each game. It orders actions (monotonic {@code seq}),
 * stamps the real sender and the server time, hands out a shared random seed at start and keeps
 * the match log so late joiners can replay it. Every client applies the same pure rules to the
 * same ordered actions, so all clients compute the same state.</p>
 *
 * <p>Broadcasts on {@code /topic/room/<id>}: ROOM, START, ACTION, FINISHED.
 * Private messages on {@code /user/queue/room}: SYNC, ERROR.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RoomService {

    public static final int MAX_LOG = 5_000;
    public static final int MAX_ACTIONS_PER_SECOND = 25;
    /** Score is capped so that client-reported results can't mint unlimited XP. */
    public static final int MAX_REWARD_SCORE = 30;

    private static final Pattern ID = Pattern.compile("^[A-Za-z0-9_-]{1,80}$");
    private static final Pattern GAME_ID = Pattern.compile("^[A-Za-z0-9_-]{1,40}$");

    public enum Status { LOBBY, PLAYING, FINISHED }

    public record Action(long seq, String sender, String type, Map<String, Object> data, long serverTime) {}

    public record RoomView(String id, String gameId, String host, String status, List<String> members,
                           List<String> players, int maxPlayers, long seed, int matchId, long serverTime) {}

    static final class Room {
        final String id;
        final String gameId;
        final int maxPlayers;
        final Set<String> members = new LinkedHashSet<>();
        List<String> players = List.of();
        final List<Action> log = new ArrayList<>();
        final Map<String, long[]> rate = new HashMap<>(); // user -> {windowStartMs, count}
        String host;
        Status status = Status.LOBBY;
        long seed;
        long seq;
        int matchId;

        Room(String id, String gameId, int maxPlayers, String host) {
            this.id = id;
            this.gameId = gameId;
            this.maxPlayers = maxPlayers;
            this.host = host;
        }

        RoomView view() {
            return new RoomView(id, gameId, host, status.name(), List.copyOf(members), players,
                    maxPlayers, seed, matchId, System.currentTimeMillis());
        }
    }

    private final Map<String, Room> rooms = new ConcurrentHashMap<>();

    private final SimpMessagingTemplate messaging;
    private final RewardService rewardService;
    private final ActivityService activityService;

    public void join(String roomId, String user, String gameId, Integer maxPlayers) {
        if (!ID.matcher(roomId).matches()) {
            error(user, "Identifiant de salle invalide");
            return;
        }
        String game = gameId != null && GAME_ID.matcher(gameId).matches() ? gameId : roomId.split("-")[0];
        int max = maxPlayers == null ? 8 : Math.clamp(maxPlayers, 1, 100);
        Room room = rooms.computeIfAbsent(roomId, id -> new Room(id, game, max, user));

        Map<String, Object> sync;
        synchronized (room) {
            if (!room.members.contains(user) && room.status == Status.LOBBY && room.members.size() >= room.maxPlayers) {
                error(user, "La salle est pleine");
                return;
            }
            room.members.add(user);
            if (room.host == null) room.host = user;
            sync = Map.of("type", "SYNC", "room", room.view(), "log", List.copyOf(room.log));
        }
        messaging.convertAndSendToUser(user, "/queue/room", sync);
        broadcastRoom(room);
    }

    public void leave(String roomId, String user) {
        Room room = rooms.get(roomId);
        if (room != null) leave(room, user);
    }

    /** Called when a WebSocket session closes. */
    public void leaveAll(String user) {
        rooms.values().forEach(room -> {
            boolean member;
            synchronized (room) {
                member = room.members.contains(user);
            }
            if (member) leave(room, user);
        });
    }

    private void leave(Room room, String user) {
        boolean empty;
        boolean wasPlayer;
        synchronized (room) {
            if (!room.members.remove(user)) return;
            room.rate.remove(user);
            wasPlayer = room.status == Status.PLAYING && room.players.contains(user);
            if (user.equals(room.host)) {
                room.host = room.members.isEmpty() ? null : room.members.iterator().next();
            }
            empty = room.members.isEmpty();
            if (empty) rooms.remove(room.id, room);
        }
        if (empty) return;
        // Let the rules react (forfeit, skip turn...) in the same deterministic order as other actions.
        if (wasPlayer) append(room, user, "_left", Map.of());
        broadcastRoom(room);
    }

    public void start(String roomId, String user) {
        Room room = rooms.get(roomId);
        if (room == null) return;
        Map<String, Object> payload;
        synchronized (room) {
            if (!user.equals(room.host)) {
                error(user, "Seul l'hôte peut lancer la partie");
                return;
            }
            if (room.status == Status.PLAYING) return;
            room.players = room.members.stream().limit(room.maxPlayers).toList();
            room.seed = ThreadLocalRandom.current().nextLong(1, Integer.MAX_VALUE);
            room.log.clear();
            room.seq = 0;
            room.matchId++;
            room.status = Status.PLAYING;
            payload = Map.of("type", "START", "room", room.view());
        }
        broadcast(room.id, payload);
    }

    public void action(String roomId, String user, String type, Map<String, Object> data) {
        Room room = rooms.get(roomId);
        if (room == null || type == null || type.isBlank() || type.startsWith("_") || type.length() > 32) return;
        synchronized (room) {
            if (room.status != Status.PLAYING || !room.members.contains(user)) return;
            if (!allow(room, user)) return;
        }
        append(room, user, type, data == null ? Map.of() : data);
    }

    /**
     * Ends the match. Only the host reports, with the scores its rules computed; every client runs
     * the same rules so the host has no way to report a result the others would not agree with
     * without it showing on their screens. Rewards are capped regardless.
     */
    public void finish(String roomId, String user, Map<String, Integer> scores) {
        Room room = rooms.get(roomId);
        if (room == null) return;
        List<String> players;
        Map<String, Integer> clean = new LinkedHashMap<>();
        synchronized (room) {
            if (!user.equals(room.host) || room.status != Status.PLAYING) return;
            room.status = Status.FINISHED;
            players = room.players;
            for (String p : players) {
                Integer s = scores == null ? null : scores.get(p);
                clean.put(p, s == null ? 0 : Math.clamp(s, 0, 1_000_000));
            }
        }
        int best = clean.values().stream().max(Integer::compare).orElse(0);
        long winners = clean.values().stream().filter(v -> v == best).count();
        String winner = best > 0 && winners == 1
                ? clean.entrySet().stream().filter(e -> e.getValue() == best).map(Map.Entry::getKey).findFirst().orElse(null)
                : null;

        broadcast(room.id, Map.of(
                "type", "FINISHED",
                "scores", clean,
                "winner", winner == null ? "" : winner,
                "room", room.view()
        ));
        broadcastRoom(room);

        clean.forEach((player, score) -> {
            boolean won = player.equals(winner) && players.size() > 1;
            try {
                rewardService.grantGameReward(player, Math.min(score, MAX_REWARD_SCORE), won);
            } catch (Exception ex) {
                log.error("Failed to reward {} in room {}: {}", player, room.id, ex.getMessage());
            }
            activityService.record(player, ActivityType.GAME_PLAYED);
            if (won) activityService.record(player, ActivityType.GAME_WON);
        });
    }

    public List<RoomView> openRooms(String gameId) {
        return rooms.values().stream()
                .map(r -> {
                    synchronized (r) {
                        return r.view();
                    }
                })
                .filter(v -> gameId == null || gameId.equals(v.gameId()))
                .filter(v -> Status.LOBBY.name().equals(v.status()) && v.members().size() < v.maxPlayers())
                .sorted(Comparator.comparingInt((RoomView v) -> v.members().size()).reversed())
                .limit(50)
                .toList();
    }

    /** Returns a waiting room for this game with free seats, or the id of a new one. */
    public String quickMatch(String gameId, String user) {
        if (gameId == null || !GAME_ID.matcher(gameId).matches()) {
            throw new IllegalArgumentException("Invalid game id");
        }
        return openRooms(gameId).stream()
                .filter(v -> !v.members().contains(user))
                .map(RoomView::id)
                .findFirst()
                .orElseGet(() -> gameId + "-" + Long.toString(ThreadLocalRandom.current().nextLong(36L * 36 * 36 * 36 * 36, 36L * 36 * 36 * 36 * 36 * 36), 36));
    }

    Optional<RoomView> find(String roomId) {
        return Optional.ofNullable(rooms.get(roomId)).map(r -> {
            synchronized (r) {
                return r.view();
            }
        });
    }

    private void append(Room room, String sender, String type, Map<String, Object> data) {
        Action action;
        synchronized (room) {
            if (room.log.size() >= MAX_LOG) return;
            action = new Action(++room.seq, sender, type, data, Instant.now().toEpochMilli());
            room.log.add(action);
            // Broadcast while holding the lock so subscribers receive actions in seq order.
            broadcast(room.id, Map.of("type", "ACTION", "action", action));
        }
    }

    private static boolean allow(Room room, String user) {
        long now = System.currentTimeMillis();
        long[] window = room.rate.computeIfAbsent(user, u -> new long[]{now, 0});
        if (now - window[0] >= 1_000) {
            window[0] = now;
            window[1] = 0;
        }
        return ++window[1] <= MAX_ACTIONS_PER_SECOND;
    }

    private void broadcastRoom(Room room) {
        RoomView view;
        synchronized (room) {
            view = room.view();
        }
        broadcast(room.id, Map.of("type", "ROOM", "room", view));
    }

    private void broadcast(String roomId, Object payload) {
        messaging.convertAndSend("/topic/room/" + roomId, payload);
    }

    private void error(String user, String message) {
        messaging.convertAndSendToUser(user, "/queue/room", Map.of("type", "ERROR", "message", message));
    }
}
