'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Play, Users, Search, Zap, Trophy, Gamepad2, Filter } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import Link from 'next/link';
import { Badge } from '@/components/ui/badge';

const CATEGORIES = ['All', 'Quiz', 'Speed Run', 'Tournament', 'Casual'];

const STREAMS = [
  { id: 'session-1', title: 'Global Trivia Night', host: 'Shadow_X', hostAvatar: '🥷', viewers: 1240, category: 'Quiz', bg: 'from-indigo-900 to-purple-900', live: true, prize: '500 coins' },
  { id: 'session-2', title: 'Speed Run Challenge', host: 'SpeedKing99', hostAvatar: '⚡', viewers: 892, category: 'Speed Run', bg: 'from-rose-900 to-pink-900', live: true, prize: null },
  { id: 'session-3', title: 'Diamond Tournament Finals', host: 'CosmicAce', hostAvatar: '🦅', viewers: 3400, category: 'Tournament', bg: 'from-yellow-900 to-amber-900', live: true, prize: '2000 coins' },
  { id: 'session-4', title: 'Beginner Math Battle', host: 'NeonByte', hostAvatar: '🤖', viewers: 445, category: 'Casual', bg: 'from-green-900 to-emerald-900', live: true, prize: null },
  { id: 'session-5', title: 'Word Masters Cup', host: 'LunaGaming', hostAvatar: '🌙', viewers: 678, category: 'Quiz', bg: 'from-blue-900 to-cyan-900', live: false, prize: '300 coins' },
  { id: 'session-6', title: 'Logic Arena Pro', host: 'IronFist', hostAvatar: '🤜', viewers: 234, category: 'Casual', bg: 'from-slate-900 to-zinc-900', live: false, prize: null },
];

