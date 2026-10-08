package com.backend.backend.social;

import com.backend.backend.ai.AIModerationService;
import com.backend.backend.core.domain.Role;
import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.social.domain.Post;
import com.backend.backend.social.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PostService {

    private static final int MAX_LENGTH = 1000;
    private static final int FEED_SIZE = 50;

    private final PostRepository postRepository;
    private final AIModerationService moderationService;

    @Transactional
    public PostView createPost(User author, String content, String mediaUrl) {
        String text = content == null ? "" : content.trim();
        if (text.isEmpty()) throw ApiException.badRequest("Post cannot be empty");
        if (text.length() > MAX_LENGTH) throw ApiException.badRequest("Post is too long (max " + MAX_LENGTH + " characters)");
        if (!moderationService.isContentSafe(text)) {
            throw ApiException.badRequest("This post violates community guidelines");
        }

        Post post = postRepository.save(Post.builder()
                .author(author)
                .content(text)
                .mediaUrl(mediaUrl == null || mediaUrl.isBlank() ? null : mediaUrl.trim())
                .build());
        return PostView.of(post, author.getId());
    }

    @Transactional(readOnly = true)
    public List<PostView> getFeed(Long viewerId) {
        return postRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, FEED_SIZE)).stream()
                .map(p -> PostView.of(p, viewerId))
                .toList();
    }

    @Transactional
    public PostView toggleLike(Long postId, Long userId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> ApiException.notFound("Post not found"));
        if (!post.getLikedBy().remove(userId)) {
            post.getLikedBy().add(userId);
        }
        return PostView.of(postRepository.save(post), userId);
    }

    @Transactional
    public void deletePost(Long postId, User user) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> ApiException.notFound("Post not found"));
        boolean isModerator = user.getRole() == Role.ADMIN || user.getRole() == Role.MODERATOR;
        if (!post.getAuthor().getId().equals(user.getId()) && !isModerator) {
            throw new ApiException(HttpStatus.FORBIDDEN, "You can only delete your own posts");
        }
        postRepository.delete(post);
    }

    public record Author(Long id, String username, String avatar, int level, String role) {}

    public record PostView(
            Long id, Author author, String content, String mediaUrl,
            int likes, boolean likedByMe, LocalDateTime createdAt
    ) {
        static PostView of(Post p, Long viewerId) {
            User a = p.getAuthor();
            return new PostView(
                    p.getId(),
                    new Author(a.getId(), a.getUsername(), a.getAvatar(), a.getLevel(), a.getRole().name()),
                    p.getContent(),
                    p.getMediaUrl(),
                    p.getLikes() + p.getLikedBy().size(),
                    viewerId != null && p.getLikedBy().contains(viewerId),
                    p.getCreatedAt()
            );
        }
    }
}
