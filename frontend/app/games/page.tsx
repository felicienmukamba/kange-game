'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Gamepad2, Users, Lock, Copy, ArrowRight } from 'lucide-react';
import { toast } from 'sonner';
import AppLayout from '@/components/AppLayout';
import { GAME_MODES, publicRoomId } from '@/app/lib/api';

/** A short random room code; the prefix selects the question set. */
function newRoomCode(mode: string) {
  return `${mode}-${Math.random().toString(36).slice(2, 8)}`;
}

export default function GamesPage() {
  const router = useRouter();
  const [joinCode, setJoinCode] = useState('');

  const createPrivateRoom = (mode: string) => {
    const code = newRoomCode(mode);
    const url = `${window.location.origin}/live/${code}`;
    navigator.clipboard?.writeText(url).then(
      () => toast.success('Private room created — invite link copied!', { description: url }),
      () => toast.success('Private room created', { description: url })
    );
    router.push(`/live/${code}`);
  };

  const join = (e: React.FormEvent) => {
    e.preventDefault();
    // Accept either a full invite link or just the room code
    const code = joinCode.trim().split('/live/').pop()?.replace(/[^A-Za-z0-9-]/g, '');
    if (code) router.push(`/live/${code}`);
  };

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-6xl mx-auto space-y-8">
        <div>
          <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Play</div>
          <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
            <Gamepad2 className="w-8 h-8 text-indigo-400" /> Games
          </h1>
          <p className="text-zinc-500 text-sm mt-2">Jump into a public arena, or spin up a private room and invite your crew.</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {GAME_MODES.map((mode, i) => (
            <motion.div
              key={mode.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.06 }}
              className={`border ${mode.accent} rounded-3xl p-6 space-y-4`}
            >
              <div className="flex items-start gap-4">
                <span className="text-5xl">{mode.icon}</span>
                <div>
                  <h2 className="font-black text-xl">{mode.name}</h2>
                  <p className="text-sm text-zinc-400">{mode.desc}</p>
                </div>
              </div>
              <div className="flex gap-2">
                <Link href={`/live/${publicRoomId(mode.id)}`} className="flex-1">
                  <button className="w-full flex items-center justify-center gap-2 py-3 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all text-sm">
                    <Users className="w-4 h-4" /> Public arena
                  </button>
                </Link>
                <button
                  onClick={() => createPrivateRoom(mode.id)}
                  className="flex-1 flex items-center justify-center gap-2 py-3 bg-white/5 border border-white/10 font-black rounded-xl hover:bg-white/10 transition-all text-sm"
                >
                  <Lock className="w-4 h-4" /> Private room
                </button>
              </div>
            </motion.div>
          ))}
        </div>

        <form onSubmit={join} className="bg-white/[0.03] border border-white/5 rounded-2xl p-5 flex flex-col sm:flex-row gap-3 sm:items-center">
          <div className="flex items-center gap-2 text-sm font-bold text-zinc-300">
            <Copy className="w-4 h-4" /> Have an invite?
          </div>
          <input
            value={joinCode}
            onChange={(e) => setJoinCode(e.target.value)}
            placeholder="Paste a room link or code, e.g. trivia-a1b2c3"
            className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30"
          />
          <button type="submit" disabled={!joinCode.trim()} className="flex items-center justify-center gap-2 px-5 py-3 bg-white text-black font-black rounded-xl text-sm disabled:opacity-30">
            Join <ArrowRight className="w-4 h-4" />
          </button>
        </form>
      </div>
    </AppLayout>
  );
}
