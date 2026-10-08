package com.backend.backend.tournament;

import com.backend.backend.core.domain.User;
import com.backend.backend.core.exception.ApiException;
import com.backend.backend.core.repository.UserRepository;
import com.backend.backend.tournament.domain.Tournament;
import com.backend.backend.tournament.repository.TournamentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/tournaments")
@RequiredArgsConstructor
public class TournamentController {

    private final TournamentRepository tournamentRepository;
    private final UserRepository userRepository;

    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<List<TournamentView>> list(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(tournamentRepository.findAll(Sort.by("startsAt")).stream()
                .map(t -> TournamentView.of(t, user.getId()))
                .toList());
    }

    @PostMapping("/{id}/join")
    @Transactional
    public ResponseEntity<TournamentView> join(@PathVariable Long id, @AuthenticationPrincipal User principal) {
        Tournament t = tournamentRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Tournament not found"));
        if ("COMPLETED".equals(t.getStatus())) {
            throw ApiException.badRequest("This tournament has ended");
        }
        boolean already = t.getParticipants().stream().anyMatch(p -> p.getId().equals(principal.getId()));
        if (!already) {
            if (t.getParticipants().size() >= t.getMaxParticipants()) {
                throw ApiException.conflict("This tournament is full");
            }
            t.getParticipants().add(userRepository.getReferenceById(principal.getId()));
            tournamentRepository.save(t);
        }
        return ResponseEntity.ok(TournamentView.of(t, principal.getId()));
    }

    public record TournamentView(
            Long id, String title, String type, String status, String topic,
            int prizePool, int participants, int maxParticipants,
            boolean joined, LocalDateTime startsAt, String roomId
    ) {
        static TournamentView of(Tournament t, Long viewerId) {
            boolean joined = t.getParticipants().stream().anyMatch(p -> p.getId().equals(viewerId));
            String topic = t.getTopic() == null ? "trivia" : t.getTopic();
            return new TournamentView(
                    t.getId(), t.getTitle(), t.getType(), t.getStatus(), topic,
                    t.getPrizePool() == null ? 0 : t.getPrizePool(),
                    t.getParticipants().size(), t.getMaxParticipants() == null ? 0 : t.getMaxParticipants(),
                    joined, t.getStartsAt(), topic + "-tournament-" + t.getId()
            );
        }
    }
}
