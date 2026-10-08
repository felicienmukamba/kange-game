'use client';

import Sidebar from '@/components/Sidebar';
import { useAuthStore, useHydrated } from '@/app/lib/store';
import { api } from '@/app/lib/api';
import type { User } from '@/app/lib/store';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { user, token, setUser } = useAuthStore();
  const hydrated = useHydrated();
  const router = useRouter();
  // Start collapsed on narrow screens (nothing renders until hydrated, so no SSR mismatch)
  const [collapsed, setCollapsed] = useState(() => typeof window !== 'undefined' && window.innerWidth < 1024);

  useEffect(() => {
    if (hydrated && !token) router.replace('/auth');
  }, [hydrated, token, router]);

  // Keep coins / XP / level in sync with the server on every page load
  useEffect(() => {
    if (!hydrated || !token) return;
    api.get<User>('/profile/me').then((res) => setUser(res.data)).catch(() => {});
  }, [hydrated, token, setUser]);

  if (!hydrated || !user || !token) return null;

  return (
    <div className="flex min-h-screen bg-[#080808] text-white font-sans">
      <Sidebar collapsed={collapsed} onToggle={() => setCollapsed((c) => !c)} />
      <main
        className="flex-1 min-h-screen min-w-0 transition-[margin] duration-300"
        style={{ marginLeft: collapsed ? 72 : 240 }}
      >
        {children}
      </main>
    </div>
  );
}
