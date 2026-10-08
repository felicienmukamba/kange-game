package com.backend.backend.websocket;

import com.backend.backend.security.JwtService;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessageDeliveryException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;

/**
 * Authenticates STOMP sessions using the JWT sent in the CONNECT frame's
 * {@code Authorization: Bearer <token>} header, and rejects SEND frames from
 * unauthenticated sessions.
 */
@Component
@RequiredArgsConstructor
public class StompAuthChannelInterceptor implements ChannelInterceptor {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) return message;

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String header = accessor.getFirstNativeHeader("Authorization");
            if (header != null && header.startsWith("Bearer ")) {
                String token = header.substring(7);
                try {
                    UserDetails user = userDetailsService.loadUserByUsername(jwtService.extractUsername(token));
                    if (jwtService.isTokenValid(token, user)) {
                        accessor.setUser(new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities()));
                    }
                } catch (JwtException | IllegalArgumentException | UsernameNotFoundException ex) {
                    throw new MessageDeliveryException("Invalid authentication token");
                }
            }
        } else if (StompCommand.SEND.equals(accessor.getCommand()) && accessor.getUser() == null) {
            throw new MessageDeliveryException("Authentication required");
        }
        return message;
    }
}
