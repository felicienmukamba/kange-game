package com.backend.backend;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ApiIntegrationTests {

    @Autowired
    private MockMvc mvc;

    private String register(String role) throws Exception {
        String name = "u" + UUID.randomUUID().toString().substring(0, 8);
        String body = """
                {"username":"%s","email":"%s@test.com","password":"secret1"%s}
                """.formatted(name, name, role == null ? "" : ",\"role\":\"" + role + "\"");
        String json = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.coins").value(100))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(json, "$.token");
    }

    private static String bearer(String token) {
        return "Bearer " + token;
    }

    @Test
    void protectedEndpointsRequireAuthentication() throws Exception {
        mvc.perform(get("/api/v1/profile/me")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/profile/me").header("Authorization", "Bearer not-a-jwt")).andExpect(status().isUnauthorized());
    }

    @Test
    void loginWithSeededAccountAndRejectBadPassword() throws Exception {
        mvc.perform(post("/api/v1/auth/authenticate").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"gamer_pro\",\"password\":\"gamer123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.username").value("gamer_pro"))
                .andExpect(jsonPath("$.user.password").doesNotExist());

        mvc.perform(post("/api/v1/auth/authenticate").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"gamer_pro\",\"password\":\"wrong\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void cannotSelfRegisterAsAdmin() throws Exception {
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"sneaky\",\"email\":\"sneaky@test.com\",\"password\":\"secret1\",\"role\":\"ADMIN\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void registrationValidatesInput() throws Exception {
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"a\",\"email\":\"nope\",\"password\":\"1\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.username").exists())
                .andExpect(jsonPath("$.errors.email").exists())
                .andExpect(jsonPath("$.errors.password").exists());
    }

    @Test
    void purchasesDebitCoinsAndCannotOverdraw() throws Exception {
        String token = register(null);
        // Thunder Bolt (95 coins) is affordable with the 100 starter coins
        String items = mvc.perform(get("/api/v1/marketplace/items").header("Authorization", bearer(token)))
                .andReturn().getResponse().getContentAsString();
        List<Integer> cheapIds = JsonPath.read(items, "$[?(@.price == 95)].id");
        List<Integer> priceyIds = JsonPath.read(items, "$[?(@.price == 500)].id");
        Integer cheap = cheapIds.getFirst();
        Integer pricey = priceyIds.getFirst();

        mvc.perform(post("/api/v1/marketplace/purchase/" + cheap).header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.coins").value(5));
        mvc.perform(post("/api/v1/marketplace/purchase/" + cheap).header("Authorization", bearer(token)))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/v1/marketplace/purchase/" + pricey).header("Authorization", bearer(token)))
                .andExpect(status().isPaymentRequired());
        mvc.perform(get("/api/v1/marketplace/inventory").header("Authorization", bearer(token)))
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void postsCanBeLikedAndOnlyDeletedByAuthor() throws Exception {
        String author = register(null);
        String other = register(null);

        String json = mvc.perform(post("/api/v1/social/posts").header("Authorization", bearer(author))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"content\":\"gg everyone\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        Integer postId = JsonPath.read(json, "$.id");

        mvc.perform(post("/api/v1/social/posts/" + postId + "/like").header("Authorization", bearer(other)))
                .andExpect(jsonPath("$.likes").value(1))
                .andExpect(jsonPath("$.likedByMe").value(true));
        mvc.perform(post("/api/v1/social/posts/" + postId + "/like").header("Authorization", bearer(other)))
                .andExpect(jsonPath("$.likes").value(0));

        mvc.perform(delete("/api/v1/social/posts/" + postId).header("Authorization", bearer(other)))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/v1/social/posts/" + postId).header("Authorization", bearer(author)))
                .andExpect(status().isNoContent());
    }

    @Test
    void challengeEscrowsPrizeAndHidesAnswersPublicly() throws Exception {
        String creator = register("CREATOR");

        mvc.perform(post("/api/v1/challenges").header("Authorization", bearer(creator))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Too rich\",\"topic\":\"trivia\",\"prizePool\":1000}"))
                .andExpect(status().isPaymentRequired());

        mvc.perform(post("/api/v1/challenges").header("Authorization", bearer(creator))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Math cup\",\"topic\":\"math\",\"prizePool\":40,\"questionCount\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questions.length()").value(3));

        mvc.perform(get("/api/v1/profile/me").header("Authorization", bearer(creator)))
                .andExpect(jsonPath("$.coins").value(60));

        mvc.perform(get("/api/v1/challenges").header("Authorization", bearer(creator)))
                .andExpect(jsonPath("$[0].questions").doesNotExist())
                .andExpect(jsonPath("$[*].title", hasItem("Math cup")));
    }

    @Test
    void leaderboardNeverExposesPrivateFields() throws Exception {
        String token = register(null);
        mvc.perform(get("/api/v1/leaderboard/global").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].rank").value(1))
                .andExpect(jsonPath("$[0].email").doesNotExist());
    }
}
