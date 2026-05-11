'use client';

import Sidebar from '@/components/Sidebar';
import { useAuthStore } from '@/app/lib/store';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { user } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    if (!user) router.push('/auth');
  }, [user, router]);

  if (!user) return null;

  return (
    <div className="flex min-h-screen bg-[#080808] text-white font-sans">
      <Sidebar />
      <main className="flex-1 ml-[240px] min-h-screen transition-all duration-300">
        {children}
      </main>
    </div>
  );
}
