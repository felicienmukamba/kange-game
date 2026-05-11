package com.backend.backend.game.engine;

import com.backend.backend.core.domain.User;
import com.backend.backend.game.GameSessionService;
import com.backend.backend.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

@Service
@RequiredArgsConstructor
public class MatchmakingService {

    private final GameSessionService gameSessionService;
    private final NotificationService notificationService;
    private final Map<Long, Queue<User>> tournamentQueues = new ConcurrentHashMap<>();

    public void joinTournamentQueue(Long tournamentId, User user) {
        tournamentQueues.computeIfAbsent(tournamentId, k -> new ConcurrentLinkedQueue<>()).add(user);
        tryMatchTournament(tournamentId);
    }

    private void tryMatchTournament(Long tournamentId) {
        Queue<User> queue = tournamentQueues.get(tournamentId);
        // We need 4 players for a match
        while (queue != null && queue.size() >= 4) {
            List<User> players = new ArrayList<>();
            String sessionId = "tournament-" + tournamentId + "-" + System.currentTimeMillis();
            
            // Create the session first
            gameSessionService.createSession(sessionId);

            for (int i = 0; i < 4; i++) {
                User player = queue.poll();
                players.add(player);
                
                // Notify players to join the specific session
                notificationService.sendPrivateNotification(
                    player.getUsername(), 
                    "Match found! Joining arena...", 
                    "MATCH_FOUND"
                );
            }
            
            // In a real system, we'd send the sessionId to players via WebSocket to trigger client-side redirect
            System.out.println("Tournament Match started: " + sessionId + " for tournament " + tournamentId);
            
            // Auto-start the session after 5 seconds to give users time to connect
            new Timer().schedule(new TimerTask() {
                @Override
                public void run() {
                    gameSessionService.startSession(sessionId);
                }
            }, 5000);
        }
    }
}
