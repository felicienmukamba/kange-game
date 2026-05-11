package com.backend.backend.stream;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Service
public class StreamService {

    @Value("${application.stream.livekit.api-key}")
    private String apiKey;

    @Value("${application.stream.livekit.api-secret}")
    private String apiSecret;

    public String createToken(String room, String identity) {
        Map<String, Object> videoGrant = new HashMap<>();
        videoGrant.put("roomJoin", true);
        videoGrant.put("room", room);
        videoGrant.put("canPublish", true);
        videoGrant.put("canSubscribe", true);

        return Jwts.builder()
                .setIssuer(apiKey)
                .setSubject(identity)
                .setExpiration(new Date(System.currentTimeMillis() + 3600000)) // 1 hour
                .claim("video", videoGrant)
                .signWith(Keys.hmacShaKeyFor(apiSecret.getBytes()), SignatureAlgorithm.HS256)
                .compact();
    }
}
