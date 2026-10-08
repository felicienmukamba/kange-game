import axios, { AxiosError } from 'axios';
import { useAuthStore, type User } from './store';

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8080/api/v1';

export const api = axios.create({ baseURL: API_URL });

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (error: AxiosError) => {
    // Expired or invalid session: drop credentials so AppLayout redirects to /auth
    if (error.response?.status === 401 && useAuthStore.getState().token) {
      useAuthStore.getState().logout();
    }
    return Promise.reject(error);
  }
);

/** Extracts a human-readable message from an API error. */
export function apiError(error: unknown, fallback = 'Something went wrong'): string {
  if (axios.isAxiosError(error)) {
    if (!error.response) return 'Cannot reach the server. Is the backend running?';
    const data = error.response.data as { message?: string } | undefined;
    return data?.message ?? fallback;
  }
  return fallback;
}

/* ─── Types mirroring the backend DTOs ─── */

export interface AuthResponse {
  token: string;
  user: User;
}

export interface LeaderboardEntry {
  rank: number;
  userId: number;
  username: string;
  avatar?: string | null;
  score: number;
  level: number;
  wins: number;
  gamesPlayed: number;
}

export interface PostView {
  id: number;
  author: { id: number; username: string; avatar?: string | null; level: number; role: string };
  content: string;
  mediaUrl?: string | null;
  likes: number;
  likedByMe: boolean;
  createdAt: string;
}

export interface MarketplaceItem {
  id: number;
  name: string;
  description: string;
  price: number;
  type: string;
  rarity: string;
  icon?: string | null;
  imageUrl?: string | null;
}

export interface InventoryItem {
  id: number;
  item: MarketplaceItem;
  acquiredAt: string;
}

export interface QuizQuestion {
  id?: string;
  question: string;
  options: string[];
  correctAnswerIndex: number;
  timeLimit: number;
}

export interface Challenge {
  id: number;
  title: string;
  topic: string;
  creator: string;
  prizePool: number;
  maxPlayers: number;
  prizeWinner?: string | null;
  questions: QuizQuestion[];
  createdAt: string;
}

export interface ChallengeSummary {
  id: number;
  title: string;
  topic: string;
  creator: string;
  prizePool: number;
  maxPlayers: number;
  questionCount: number;
  prizeWinner?: string | null;
  roomId: string;
  playersInRoom: number;
  roomStatus: 'IDLE' | 'WAITING' | 'ACTIVE' | 'FINISHED';
  createdAt: string;
}

export interface Tournament {
  id: number;
  title: string;
  type: string;
  status: string;
  topic: string;
  prizePool: number;
  participants: number;
  maxParticipants: number;
  joined: boolean;
  startsAt: string;
  roomId: string;
}

/** Built-in quick-play modes; the room id prefix selects the question set on the backend. */
export const GAME_MODES = [
  { id: 'trivia', icon: '⚡', name: 'Quiz Battle', desc: 'General knowledge, 5 rounds', accent: 'border-yellow-500/20 bg-yellow-500/5' },
  { id: 'math', icon: '🧮', name: 'Speed Math', desc: 'Rapid-fire arithmetic, 10 rounds', accent: 'border-blue-500/20 bg-blue-500/5' },
  { id: 'words', icon: '📝', name: 'Word Rush', desc: 'Vocabulary & language', accent: 'border-green-500/20 bg-green-500/5' },
  { id: 'gaming', icon: '🎮', name: 'Gamer Trivia', desc: 'Test your gaming lore', accent: 'border-purple-500/20 bg-purple-500/5' },
] as const;

/** The always-open public room for each mode. */
export const publicRoomId = (mode: string) => `${mode}-arena`;

export function timeAgo(iso: string) {
  const seconds = Math.max(0, (Date.now() - new Date(iso).getTime()) / 1000);
  if (seconds < 60) return 'just now';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}
