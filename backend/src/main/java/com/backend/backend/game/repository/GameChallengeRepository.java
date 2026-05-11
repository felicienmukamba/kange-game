package com.backend.backend.game.repository;

import com.backend.backend.game.model.GameChallenge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GameChallengeRepository extends JpaRepository<GameChallenge, Long> {
    List<GameChallenge> findByCreator(String creator);
}
