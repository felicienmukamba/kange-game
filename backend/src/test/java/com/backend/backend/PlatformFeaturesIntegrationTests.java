package com.backend.backend;

import com.backend.backend.game.QuestionBank;
import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Solo scores, quests, multiplayer rooms, live sessions and public profiles. */
@SpringBootTest
@AutoConfigureMockMvc
class PlatformFeaturesIntegrationTests {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private QuestionBank questionBank;

    private record Account(String name, String token) {
        String bearer() {
            return "Bearer " + token;
        }
    }

    private Account register(String role) throws Exception {
        String name = "u" + UUID.randomUUID().toString().substring(0, 8);
        String body = """
                {"username":"%s","email":"%s@test.com","password":"secret1"%s}
                """.formatted(name, name, role == null ? "" : ",\"role\":\"" + role + "\"");
        String json = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return new Account(name, JsonPath.read(json, "$.token"));
    }

    private void submitScore(Account a, String gameId, long score, int rating) throws Exception {
        mvc.perform(post("/api/v1/games/scores").header("Authorization", a.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"gameId\":\"%s\",\"score\":%d,\"rating\":%d,\"durationMs\":30000}".formatted(gameId, score, rating)))
                .andExpect(status().isOk());
    }

    @Test
    void frenchQuestionBankCoversCatalogTopics() {
        assertThat(questionBank.topics()).contains("culture", "football", "manga", "afrique", "drapeaux", "geo");
        var questions = questionBank.questionsFor("football", 5);
        assertThat(questions).hasSize(5).allSatisfy(q -> {
            assertThat(q.getOptions()).hasSize(4);
            assertThat(q.getCorrectAnswerIndex()).isBetween(0, 3);
        });
        // Legacy web topics still resolve
        assertThat(questionBank.questionsFor("trivia", 3)).hasSize(3);
    }

    @Test
    void soloScoresRewardAndRankPlayers() throws Exception {
        Account a = register(null);
        Account b = register(null);
        String game = "c99-" + UUID.randomUUID().toString().substring(0, 4);

        mvc.perform(post("/api/v1/games/scores").header("Authorization", a.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"gameId\":\"%s\",\"score\":120,\"rating\":50,\"durationMs\":30000}".formatted(game)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.newRecord").value(true))
                .andExpect(jsonPath("$.xpGained").value(100))
                .andExpect(jsonPath("$.coinsGained").value(5))
                .andExpect(jsonPath("$.coins").value(105))
                .andExpect(jsonPath("$.rank").value(1));
        submitScore(b, game, 300, 80);

        mvc.perform(get("/api/v1/games/{id}/leaderboard", game).header("Authorization", a.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].username").value(b.name()))
                .andExpect(jsonPath("$[0].score").value(300))
                .andExpect(jsonPath("$[1].username").value(a.name()));

        // Too short to be a real game: recorded, not rewarded
        mvc.perform(post("/api/v1/games/scores").header("Authorization", a.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"gameId\":\"%s\",\"score\":999,\"rating\":100,\"durationMs\":10}".formatted(game)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.xpGained").value(0));

        mvc.perform(get("/api/v1/games/stats/me").header("Authorization", a.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].gameId").value(game))
                .andExpect(jsonPath("$[0].plays").value(2));
    }

    @Test
    void questsTrackActivityAndPayOnce() throws Exception {
        Account a = register(null);

        mvc.perform(get("/api/v1/quests").header("Authorization", a.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dailyBonusAvailable").value(true))
                .andExpect(jsonPath("$.quests[?(@.id=='play3')].progress").value(hasItem(0)));

        mvc.perform(post("/api/v1/quests/play3/claim").header("Authorization", a.bearer()))
                .andExpect(status().isBadRequest());

        for (int i = 0; i < 3; i++) submitScore(a, "c01-01", 10, 0);

        mvc.perform(post("/api/v1/quests/play3/claim").header("Authorization", a.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quests[?(@.id=='play3')].claimed").value(hasItem(true)))
                .andExpect(jsonPath("$.coins").value(150));
        mvc.perform(post("/api/v1/quests/play3/claim").header("Authorization", a.bearer()))
                .andExpect(status().isConflict());

        mvc.perform(post("/api/v1/quests/daily-bonus").header("Authorization", a.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.streak").value(1))
                .andExpect(jsonPath("$.dailyBonusAvailable").value(false))
                .andExpect(jsonPath("$.coins").value(180));
        mvc.perform(post("/api/v1/quests/daily-bonus").header("Authorization", a.bearer()))
                .andExpect(status().isConflict());
    }

    @Test
    void quickMatchReturnsARoomForTheGame() throws Exception {
        Account a = register(null);
        mvc.perform(post("/api/v1/rooms/quick-match").header("Authorization", a.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"gameId\":\"c07-09\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.roomId").value(startsWith("c07-09-")));
        mvc.perform(post("/api/v1/rooms/quick-match").header("Authorization", a.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"gameId\":\"../etc\"}"))
                .andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/rooms").header("Authorization", a.bearer()))
                .andExpect(status().isOk());
    }

    @Test
    void onlyBroadcastersGoLiveAndViewersCanSendGifts() throws Exception {
        Account player = register(null);
        Account streamer = register("STREAMER");

        mvc.perform(post("/api/v1/stream/live").header("Authorization", player.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"title\":\"Nope\"}"))
                .andExpect(status().isForbidden());

        String room = "live-" + streamer.name();
        mvc.perform(post("/api/v1/stream/live").header("Authorization", streamer.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"title\":\"Quiz du soir\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.room").value(room))
                .andExpect(jsonPath("$.title").value("Quiz du soir"));

        mvc.perform(get("/api/v1/stream/live").header("Authorization", player.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].room").value(hasItem(room)));

        mvc.perform(post("/api/v1/stream/live/{room}/gift", room).header("Authorization", player.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":40}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.coins").value(60));
        mvc.perform(post("/api/v1/stream/live/{room}/gift", room).header("Authorization", player.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":500}"))
                .andExpect(status().isPaymentRequired());
        mvc.perform(get("/api/v1/profile/me").header("Authorization", streamer.bearer()))
                .andExpect(jsonPath("$.coins").value(140));

        mvc.perform(delete("/api/v1/stream/live").header("Authorization", streamer.bearer()))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/stream/live/{room}", room).header("Authorization", player.bearer()))
                .andExpect(status().isNotFound());
    }

    @Test
    void publicProfilesHidePrivateFields() throws Exception {
        Account a = register(null);
        mvc.perform(get("/api/v1/users/gamer_pro").header("Authorization", a.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("gamer_pro"))
                .andExpect(jsonPath("$.rank").isNumber())
                .andExpect(jsonPath("$.email").doesNotExist())
                .andExpect(jsonPath("$.coins").doesNotExist());
        mvc.perform(get("/api/v1/users/nobody_here").header("Authorization", a.bearer()))
                .andExpect(status().isNotFound());
    }
}
