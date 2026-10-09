package com.backend.backend.room;

import com.backend.backend.quest.ActivityService;
import com.backend.backend.reward.RewardService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class RoomServiceTest {

    private SimpMessagingTemplate messaging;
    private RewardService rewards;
    private RoomService rooms;

    @BeforeEach
    void setUp() {
        messaging = mock(SimpMessagingTemplate.class);
        rewards = mock(RewardService.class);
        rooms = new RoomService(messaging, rewards, mock(ActivityService.class));
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> broadcasts(String roomId) {
        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(messaging, atLeastOnce()).convertAndSend(eq("/topic/room/" + roomId), captor.capture());
        return captor.getAllValues().stream().map(o -> (Map<String, Object>) o).toList();
    }

    @Test
    void firstJoinerHostsAndOnlyHostStarts() {
        rooms.join("r1", "alice", "c07-09", 2);
        rooms.join("r1", "bob", "c07-09", 2);

        rooms.start("r1", "bob");
        verify(messaging).convertAndSendToUser(eq("bob"), eq("/queue/room"),
                argThat(p -> "ERROR".equals(((Map<?, ?>) p).get("type"))));
        assertThat(rooms.find("r1")).get().extracting(RoomService.RoomView::status).isEqualTo("LOBBY");

        rooms.start("r1", "alice");
        RoomService.RoomView view = rooms.find("r1").orElseThrow();
        assertThat(view.status()).isEqualTo("PLAYING");
        assertThat(view.players()).containsExactly("alice", "bob");
        assertThat(view.seed()).isPositive();
    }

    @Test
    void roomIsCappedWhileWaiting() {
        rooms.join("r2", "alice", "g", 2);
        rooms.join("r2", "bob", "g", 2);
        rooms.join("r2", "carol", "g", 2);
        assertThat(rooms.find("r2").orElseThrow().members()).containsExactly("alice", "bob");
    }

    @Test
    void actionsAreSequencedAndStampedWithTheRealSender() {
        rooms.join("r3", "alice", "g", 4);
        rooms.join("r3", "bob", "g", 4);
        rooms.start("r3", "alice");
        rooms.action("r3", "bob", "move", Map.of("cell", 4));
        rooms.action("r3", "alice", "move", Map.of("cell", 0));
        rooms.action("r3", "alice", "_left", Map.of()); // reserved types are rejected

        List<RoomService.Action> actions = broadcasts("r3").stream()
                .filter(p -> "ACTION".equals(p.get("type")))
                .map(p -> (RoomService.Action) p.get("action"))
                .toList();
        assertThat(actions).extracting(RoomService.Action::seq).containsExactly(1L, 2L);
        assertThat(actions).extracting(RoomService.Action::sender).containsExactly("bob", "alice");
    }

    @Test
    void floodingIsRateLimited() {
        rooms.join("r4", "alice", "g", 2);
        rooms.start("r4", "alice");
        for (int i = 0; i < 100; i++) rooms.action("r4", "alice", "tap", Map.of());
        long sent = broadcasts("r4").stream().filter(p -> "ACTION".equals(p.get("type"))).count();
        assertThat(sent).isEqualTo(RoomService.MAX_ACTIONS_PER_SECOND);
    }

    @Test
    void hostLeavingHandsOverAndLogsALeaveForTheRules() {
        rooms.join("r5", "alice", "g", 4);
        rooms.join("r5", "bob", "g", 4);
        rooms.start("r5", "alice");
        rooms.leaveAll("alice");

        assertThat(rooms.find("r5").orElseThrow().host()).isEqualTo("bob");
        assertThat(broadcasts("r5").stream()
                .filter(p -> "ACTION".equals(p.get("type")))
                .map(p -> (RoomService.Action) p.get("action")))
                .anySatisfy(a -> {
                    assertThat(a.type()).isEqualTo("_left");
                    assertThat(a.sender()).isEqualTo("alice");
                });
    }

    @Test
    void finishPaysCappedRewardsOnce() {
        rooms.join("r6", "alice", "g", 4);
        rooms.join("r6", "bob", "g", 4);
        rooms.start("r6", "alice");

        rooms.finish("r6", "bob", Map.of("bob", 999)); // not host: ignored
        verifyNoInteractions(rewards);

        rooms.finish("r6", "alice", Map.of("alice", 5_000, "bob", 3));
        verify(rewards).grantGameReward("alice", RoomService.MAX_REWARD_SCORE, true);
        verify(rewards).grantGameReward("bob", 3, false);

        rooms.finish("r6", "alice", Map.of("alice", 1));
        verify(rewards, times(2)).grantGameReward(anyString(), anyInt(), anyBoolean());
        assertThat(rooms.find("r6").orElseThrow().status()).isEqualTo("FINISHED");
    }

    @Test
    void lastMemberLeavingDeletesTheRoom() {
        rooms.join("r7", "alice", "g", 2);
        rooms.leave("r7", "alice");
        assertThat(rooms.find("r7")).isEmpty();
    }
}
