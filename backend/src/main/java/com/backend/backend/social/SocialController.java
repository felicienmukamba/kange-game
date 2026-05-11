package com.backend.backend.social;

import com.backend.backend.core.domain.User;
import com.backend.backend.social.domain.Post;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/social")
@RequiredArgsConstructor
public class SocialController {

    private final PostService postService;

    @PostMapping("/posts")
    public ResponseEntity<Post> createPost(
            @AuthenticationPrincipal User user,
            @RequestBody PostRequest request
    ) {
        return ResponseEntity.ok(postService.createPost(user, request.content(), request.mediaUrl()));
    }

    @GetMapping("/feed")
    public ResponseEntity<List<Post>> getFeed() {
        return ResponseEntity.ok(postService.getFeed());
    }

    public record PostRequest(String content, String mediaUrl) {}
}