export default function LivePage() {
  const [category, setCategory] = useState('All');
  const [search, setSearch] = useState('');

  const filtered = STREAMS.filter((s) => {
    const matchCat = category === 'All' || s.category === category;
    const matchSearch = s.title.toLowerCase().includes(search.toLowerCase()) || s.host.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  const liveStreams = filtered.filter((s) => s.live);
  const upcomingStreams = filtered.filter((s) => !s.live);

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-7xl mx-auto space-y-7">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Streams</div>
            <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
              <span className="w-3 h-3 bg-red-500 rounded-full animate-pulse" />
              Live Now
            </h1>
          </div>
          <div className="flex items-center gap-2 text-sm text-zinc-400">
            <Users className="w-4 h-4" />
            <span className="font-bold">{STREAMS.filter(s => s.live).reduce((a, s) => a + s.viewers, 0).toLocaleString()}</span>
            <span>watching</span>
          </div>
        </div>

        {/* Search */}
        <div className="flex gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-500" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search streams or hosts..."
              className="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors"
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-sm text-zinc-400 hover:text-white hover:bg-white/8 transition-all">
            <Filter className="w-4 h-4" /> Filter
          </button>
        </div>

        {/* Categories */}
        <div className="flex gap-2 overflow-x-auto pb-1">
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-4 py-2 rounded-xl text-sm font-bold flex-shrink-0 transition-all ${
                category === cat ? 'bg-white text-black' : 'bg-white/5 text-zinc-400 hover:bg-white/10 hover:text-white border border-white/5'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        {/* Featured Stream (largest) */}
        {liveStreams.length > 0 && (
          <Link href={`/live/${liveStreams[0].id}`}>
            <motion.div
              whileHover={{ scale: 1.01 }}
              whileTap={{ scale: 0.99 }}
              className={`relative rounded-3xl overflow-hidden bg-gradient-to-br ${liveStreams[0].bg} border border-white/10 cursor-pointer`}
              style={{ aspectRatio: '21/9' }}
            >
              <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent" />
              {/* Fake video effect */}
              <div className="absolute inset-0 opacity-20">
                {Array.from({ length: 6 }).map((_, i) => (
                  <div key={i} className="absolute bg-white/5 rounded-full animate-pulse"
                    style={{ width: `${80 + i * 40}px`, height: `${80 + i * 40}px`, top: `${20 + i * 8}%`, left: `${10 + i * 12}%`, animationDelay: `${i * 0.3}s` }} />
                ))}
              </div>

              <div className="absolute top-4 left-4 flex items-center gap-2">
                <Badge className="bg-red-500 text-white border-none animate-pulse font-black">LIVE</Badge>
                <div className="bg-black/50 backdrop-blur-sm px-2.5 py-1 rounded-full text-xs font-bold flex items-center gap-1">
                  <Users className="w-3 h-3" /> {liveStreams[0].viewers.toLocaleString()}
                </div>
                {liveStreams[0].prize && (
                  <div className="bg-yellow-500/20 backdrop-blur-sm border border-yellow-500/40 px-2.5 py-1 rounded-full text-xs font-bold text-yellow-400">
                    🏆 {liveStreams[0].prize}
                  </div>
                )}
              </div>

              <div className="absolute bottom-6 left-6 right-6 flex items-end justify-between">
                <div>
                  <h2 className="text-3xl font-black tracking-tighter mb-1">{liveStreams[0].title}</h2>
                  <div className="flex items-center gap-2 text-zinc-300 text-sm">
                    <span className="text-2xl">{liveStreams[0].hostAvatar}</span>
                    <span className="font-bold">{liveStreams[0].host}</span>
                    <Badge className="bg-white/10 text-white border-none text-[10px]">{liveStreams[0].category}</Badge>
                  </div>
                </div>
                <div className="w-14 h-14 bg-white rounded-full flex items-center justify-center shadow-2xl">
                  <Play className="w-6 h-6 text-black fill-black ml-0.5" />
                </div>
              </div>
            </motion.div>
          </Link>
        )}

        {/* Other Live Streams */}
        {liveStreams.length > 1 && (
          <div>
            <h2 className="font-black text-lg mb-4 flex items-center gap-2">
              <Zap className="w-5 h-5 text-yellow-400" /> More Live
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {liveStreams.slice(1).map((stream, i) => (
                <Link href={`/live/${stream.id}`} key={stream.id}>
                  <motion.div
                    initial={{ opacity: 0, y: 16 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.06 }}
                    whileHover={{ scale: 1.02, y: -2 }}
                    whileTap={{ scale: 0.98 }}
                    className={`relative aspect-video rounded-2xl overflow-hidden bg-gradient-to-br ${stream.bg} border border-white/5 cursor-pointer group`}
                  >
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-transparent" />
                    <div className="absolute top-2.5 left-2.5 flex items-center gap-1.5">
                      <Badge className="bg-red-500 text-white border-none text-[10px] animate-pulse px-1.5 py-0.5">LIVE</Badge>
                      <span className="text-[10px] bg-black/40 backdrop-blur-sm px-2 py-0.5 rounded-full text-white/80 font-bold flex items-center gap-1">
                        <Users className="w-2.5 h-2.5" /> {stream.viewers.toLocaleString()}
                      </span>
                    </div>
                    {stream.prize && (
                      <div className="absolute top-2.5 right-2.5">
                        <span className="text-[10px] bg-yellow-500/20 border border-yellow-500/40 px-2 py-0.5 rounded-full text-yellow-400 font-bold">🏆 {stream.prize}</span>
                      </div>
                    )}
                    <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between">
                      <div>
                        <div className="font-bold text-sm leading-tight">{stream.title}</div>
                        <div className="text-xs text-zinc-400 mt-0.5 flex items-center gap-1">
                          <span>{stream.hostAvatar}</span>{stream.host}
                        </div>
                      </div>
                      <div className="w-8 h-8 bg-white/20 group-hover:bg-white rounded-full flex items-center justify-center transition-all">
                        <Play className="w-3.5 h-3.5 text-white group-hover:text-black fill-current ml-0.5" />
                      </div>
                    </div>
                  </motion.div>
                </Link>
              ))}
            </div>
          </div>
        )}

        {/* Upcoming */}
        {upcomingStreams.length > 0 && (
          <div>
            <h2 className="font-black text-lg mb-4 flex items-center gap-2">
              <Gamepad2 className="w-5 h-5 text-indigo-400" /> Starting Soon
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {upcomingStreams.map((stream, i) => (
                <motion.div
                  key={stream.id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: i * 0.06 }}
                  className="flex items-center gap-4 p-4 bg-white/[0.03] border border-white/5 rounded-2xl hover:border-white/10 transition-all cursor-pointer"
                >
                  <div className={`w-14 h-14 rounded-xl bg-gradient-to-br ${stream.bg} flex items-center justify-center text-2xl flex-shrink-0`}>
                    {stream.hostAvatar}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="font-bold text-sm truncate">{stream.title}</div>
                    <div className="text-xs text-zinc-500 mt-0.5">{stream.host} · {stream.category}</div>
                    {stream.prize && <div className="text-xs text-yellow-400 font-bold mt-0.5">🏆 {stream.prize}</div>}
                  </div>
                  <Badge className="bg-zinc-700 text-zinc-300 border-none text-[10px] flex-shrink-0">SOON</Badge>
                </motion.div>
              ))}
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
