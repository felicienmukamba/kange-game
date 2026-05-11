'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Trophy, Crown, Star, Zap, TrendingUp, Medal, Users, ArrowUp, ArrowDown, Minus } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import { useAuthStore } from '@/app/lib/store';

const TABS = ['Global', 'Weekly', 'Friends'];

const PLAYERS = [
  { rank: 1, name: 'Shadow_X', avatar: '🥷', score: 48200, wins: 312, level: 99, change: 0, badge: 'LEGEND' },
  { rank: 2, name: 'NeonByte', avatar: '🤖', score: 42100, wins: 278, level: 87, change: 1, badge: 'MASTER' },
  { rank: 3, name: 'CosmicAce', avatar: '🦅', score: 39800, wins: 254, level: 82, change: -1, badge: 'MASTER' },
  { rank: 4, name: 'SpeedKing99', avatar: '⚡', score: 35600, wins: 231, level: 75, change: 2, badge: 'DIAMOND' },
  { rank: 5, name: 'PhoenixRise', avatar: '🔥', score: 31200, wins: 198, level: 68, change: 0, badge: 'DIAMOND' },
  { rank: 6, name: 'CryptoWiz', avatar: '🧙', score: 28900, wins: 176, level: 61, change: -2, badge: 'GOLD' },
  { rank: 7, name: 'StormBreaker', avatar: '⚔️', score: 25400, wins: 155, level: 54, change: 3, badge: 'GOLD' },
  { rank: 8, name: 'LunaGaming', avatar: '🌙', score: 22100, wins: 134, level: 48, change: 1, badge: 'SILVER' },
  { rank: 9, name: 'IronFist', avatar: '🤜', score: 19800, wins: 112, level: 42, change: -1, badge: 'SILVER' },
  { rank: 10, name: 'VortexX', avatar: '🌀', score: 17500, wins: 98, level: 36, change: 0, badge: 'BRONZE' },
];

const BADGE_STYLES: Record<string, string> = {
  LEGEND: 'bg-gradient-to-r from-yellow-400 to-orange-500 text-black',
  MASTER: 'bg-gradient-to-r from-purple-500 to-pink-500 text-white',
  DIAMOND: 'bg-gradient-to-r from-blue-400 to-cyan-400 text-black',
  GOLD: 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30',
  SILVER: 'bg-zinc-500/20 text-zinc-300 border border-zinc-500/30',
  BRONZE: 'bg-orange-900/30 text-orange-400 border border-orange-500/20',
};

const TOP_3_COLORS = ['from-yellow-500/30 to-amber-500/30 border-yellow-500/40', 'from-zinc-400/20 to-zinc-600/20 border-zinc-400/30', 'from-orange-600/20 to-amber-700/20 border-orange-600/30'];
const TOP_3_ICONS = ['🥇', '🥈', '🥉'];

