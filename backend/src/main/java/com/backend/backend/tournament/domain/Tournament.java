package com.backend.backend.tournament.domain;

import com.backend.backend.core.domain.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "tournaments")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Tournament {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private String type; // SINGLE_ELIMINATION, LEAGUE

    private String status; // UPCOMING, ONGOING, COMPLETED

    /** Question topic used by the tournament's game room. */
    private String topic;

    private Integer prizePool;

    @Builder.Default
    private Integer maxParticipants = 64;

    @ManyToMany
    @JoinTable(
        name = "tournament_participants",
        joinColumns = @JoinColumn(name = "tournament_id"),
        inverseJoinColumns = @JoinColumn(name = "user_id")
    )
    @Builder.Default
    private Set<User> participants = new HashSet<>();

    private LocalDateTime startsAt;
}
