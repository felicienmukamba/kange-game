'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Play, Users, Search, Zap, Gamepad2, RefreshCw } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import Link from 'next/link';
import { Badge } from '@/components/ui/badge';
import { api, GAME_MODES, publicRoomId, type ChallengeSummary } from '@/app/lib/api';

const GRADIENTS = ['from-indigo-900 to-purple-900', 'from-rose-900 to-pink-900', 'from-yellow-900 to-amber-900', 'from-green-900 to-emerald-900', 'from-blue-900 to-cyan-900'];

export default function LivePage() {
  const [challenges, setChallenges] = useState<ChallengeSummary[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  const fetchChallenges = () =>
    api.get<ChallengeSummary[]>('/challenges')
      .then((r) => setChallenges(r.data))
      .catch(() => {})
      .finally(() => setLoading(false));

  const load = () => {
    setLoading(true);
    fetchChallenges();
  };

  useEffect(() => { fetchChallenges(); }, []);

  const q = search.toLowerCase();
  const filtered = challenges.filter((c) => c.title.toLowerCase().includes(q) || c.creator.toLowerCase().includes(q) || c.topic.toLowerCase().includes(q));
  const live = filtered.filter((c) => c.roomStatus === 'ACTIVE' || c.roomStatus === 'WAITING');
  const open = filtered.filter((c) => !(c.roomStatus === 'ACTIVE' || c.roomStatus === 'WAITING'));
  const featured = live[0];

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-7xl mx-auto space-y-7">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Rooms</div>
            <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
              <span className="w-3 h-3 bg-red-500 rounded-full animate-pulse" />
              Live Rooms
            </h1>
          </div>
          <button onClick={load} className="flex items-center gap-2 text-sm text-zinc-400 hover:text-white transition-colors">
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
          </button>
        </div>

        {/* Public arenas — always open */}
        <div>
          <h2 className="font-black text-lg mb-4 flex items-center gap-2">
            <Zap className="w-5 h-5 text-yellow-400" /> Public Arenas
          </h2>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {GAME_MODES.map((mode, i) => (
              <Link href={`/live/${publicRoomId(mode.id)}`} key={mode.id}>
                <motion.div
                  whileHover={{ scale: 1.02, y: -2 }}
                  whileTap={{ scale: 0.98 }}
                  className={`relative aspect-video rounded-2xl overflow-hidden bg-gradient-to-br ${GRADIENTS[i % GRADIENTS.length]} border border-white/5 cursor-pointer group`}
                >
                  <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-transparent" />
                  <div className="absolute top-2.5 left-2.5">
                    <Badge className="bg-white/10 text-white border-none text-[10px] px-1.5 py-0.5">ALWAYS OPEN</Badge>
                  </div>
                  <div className="absolute inset-0 flex items-center justify-center text-5xl opacity-60 group-hover:scale-110 transition-transform">{mode.icon}</div>
                  <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between">
                    <div>
                      <div className="font-bold text-sm leading-tight">{mode.name}</div>
                      <div className="text-xs text-zinc-400 mt-0.5">{mode.desc}</div>
                    </div>
                    <div className="w-8 h-8 bg-white/20 group-hover:bg-white rounded-full flex items-center justify-center transition-all flex-shrink-0">
                      <Play className="w-3.5 h-3.5 text-white group-hover:text-black fill-current ml-0.5" />
                    </div>
                  </div>
                </motion.div>
              </Link>
            ))}
          </div>
        </div>

        <div className="relative">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-500" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search challenges, creators or topics..."
            className="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors"
          />
        </div>

        {/* Featured live challenge */}
        {featured && (
          <Link href={`/live/${featured.roomId}`} className="block">
            <motion.div
              whileHover={{ scale: 1.01 }}
              whileTap={{ scale: 0.99 }}
              className="relative rounded-3xl overflow-hidden bg-gradient-to-br from-indigo-900 to-purple-900 border border-white/10 cursor-pointer"
              style={{ aspectRatio: '21/9' }}
            >
              <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent" />
              <div className="absolute top-4 left-4 flex items-center gap-2">
                <Badge className="bg-red-500 text-white border-none animate-pulse font-black">LIVE</Badge>
                <div className="bg-black/50 backdrop-blur-sm px-2.5 py-1 rounded-full text-xs font-bold flex items-center gap-1">
                  <Users className="w-3 h-3" /> {featured.playersInRoom}
                </div>
                {featured.prizePool > 0 && !featured.prizeWinner && (
                  <div className="bg-yellow-500/20 backdrop-blur-sm border border-yellow-500/40 px-2.5 py-1 rounded-full text-xs font-bold text-yellow-400">
                    🏆 {featured.prizePool} coins
                  </div>
                )}
              </div>
              <div className="absolute bottom-6 left-6 right-6 flex items-end justify-between">
                <div>
                  <h2 className="text-3xl font-black tracking-tighter mb-1">{featured.title}</h2>
                  <div className="flex items-center gap-2 text-zinc-300 text-sm">
                    <span className="font-bold">{featured.creator}</span>
                    <Badge className="bg-white/10 text-white border-none text-[10px]">{featured.topic}</Badge>
                  </div>
                </div>
                <div className="w-14 h-14 bg-white rounded-full flex items-center justify-center shadow-2xl">
                  <Play className="w-6 h-6 text-black fill-black ml-0.5" />
                </div>
              </div>
            </motion.div>
          </Link>
        )}

        {/* Community challenges */}
        <div>
          <h2 className="font-black text-lg mb-4 flex items-center gap-2">
            <Gamepad2 className="w-5 h-5 text-indigo-400" /> Community Challenges
          </h2>
          {!loading && filtered.length === 0 && (
            <div className="text-center text-zinc-500 text-sm py-10 border border-dashed border-white/10 rounded-2xl">
              {challenges.length === 0 ? <>No challenges yet. <Link href="/creator" className="text-white underline">Create one</Link>.</> : 'No challenges match your search.'}
            </div>
          )}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {[...live.slice(1), ...open].map((c, i) => {
              const isLive = c.roomStatus === 'ACTIVE' || c.roomStatus === 'WAITING';
              return (
                <Link key={c.id} href={`/live/${c.roomId}`}>
                  <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ delay: i * 0.04 }}
                    className="flex items-center gap-4 p-4 bg-white/[0.03] border border-white/5 rounded-2xl hover:border-white/10 transition-all cursor-pointer"
                  >
                    <div className={`w-14 h-14 rounded-xl bg-gradient-to-br ${GRADIENTS[c.id % GRADIENTS.length]} flex items-center justify-center text-2xl flex-shrink-0`}>
                      {GAME_MODES.find((m) => m.id === c.topic)?.icon ?? '🎯'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-bold text-sm truncate">{c.title}</div>
                      <div className="text-xs text-zinc-500 mt-0.5">{c.creator} · {c.topic} · {c.questionCount} questions</div>
                      {c.prizePool > 0 && (
                        <div className="text-xs text-yellow-400 font-bold mt-0.5">
                          🏆 {c.prizePool} coins{c.prizeWinner ? ` · won by ${c.prizeWinner}` : ''}
                        </div>
                      )}
                    </div>
                    {isLive
                      ? <Badge className="bg-red-500 text-white border-none text-[10px] flex-shrink-0 animate-pulse">LIVE · {c.playersInRoom}</Badge>
                      : <Badge className="bg-zinc-700 text-zinc-300 border-none text-[10px] flex-shrink-0">OPEN</Badge>}
                  </motion.div>
                </Link>
              );
            })}
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
