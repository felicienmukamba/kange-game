package com.backend.backend.social;

import com.backend.backend.core.domain.User;
import com.backend.backend.social.domain.Post;
import com.backend.backend.social.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;

    public Post createPost(User author, String content, String mediaUrl) {
        Post post = Post.builder()
                .author(author)
                .content(content)
                .mediaUrl(mediaUrl)
                .build();
        return postRepository.save(post);
    }

    public List<Post> getFeed() {
        return postRepository.findAllByOrderByCreatedAtDesc();
    }
}
