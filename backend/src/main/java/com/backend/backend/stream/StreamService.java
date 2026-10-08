package com.backend.backend.stream;

import com.backend.backend.core.exception.ApiException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

/** Issues LiveKit access tokens. Streaming is disabled unless LIVEKIT_URL / API key / secret are set. */
@Service
public class StreamService {

    private static final long TOKEN_TTL_MS = 3_600_000; // 1 hour

    @Value("${application.stream.livekit.url}")
    private String url;

    @Value("${application.stream.livekit.api-key}")
    private String apiKey;

    @Value("${application.stream.livekit.api-secret}")
    private String apiSecret;

    public boolean isEnabled() {
        // HS256 needs a secret of at least 256 bits
        return !url.isBlank() && !apiKey.isBlank() && apiSecret.getBytes(StandardCharsets.UTF_8).length >= 32;
    }

    public String getUrl() {
        return url;
    }

    public String createToken(String room, String identity, boolean canPublish) {
        if (!isEnabled()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "Live video is not configured on this server");
        }
        Map<String, Object> videoGrant = new LinkedHashMap<>();
        videoGrant.put("roomJoin", true);
        videoGrant.put("room", room);
        videoGrant.put("canPublish", canPublish);
        videoGrant.put("canSubscribe", true);
        videoGrant.put("canPublishData", true);

        long now = System.currentTimeMillis();
        return Jwts.builder()
                .issuer(apiKey)
                .subject(identity)
                .claim("name", identity)
                .notBefore(new Date(now))
                .expiration(new Date(now + TOKEN_TTL_MS))
                .claim("video", videoGrant)
                .signWith(Keys.hmacShaKeyFor(apiSecret.getBytes(StandardCharsets.UTF_8)), Jwts.SIG.HS256)
                .compact();
    }
}
