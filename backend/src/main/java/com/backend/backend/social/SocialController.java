package com.backend.backend.social;

import com.backend.backend.core.domain.User;
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
    public ResponseEntity<PostService.PostView> createPost(
            @AuthenticationPrincipal User user,
            @RequestBody PostRequest request
    ) {
        return ResponseEntity.ok(postService.createPost(user, request.content(), request.mediaUrl()));
    }

    @GetMapping("/feed")
    public ResponseEntity<List<PostService.PostView>> getFeed(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(postService.getFeed(user.getId()));
    }

    @PostMapping("/posts/{id}/like")
    public ResponseEntity<PostService.PostView> toggleLike(
            @PathVariable Long id,
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.ok(postService.toggleLike(id, user.getId()));
    }

    @DeleteMapping("/posts/{id}")
    public ResponseEntity<Void> deletePost(
            @PathVariable Long id,
            @AuthenticationPrincipal User user
    ) {
        postService.deletePost(id, user);
        return ResponseEntity.noContent().build();
    }

    public record PostRequest(String content, String mediaUrl) {}
}
