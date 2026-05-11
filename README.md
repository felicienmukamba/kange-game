# REWIFY - Social + Gaming + Live

REWIFY is a next-generation platform combining Social Networking, Live Streaming, and Interactive Gaming.

## Project Structure

- `frontend/`: Next.js 16+ application with Tailwind 4 and Framer Motion.
- `backend/`: Spring Boot 4 application with Java 25 and Spring AI.

## Features

- **Auth**: Secure JWT authentication.
- **Profiles**: User levels, XP, and coin system.
- **Live Quiz**: Real-time synchronized games using WebSockets.
- **AI Generator**: Dynamic challenge creation using Spring AI.
- **Creator Studio**: Tools for creators to design and publish games.

## Getting Started

### Backend
1. Navigate to `backend/`.
2. Run `./gradlew bootRun`.
3. API available at `http://localhost:8080/api/v1`.

### Frontend
1. Navigate to `frontend/`.
2. Run `npm install` and `npm run dev`.
3. Web app available at `http://localhost:3000`.

## Architecture

Based on the Event-Driven Microservices pattern (initially implemented as a modular monolith for MVP).
- Real-time: STOMP/WebSockets.
- Database: H2 (Dev) / PostgreSQL (Prod).
- Cache: Redis (for Leaderboards).
