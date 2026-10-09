package com.backend.backend.websocket;

import com.backend.backend.game.GameSessionService;
import com.backend.backend.room.RoomService;
import com.backend.backend.stream.LiveService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

/** Frees seats and presence when a client's WebSocket closes (app killed, network lost...). */
@Component
@RequiredArgsConstructor
public class SessionDisconnectListener {

    private final RoomService roomService;
    private final GameSessionService gameSessionService;
    private final LiveService liveService;

    @EventListener
    public void onDisconnect(SessionDisconnectEvent event) {
        if (event.getUser() == null) return;
        String user = event.getUser().getName();
        roomService.leaveAll(user);
        gameSessionService.leaveAll(user);
        liveService.disconnected(user);
    }
}