export default function LeaderboardPage() {
  const { user } = useAuthStore();
  const [tab, setTab] = useState('Global');

  const myRank = 412;

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-4xl mx-auto space-y-7">
        {/* Header */}
        <div>
          <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Rankings</div>
          <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
            <Trophy className="w-8 h-8 text-yellow-400" /> Leaderboard
          </h1>
        </div>

        {/* My Rank Banner */}
        <div className="bg-gradient-to-r from-indigo-600/20 to-purple-600/20 border border-indigo-500/30 rounded-2xl p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-xl font-black">
            {user?.username?.[0]?.toUpperCase()}
          </div>
          <div className="flex-1">
            <div className="font-black text-lg">{user?.username}</div>
            <div className="text-zinc-400 text-sm">Your current ranking</div>
          </div>
          <div className="text-right">
            <div className="text-3xl font-black text-white">#{myRank}</div>
            <div className="text-xs text-zinc-500">Global rank</div>
          </div>
        </div>

        {/* Top 3 Podium */}
        <div className="grid grid-cols-3 gap-4">
          {[PLAYERS[1], PLAYERS[0], PLAYERS[2]].map((player, i) => {
            const actualI = i === 0 ? 1 : i === 1 ? 0 : 2;
            return (
              <motion.div
                key={player.rank}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: actualI * 0.1 }}
                className={`bg-gradient-to-br ${TOP_3_COLORS[actualI]} border rounded-2xl p-4 flex flex-col items-center gap-2 text-center ${i === 1 ? 'scale-105 -mt-2' : ''}`}
              >
                <span className="text-2xl">{TOP_3_ICONS[actualI]}</span>
                <div className="text-3xl">{player.avatar}</div>
                <div className="font-black text-sm">{player.name}</div>
                <div className="text-xs text-zinc-400">{player.score.toLocaleString()} pts</div>
                <span className={`text-[9px] font-black px-2 py-0.5 rounded-full ${BADGE_STYLES[player.badge]}`}>{player.badge}</span>
              </motion.div>
            );
          })}
        </div>

        {/* Tabs */}
        <div className="flex gap-1 bg-white/5 border border-white/10 rounded-xl p-1">
          {TABS.map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`flex-1 py-2 rounded-lg text-sm font-bold transition-all ${tab === t ? 'bg-white text-black' : 'text-zinc-500 hover:text-white'}`}
            >
              {t}
            </button>
          ))}
        </div>

        {/* Rankings List */}
        <div className="space-y-2">
          <AnimatePresence mode="wait">
            <motion.div
              key={tab}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-2"
            >
              {PLAYERS.map((player, i) => {
                const isMe = player.name === user?.username;
                return (
                  <motion.div
                    key={player.rank}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.04 }}
                    whileHover={{ x: 4 }}
                    className={`flex items-center gap-4 p-4 rounded-2xl border transition-all ${
                      isMe
                        ? 'bg-indigo-600/15 border-indigo-500/40'
                        : 'bg-white/[0.02] border-white/5 hover:bg-white/[0.04] hover:border-white/10'
                    }`}
                  >
                    {/* Rank */}
                    <div className={`w-8 text-center font-black text-sm flex-shrink-0 ${player.rank <= 3 ? 'text-yellow-400' : 'text-zinc-500'}`}>
                      #{player.rank}
                    </div>

                    {/* Avatar */}
                    <div className="w-10 h-10 rounded-xl bg-zinc-800/80 flex items-center justify-center text-xl flex-shrink-0">
                      {player.avatar}
                    </div>

                    {/* Name + Badge */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className={`font-black text-sm ${isMe ? 'text-indigo-300' : 'text-white'}`}>{player.name}</span>
                        <span className={`text-[9px] font-black px-1.5 py-0.5 rounded-full ${BADGE_STYLES[player.badge]}`}>{player.badge}</span>
                        {isMe && <span className="text-[9px] text-indigo-400 font-black">YOU</span>}
                      </div>
                      <div className="flex items-center gap-3 mt-0.5">
                        <span className="text-[11px] text-zinc-500 flex items-center gap-1"><Star className="w-3 h-3 text-yellow-500 fill-yellow-500" /> Lv.{player.level}</span>
                        <span className="text-[11px] text-zinc-500 flex items-center gap-1"><Trophy className="w-3 h-3" /> {player.wins}W</span>
                      </div>
                    </div>

                    {/* Score */}
                    <div className="text-right flex-shrink-0">
                      <div className="font-black text-sm">{player.score.toLocaleString()}</div>
                      <div className="text-[10px] font-bold flex items-center justify-end gap-0.5 mt-0.5">
                        {player.change > 0 ? <><ArrowUp className="w-3 h-3 text-green-400" /><span className="text-green-400">+{player.change}</span></> :
                         player.change < 0 ? <><ArrowDown className="w-3 h-3 text-red-400" /><span className="text-red-400">{player.change}</span></> :
                         <><Minus className="w-3 h-3 text-zinc-600" /><span className="text-zinc-600">—</span></>}
                      </div>
                    </div>
                  </motion.div>
                );
              })}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </AppLayout>
  );
}
