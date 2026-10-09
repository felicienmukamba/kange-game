# REWIFY — Plan de réalisation de l'application mobile (Flutter)

> Objectif : livrer une application Flutter finie (Android, iOS, Web, Windows) qui rend jouables
> les **1000 idées de challenges** du document produit, avec du **multijoueur temps réel** et du
> **live streaming**, sur le backend Spring Boot existant.

---

## 1. L'équipe (rôles assumés)

| Rôle | Responsabilités sur ce projet |
|---|---|
| **Product Owner** | Découpage des 1000 idées en moteurs de jeu, priorisation, critères d'acceptation. |
| **Architecte / Tech Lead** | Clean Architecture, choix BLoC + get_it + go_router, protocole temps réel, revue de code. |
| **Game Designer** | Règles, scoring, durées, difficulté, équilibre des récompenses (XP / coins). |
| **Dev Flutter (UI)** | Design system, écrans, navigation, accessibilité, animations 60 fps. |
| **Dev Flutter (Gameplay)** | ~40 moteurs de jeu (CustomPainter + Ticker, logique pure testable). |
| **Dev Backend (Java)** | Salles multijoueur génériques, scores, quêtes, live (gifts, réactions, sondages). |
| **Ingénieur temps réel** | STOMP natif, reconnexion, horloge serveur, lockstep déterministe, anti-spam. |
| **Ingénieur streaming** | LiveKit (simulcast, dynacast, adaptive stream), overlay jeu + chat + réactions. |
| **Content Designer** | Banques FR : quiz (foot, manga, Afrique, drapeaux…), mots, devinettes, défis. |
| **QA** | Tests unitaires des règles, tests BLoC, tests d'intégration API, analyse statique. |
| **DevOps** | CI GitHub Actions (analyse + tests Flutter), Docker, k8s. |
| **Sécurité** | JWT en stockage sécurisé, sender imposé côté serveur, plafonds de récompenses, rate-limit. |

---

## 2. Architecture

### 2.1 Flutter (`mobile/`) — Clean Architecture « feature-first »

```
lib/
  app/            # App, router (go_router + StatefulShellRoute), injection (get_it)
  core/
    config/       # Env (API / WS / nom de l'app)
    network/      # ApiClient (Dio + intercepteur JWT + mapping d'erreurs)
    realtime/     # RealtimeClient STOMP natif : reconnexion, re-souscription, heartbeats
    error/        # Failure, Result<T>
    theme/        # Design system (couleurs, typo, composants)
    widgets/      # Composants réutilisables
    utils/        # Normalisation de texte, RNG seedé, formatage
  features/
    auth/         # data / domain / presentation (AuthBloc)
    home/         # Accueil : quêtes, lives, jeux en vedette
    catalog/      # Les 1000 challenges : catégories, recherche, filtres
    play/         # Session solo : chrono, score, résultat, récompenses
    games/        # Les moteurs de jeu (1 dossier par moteur, logique pure séparée de l'UI)
    multiplayer/  # Salles génériques (lockstep), quick-match, course au score
    quiz_room/    # Salles quiz serveur (existant backend)
    live/         # Streaming LiveKit + chat + réactions + cadeaux + sondages
    social/       # Fil, likes, publication, partage de résultats
    leaderboard/  # Classements global et par jeu
    marketplace/  # Boutique + inventaire
    tournaments/  # Tournois
    creator/      # Creator Studio (challenges + cagnotte)
    quests/       # Quêtes journalières + bonus quotidien (streak)
    profile/      # Profils, paramètres
```

Chaque feature : `data/` (DTO + repository impl), `domain/` (entités + contrats), `presentation/`
(BLoC/Cubit + pages + widgets). Les BLoC ne dépendent que des contrats du domaine.

### 2.2 Gestion d'état : BLoC

- `flutter_bloc` : **Bloc** pour les flux événementiels (auth, salle multijoueur, live),
  **Cubit** pour les écrans simples (fil, boutique, classement).
- `buildWhen` / `BlocSelector` pour limiter les reconstructions ; états `Equatable` immuables.
- Les moteurs de jeu temps réel (arcade) n'utilisent **pas** setState par frame : `Ticker` +
  `ChangeNotifier` + `CustomPaint(repaint:)` dans un `RepaintBoundary`.

### 2.3 Temps réel et multijoueur

1. **Une seule connexion WebSocket STOMP native** (`/ws-native`, sans SockJS) partagée par toute
   l'app : heartbeats 10 s, reconnexion à backoff exponentiel, re-souscription automatique.
2. **Quiz serveur** (existant) : le serveur fait foi (questions, chrono, points de vitesse).
3. **Salles génériques « lockstep »** (nouveau) : le serveur ordonne les actions (`seq`),
   impose l'expéditeur, fournit une graine aléatoire commune, conserve le journal pour les
   retardataires. Chaque client applique les mêmes règles **pures et déterministes** → même état
   partout, sans serveur de jeu dédié par type.
   - Jeux au tour par tour : morpion, puissance 4, dames, échecs, ludo, cartes, pierre-feuille-ciseaux.
   - Jeux de groupe : sondages, débats, action/vérité, bluff, histoire collective, dessin à deviner.
   - **Course au score** : n'importe quel jeu solo devient multijoueur (même graine pour tous,
     classement à la fin).
