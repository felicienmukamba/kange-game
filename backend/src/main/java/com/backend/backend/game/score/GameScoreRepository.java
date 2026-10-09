package com.backend.backend.game.score;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface GameScoreRepository extends JpaRepository<GameScore, Long> {

    interface BestScore {
        String getUsername();
        long getBest();
    }

    interface GameStat {
        String getGameId();
        long getPlays();
        long getBest();
    }

    @Query("""
            select s.username as username, max(s.score) as best
            from GameScore s where s.gameId = :gameId
            group by s.username order by max(s.score) desc
            """)
    List<BestScore> topScores(@Param("gameId") String gameId, Pageable pageable);

    @Query("select max(s.score) from GameScore s where s.gameId = :gameId and s.username = :username")
    Long bestFor(@Param("gameId") String gameId, @Param("username") String username);

    @Query("""
            select s.gameId as gameId, count(s) as plays, max(s.score) as best
            from GameScore s where s.username = :username
            group by s.gameId order by count(s) desc
            """)
    List<GameStat> statsFor(@Param("username") String username, Pageable pageable);

    long countByUsernameAndCreatedAtAfter(String username, LocalDateTime after);

    long countByUsername(String username);
}
