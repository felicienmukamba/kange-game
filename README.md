# REWIFY — Social + Gaming + Live

REWIFY combines a social feed, real-time multiplayer quiz games and optional live video streaming,
with an XP / coins economy and a marketplace.

## Features

- **Auth** — JWT sign-up / sign-in with validation. Players choose Player, Streamer or Creator at sign-up (Admin / Moderator can't be self-assigned).
- **Live quiz rooms** — synchronized multiplayer games over STOMP/WebSockets: lobby, server-timed questions, speed bonus, answer reveal, final ranking. Answers never reach the client before the reveal and each player gets one answer per question.
  - Public arenas (`trivia`, `math`, `words`, `gaming`), private rooms with invite links, and community challenges.
- **Creator Studio** — build a challenge from AI-generated questions (OpenAI, optional) or the built-in question bank. The prize pool is escrowed from the creator and paid to the first winner.
- **Rewards** — 10 XP and 1 coin per point, plus 50 coins per win. 1,000 XP per level.
- **Leaderboard** — global ranking by XP.
- **Social feed** — posts, likes, author/moderator deletion, moderation (AI when enabled, blocklist otherwise).
- **Marketplace** — buy cosmetic items with coins; inventory; no overdrafts.
- **Tournaments** — list and register.
- **Live video** (optional) — LiveKit rooms; Streamers / Creators can publish.

## Project structure

- `frontend/` — Next.js 16, React 19, Tailwind 4, Framer Motion, Zustand, STOMP over SockJS.
- `backend/` — Spring Boot 4, Java 21, Spring Security (JWT), Spring Data JPA, WebSocket/STOMP, Spring AI (OpenAI, optional).
- `k8s/` — Kubernetes manifests. `docker-compose.yml` — full local stack.

## Getting started

### Backend

```bash
cd backend
./gradlew bootRun
```

- API: `http://localhost:8080/api/v1`, Swagger UI: `http://localhost:8080/swagger-ui.html`
- With no configuration it uses an in-memory H2 database and seeds demo data.
- Port 8080 taken? Run with `SERVER_PORT=8081 ./gradlew bootRun` and point the frontend at it (below).

Demo accounts: `admin` / `admin123`, `gamer_pro` / `gamer123`, `stream_queen` / `stream123`.

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The app runs at `http://localhost:3000`. If the API isn't at `localhost:8080`, copy `frontend/.env.example` to `.env.local` and set `NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_WS_URL`.

### Docker Compose (PostgreSQL + API + web)

```bash
cp .env.example .env   # then edit secrets
docker compose up --build
```

`NEXT_PUBLIC_*` values are baked into the frontend image at **build** time, so set `PUBLIC_API_URL` / `PUBLIC_WS_URL` in `.env` before building.

## Configuration (backend)

| Variable | Default | Purpose |
|---|---|---|
| `SPRING_DATASOURCE_URL` / `_USERNAME` / `_PASSWORD` | in-memory H2 | Database (PostgreSQL in compose/k8s) |
| `JWT_SECRET` | dev key | Base64 256-bit signing key — **override in production** |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:3000` | Comma-separated web origins |
| `SPRING_AI_MODEL_CHAT`, `OPENAI_API_KEY`, `OPENAI_MODEL` | `none` | Set `openai` + key to enable AI questions & moderation |
| `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` | empty | Live video (secret ≥ 32 chars) |
| `KAFKA_ENABLED`, `SPRING_KAFKA_BOOTSTRAP_SERVERS` | `false` | Analytics / notification events over Kafka |
| `spring.mail.*` | unset | Welcome emails (skipped when unset) |

## Tests

```bash
cd backend && ./gradlew test                    # API integration tests
cd frontend && npm run lint && npx tsc --noEmit
```

## Architecture notes

Modular monolith. Game rooms and the STOMP broker are in-memory, so run a **single backend replica** (as configured in `k8s/backend.yaml`). Scaling out would need an external STOMP broker relay (e.g. RabbitMQ) and shared room state.