4. **Horloge serveur** : chaque message porte `serverTime` → décalage d'horloge calculé côté client
   pour des chronos justes.
5. **Anti-triche / robustesse** : limite de débit par joueur, taille de message bornée,
   récompenses plafonnées côté serveur, nettoyage à la déconnexion.

### 2.4 Live streaming

- LiveKit : `adaptiveStream`, `dynacast`, simulcast, preset 720p ; les spectateurs ne publient pas.
- Annuaire des lives (`/api/v1/stream/live`), compteur de spectateurs.
- Réactions agrégées côté serveur et diffusées toutes les 500 ms (pas un message par cœur).
- Cadeaux (coins spectateur → streamer), sondages en direct, quiz lancé depuis le live
  (« Kahoot + live », « 1 vs audience », « Chat vs streamer »).

### 2.5 Performance

- Démarrage : catalogue chargé une fois (asset JSON parsé en isolate via `compute`).
- Listes : `ListView.builder`/`SliverGrid` avec `itemExtent`, widgets `const`.
- Pas de polices réseau, icônes emoji (zéro asset image lourd).
- Builds release : `--split-debug-info`, `--obfuscate`, tree-shaking des icônes.

---

## 3. Couverture des 1000 idées

Les 1000 idées sont décrites dans `mobile/assets/catalog/catalog.json` (généré depuis le document,
puis curé). Chaque idée est associée à un **moteur** et une **configuration** (thème, durée,
variante). Les idées « plateforme » (classement, boutique, creator studio, live multi, etc.)
pointent vers l'écran qui les implémente.

| Famille | Moteurs |
|---|---|
| Connaissance | quiz, vrai/faux, devinette à réponse libre, emoji/pixel reveal |
| Mots | pendu, anagrammes, catégories (petit bac), frappe rapide |
| Logique / mémoire | suites logiques, calcul rapide, sudoku, taquin, memory, Simon, Stroop |
| Réflexes / précision | réaction, tap battle, cible, timing parfait, tour empilée |
| Arcade | snake, flappy, runner, esquive/collecte, inclinaison, secouer |
| Plateau / cartes | morpion (classique et géant), puissance 4, dames, échecs, ludo, cartes couleurs, PFC |
| Social / party | sondages & débats, action ou vérité, bluff, histoire collective, dessin |
| Live / caméra | défi de performance (chrono + caméra + vote du public) |
| Gamification | roue de la fortune, risque/récompense, quêtes, streak, saisons |

---

## 4. Backend — ajouts

| Module | Endpoints |
|---|---|
| WebSocket natif | `/ws-native` (mobile), `/ws` SockJS conservé (web) |
| Salles génériques | STOMP `/app/room/{id}/join|leave|start|action|finish`, topic `/topic/room/{id}` ; REST `GET /api/v1/rooms`, `POST /api/v1/rooms/quick-match` |
| Scores solo | `POST /api/v1/games/scores`, `GET /api/v1/games/{gameId}/leaderboard`, `GET /api/v1/games/stats/me` |
| Quêtes | `GET /api/v1/quests`, `POST /api/v1/quests/{id}/claim`, `POST /api/v1/quests/daily-bonus` |
| Live | `GET/POST/DELETE /api/v1/stream/live`, `POST /api/v1/stream/live/{room}/gift` ; STOMP réactions / sondages / présence |
| Profils publics | `GET /api/v1/users/{username}` |
| Quiz FR | Banque de questions française multi-thèmes (foot, manga, Afrique, drapeaux, culture…) |

---

## 5. Phases (sprints)

| Sprint | Livrables | Critère de fin |
|---|---|---|
| S0 Fondations | Projet Flutter, design system, DI, router, ApiClient, RealtimeClient, auth | Connexion / inscription OK sur l'API |
| S1 Cœur social | Accueil, profil, fil, classement, boutique, tournois | Parité avec le web |
| S2 Moteur de jeu | Catalogue 1000 idées, session solo, résultats + récompenses | Chaque idée s'ouvre et se joue |
| S3 Moteurs | ~40 moteurs, banques de contenu FR | Tests unitaires des règles verts |
| S4 Multijoueur | Salles lockstep, quick-match, course au score, quiz serveur | 2 clients jouent ensemble |
| S5 Live | LiveKit, chat, réactions, cadeaux, sondages, quiz en live | Streamer + spectateurs interagissent |
| S6 Gamification | Quêtes, bonus quotidien, creator studio | Récompenses cohérentes et plafonnées |
| S7 Qualité | `flutter analyze` 0 problème, tests, CI, doc | CI verte |

---

## 6. Définition de « terminé »

- `flutter analyze` sans avertissement, `flutter test` vert, `./gradlew test` vert.
- Toutes les entrées du catalogue référencent un moteur existant (test automatisé).
- Les règles des jeux multijoueur sont des fonctions pures testées (déterminisme).
- Aucun secret dans le code ; JWT en `flutter_secure_storage`.
