'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Trophy, Star, Gamepad2, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import AppLayout from '@/components/AppLayout';
import { useAuthStore } from '@/app/lib/store';
import { api, apiError, type LeaderboardEntry } from '@/app/lib/api';

const TOP_3_COLORS = ['from-yellow-500/30 to-amber-500/30 border-yellow-500/40', 'from-zinc-400/20 to-zinc-600/20 border-zinc-400/30', 'from-orange-600/20 to-amber-700/20 border-orange-600/30'];
const TOP_3_ICONS = ['🥇', '🥈', '🥉'];

function tier(level: number) {
  if (level >= 90) return { name: 'LEGEND', style: 'bg-gradient-to-r from-yellow-400 to-orange-500 text-black' };
  if (level >= 50) return { name: 'MASTER', style: 'bg-gradient-to-r from-purple-500 to-pink-500 text-white' };
  if (level >= 25) return { name: 'DIAMOND', style: 'bg-gradient-to-r from-blue-400 to-cyan-400 text-black' };
  if (level >= 10) return { name: 'GOLD', style: 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30' };
  if (level >= 5) return { name: 'SILVER', style: 'bg-zinc-500/20 text-zinc-300 border border-zinc-500/30' };
  return { name: 'BRONZE', style: 'bg-orange-900/30 text-orange-400 border border-orange-500/20' };
}

export default function LeaderboardPage() {
  const { user } = useAuthStore();
  const [players, setPlayers] = useState<LeaderboardEntry[]>([]);
  const [myRank, setMyRank] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.get<LeaderboardEntry[]>('/leaderboard/global', { params: { limit: 50 } }),
      api.get<{ rank: number }>('/leaderboard/me'),
    ])
      .then(([top, me]) => { setPlayers(top.data); setMyRank(me.data.rank); })
      .catch((error) => toast.error(apiError(error, 'Could not load the leaderboard')))
      .finally(() => setLoading(false));
  }, []);

  const podium = players.length >= 3 ? [players[1], players[0], players[2]] : [];

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-4xl mx-auto space-y-7">
        <div>
          <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Rankings</div>
          <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
            <Trophy className="w-8 h-8 text-yellow-400" /> Leaderboard
          </h1>
        </div>

        {/* My Rank Banner */}
        <div className="bg-gradient-to-r from-indigo-600/20 to-purple-600/20 border border-indigo-500/30 rounded-2xl p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-xl font-black">
            {user?.avatar ?? user?.username?.[0]?.toUpperCase()}
          </div>
          <div className="flex-1">
            <div className="font-black text-lg">{user?.username}</div>
            <div className="text-zinc-400 text-sm">{user?.xp.toLocaleString()} XP · {user?.wins} wins</div>
          </div>
          <div className="text-right">
            <div className="text-3xl font-black text-white">{myRank ? `#${myRank}` : '—'}</div>
            <div className="text-xs text-zinc-500">Global rank</div>
          </div>
        </div>

        {loading && <div className="flex justify-center py-12"><Loader2 className="w-6 h-6 animate-spin text-zinc-600" /></div>}

        {/* Top 3 Podium */}
        {podium.length === 3 && (
          <div className="grid grid-cols-3 gap-4">
            {podium.map((player, i) => {
              const place = player.rank - 1;
              return (
                <motion.div
                  key={player.userId}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: place * 0.1 }}
                  className={`bg-gradient-to-br ${TOP_3_COLORS[place]} border rounded-2xl p-4 flex flex-col items-center gap-2 text-center ${i === 1 ? 'scale-105 -mt-2' : ''}`}
                >
                  <span className="text-2xl">{TOP_3_ICONS[place]}</span>
                  <div className="text-3xl">{player.avatar ?? '🎮'}</div>
                  <div className="font-black text-sm truncate max-w-full">{player.username}</div>
                  <div className="text-xs text-zinc-400">{player.score.toLocaleString()} XP</div>
                  <span className={`text-[9px] font-black px-2 py-0.5 rounded-full ${tier(player.level).style}`}>{tier(player.level).name}</span>
                </motion.div>
              );
            })}
          </div>
        )}

        {/* Rankings List */}
        <div className="space-y-2">
          {players.map((player, i) => {
            const isMe = player.userId === user?.id;
            const t = tier(player.level);
            return (
              <motion.div
                key={player.userId}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: Math.min(i, 15) * 0.03 }}
                className={`flex items-center gap-4 p-4 rounded-2xl border transition-all ${
                  isMe ? 'bg-indigo-600/15 border-indigo-500/40' : 'bg-white/[0.02] border-white/5 hover:bg-white/[0.04] hover:border-white/10'
                }`}
              >
                <div className={`w-8 text-center font-black text-sm flex-shrink-0 ${player.rank <= 3 ? 'text-yellow-400' : 'text-zinc-500'}`}>
                  #{player.rank}
                </div>
                <div className="w-10 h-10 rounded-xl bg-zinc-800/80 flex items-center justify-center text-xl flex-shrink-0">
                  {player.avatar ?? player.username[0].toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className={`font-black text-sm truncate ${isMe ? 'text-indigo-300' : 'text-white'}`}>{player.username}</span>
                    <span className={`text-[9px] font-black px-1.5 py-0.5 rounded-full ${t.style}`}>{t.name}</span>
                    {isMe && <span className="text-[9px] text-indigo-400 font-black">YOU</span>}
                  </div>
                  <div className="flex items-center gap-3 mt-0.5">
                    <span className="text-[11px] text-zinc-500 flex items-center gap-1"><Star className="w-3 h-3 text-yellow-500 fill-yellow-500" /> Lv.{player.level}</span>
                    <span className="text-[11px] text-zinc-500 flex items-center gap-1"><Trophy className="w-3 h-3" /> {player.wins}W</span>
                    <span className="text-[11px] text-zinc-500 flex items-center gap-1"><Gamepad2 className="w-3 h-3" /> {player.gamesPlayed}</span>
                  </div>
                </div>
                <div className="text-right flex-shrink-0">
                  <div className="font-black text-sm">{player.score.toLocaleString()}</div>
                  <div className="text-[10px] text-zinc-500">XP</div>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>
    </AppLayout>
  );
}
