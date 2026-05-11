package com.backend.backend.game.engine;

import com.backend.backend.core.domain.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

@Service
@RequiredArgsConstructor
public class MatchmakingService {

    private final Queue<User> waitingQueue = new ConcurrentLinkedQueue<>();

    private final Map<Long, Queue<User>> tournamentQueues = new ConcurrentHashMap<>();

    public void joinTournamentQueue(Long tournamentId, User user) {
        tournamentQueues.computeIfAbsent(tournamentId, k -> new ConcurrentLinkedQueue<>()).add(user);
        tryMatchTournament(tournamentId);
    }

    private void tryMatchTournament(Long tournamentId) {
        Queue<User> queue = tournamentQueues.get(tournamentId);
        while (queue != null && queue.size() >= 4) { // 4 players per match for tournaments
            List<User> players = new ArrayList<>();
            for (int i = 0; i < 4; i++) players.add(queue.poll());
            
            // Start tournament match
            System.out.println("Tournament Match started for ID: " + tournamentId + " with " + players.size() + " players");
        }
    }
}
