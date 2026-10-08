import { useSyncExternalStore } from 'react';
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface User {
  id: number;
  username: string;
  email: string;
  role: string;
  avatar?: string | null;
  bio?: string | null;
  level: number;
  xp: number;
  coins: number;
  reputation?: number;
  gamesPlayed: number;
  wins: number;
}

interface AuthState {
  user: User | null;
  token: string | null;
  hydrated: boolean;
  setAuth: (user: User, token: string) => void;
  setUser: (user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      hydrated: false,
      setAuth: (user, token) => set({ user, token }),
      setUser: (user) => set({ user }),
      logout: () => set({ user: null, token: null }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ user: state.user, token: state.token }),
      onRehydrateStorage: () => () => {
        useAuthStore.setState({ hydrated: true });
      },
    }
  )
);

const noopSubscribe = () => () => {};

/**
 * True once the component is mounted on the client AND the persisted auth
 * state has been restored. False during SSR and hydration, so server and
 * first client render always agree.
 */
export function useHydrated() {
  const mounted = useSyncExternalStore(noopSubscribe, () => true, () => false);
  const hydrated = useAuthStore((s) => s.hydrated);
  return mounted && hydrated;
}

/** XP per level on the backend: level N starts at (N - 1) * 1000 XP. */
export const XP_PER_LEVEL = 1000;

export function levelProgress(user: Pick<User, 'xp' | 'level'>) {
  const intoLevel = Math.min(Math.max(user.xp - (user.level - 1) * XP_PER_LEVEL, 0), XP_PER_LEVEL);
  return { intoLevel, needed: XP_PER_LEVEL, percent: (intoLevel / XP_PER_LEVEL) * 100 };
}
