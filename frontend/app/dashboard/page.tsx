'use client';

import { levelProgress, useAuthStore } from '@/app/lib/store';
import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Gamepad2, Play, Trophy, Users, Zap, TrendingUp, Star, Sparkles, ArrowRight, Calendar, ChevronRight } from 'lucide-react';
import Link from 'next/link';
import { toast } from 'sonner';
import AppLayout from '@/components/AppLayout';
import {
  api, apiError, GAME_MODES, publicRoomId,
  type ChallengeSummary, type LeaderboardEntry, type Tournament,
} from '@/app/lib/api';

export default function DashboardPage() {
  const { user } = useAuthStore();
  const [rank, setRank] = useState<number | null>(null);
  const [topPlayers, setTopPlayers] = useState<LeaderboardEntry[]>([]);
  const [tournaments, setTournaments] = useState<Tournament[]>([]);
  const [challenges, setChallenges] = useState<ChallengeSummary[]>([]);

  useEffect(() => {
    api.get<{ rank: number }>('/leaderboard/me').then((r) => setRank(r.data.rank)).catch(() => {});
    api.get<LeaderboardEntry[]>('/leaderboard/global', { params: { limit: 3 } }).then((r) => setTopPlayers(r.data)).catch(() => {});
    api.get<Tournament[]>('/tournaments').then((r) => setTournaments(r.data)).catch(() => {});
    api.get<ChallengeSummary[]>('/challenges').then((r) => setChallenges(r.data.slice(0, 4))).catch(() => {});
  }, []);

  const joinTournament = async (t: Tournament) => {
    try {
      const res = await api.post<Tournament>(`/tournaments/${t.id}/join`);
      setTournaments((prev) => prev.map((x) => (x.id === t.id ? res.data : x)));
      toast.success(`You're in: ${t.title}`);
    } catch (error) {
      toast.error(apiError(error));
    }
  };

  if (!user) return <AppLayout>{null}</AppLayout>;

  const progress = levelProgress(user);
  const achievements = [
    { icon: '🏆', label: 'First Victory', earned: user.wins >= 1 },
    { icon: '🎮', label: 'Veteran (10 games)', earned: user.gamesPlayed >= 10 },
    { icon: '💰', label: '1,000 Coins', earned: user.coins >= 1000 },
    { icon: '🌟', label: 'Level 10', earned: user.level >= 10 },
  ];

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-7xl mx-auto space-y-7">
        {/* Header */}
        <div className="flex items-center justify-between gap-4 flex-wrap">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Dashboard</div>
            <h1 className="text-3xl font-black tracking-tighter">Hey, {user.username} {user.avatar ?? '👋'}</h1>
          </div>
          <Link href="/creator">
            <button className="flex items-center gap-2 px-4 py-2.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all text-sm">
              <Sparkles className="w-4 h-4" /> Create
            </button>
          </Link>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label: 'Coins', value: user.coins.toLocaleString(), icon: Star, color: 'text-yellow-400', bg: 'bg-yellow-500/10' },
            { label: 'Level', value: user.level, icon: TrendingUp, color: 'text-indigo-400', bg: 'bg-indigo-500/10' },
            { label: 'Games', value: user.gamesPlayed, icon: Gamepad2, color: 'text-green-400', bg: 'bg-green-500/10' },
            { label: 'Rank', value: rank ? `#${rank}` : '—', icon: Trophy, color: 'text-orange-400', bg: 'bg-orange-500/10' },
          ].map((s, i) => (
            <motion.div key={s.label} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}
              className="bg-white/[0.03] border border-white/5 rounded-2xl p-5 flex items-center gap-4 hover:bg-white/[0.05] transition-colors">
              <div className={`w-10 h-10 rounded-xl ${s.bg} flex items-center justify-center`}>
                <s.icon className={`w-5 h-5 ${s.color}`} />
              </div>
              <div>
                <div className="text-2xl font-black">{s.value}</div>
                <div className="text-[11px] text-zinc-500 font-bold uppercase">{s.label}</div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* XP Bar */}
        <div className="bg-gradient-to-r from-indigo-600/10 to-purple-600/10 border border-indigo-500/20 rounded-2xl p-5">
          <div className="flex justify-between items-center mb-2">
            <span className="font-bold text-sm text-indigo-300">Level {user.level} Progress</span>
            <span className="text-xs text-zinc-500 font-bold">{progress.intoLevel} / {progress.needed} XP</span>
          </div>
          <Progress value={progress.percent} className="h-2 bg-white/10" />
          <div className="mt-1.5 text-xs text-zinc-500">{progress.needed - progress.intoLevel} XP to Level {user.level + 1} · earn 10 XP per quiz point</div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            {/* Quick Games */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-black text-lg flex items-center gap-2"><Zap className="w-5 h-5 text-yellow-400" /> Quick Play</h2>
                <Link href="/games" className="text-xs text-zinc-500 hover:text-white flex items-center gap-1 transition-colors">All <ChevronRight className="w-3 h-3" /></Link>
              </div>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {GAME_MODES.map((g) => (
                  <Link href={`/live/${publicRoomId(g.id)}`} key={g.id}>
                    <motion.div whileHover={{ y: -4 }} whileTap={{ scale: 0.97 }}
                      className={`border ${g.accent} rounded-2xl p-4 flex flex-col gap-2 cursor-pointer group hover:border-white/20 transition-all h-full`}>
                      <span className="text-2xl">{g.icon}</span>
                      <div className="font-bold text-sm">{g.name}</div>
                      <div className="text-[11px] text-zinc-500">{g.desc}</div>
                      <span className="mt-auto text-center text-[11px] font-black text-white bg-white/10 rounded-lg py-1.5 group-hover:bg-white/20 transition-colors">PLAY</span>
                    </motion.div>
                  </Link>
                ))}
              </div>
            </div>

            {/* Community challenges */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-black text-lg flex items-center gap-2">
                  <span className="w-2 h-2 bg-red-500 rounded-full animate-pulse" /> Community Challenges
                </h2>
                <Link href="/live" className="text-xs text-zinc-500 hover:text-white flex items-center gap-1 transition-colors">
                  See all <ChevronRight className="w-3 h-3" />
                </Link>
              </div>
              {challenges.length === 0 ? (
                <div className="border border-dashed border-white/10 rounded-2xl p-8 text-center text-sm text-zinc-500">
                  No challenges yet. <Link href="/creator" className="text-white underline">Create the first one</Link>.
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {challenges.map((c) => (
                    <Link href={`/live/${c.roomId}`} key={c.id}>
                      <motion.div whileHover={{ scale: 1.02, y: -2 }} whileTap={{ scale: 0.98 }}
                        className="relative aspect-video rounded-2xl overflow-hidden bg-gradient-to-br from-indigo-900 to-purple-900 border border-white/5 cursor-pointer">
                        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent" />
                        <div className="absolute top-3 left-3 flex items-center gap-2">
                          {c.roomStatus === 'ACTIVE' || c.roomStatus === 'WAITING'
                            ? <Badge className="bg-red-500 text-white border-none text-[10px] animate-pulse px-2">LIVE</Badge>
                            : <Badge className="bg-white/10 text-white border-none text-[10px] px-2">OPEN</Badge>}
                          <span className="text-[10px] text-white/70 flex items-center gap-1"><Users className="w-3 h-3" /> {c.playersInRoom}</span>
                        </div>
                        {c.prizePool > 0 && !c.prizeWinner && (
                          <div className="absolute top-3 right-12 text-[10px] bg-yellow-500/20 border border-yellow-500/40 px-2 py-0.5 rounded-full text-yellow-400 font-bold">🏆 {c.prizePool}</div>
                        )}
                        <div className="absolute bottom-3 left-3">
                          <div className="font-bold text-sm">{c.title}</div>
                          <div className="text-xs text-zinc-400">by {c.creator} · {c.questionCount} questions</div>
                        </div>
                        <div className="absolute top-3 right-3 w-8 h-8 bg-white/10 backdrop-blur-sm rounded-full flex items-center justify-center">
                          <Play className="w-4 h-4 fill-white text-white" />
                        </div>
                      </motion.div>
                    </Link>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="space-y-5">
            {/* Tournaments */}
            <div className="bg-gradient-to-br from-indigo-600/20 to-purple-600/20 border border-indigo-500/30 rounded-2xl p-5 space-y-3">
              <h3 className="font-black text-sm flex items-center gap-2"><Calendar className="w-4 h-4 text-indigo-300" /> Tournaments</h3>
              {tournaments.length === 0 && <p className="text-xs text-zinc-500">No tournaments scheduled.</p>}
              {tournaments.map((t) => (
                <div key={t.id} className="bg-black/20 rounded-xl p-3 space-y-2">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <div className="font-bold text-sm">{t.title}</div>
                      <div className="text-[11px] text-zinc-400">
                        {t.status === 'ONGOING' ? 'Ongoing' : `Starts ${new Date(t.startsAt).toLocaleString()}`} · {t.participants}/{t.maxParticipants}
                      </div>
                    </div>
                    <span className="text-[11px] text-yellow-400 font-bold whitespace-nowrap">🏆 {t.prizePool.toLocaleString()}</span>
                  </div>
                  {t.joined ? (
                    t.status === 'ONGOING'
                      ? <Link href={`/live/${t.roomId}`} className="block text-center text-xs font-black bg-white text-black rounded-lg py-1.5">ENTER ARENA</Link>
                      : <div className="text-center text-xs font-bold text-green-400 bg-green-500/10 rounded-lg py-1.5">✓ Registered</div>
                  ) : (
                    <button onClick={() => joinTournament(t)} className="w-full text-xs font-black bg-white/10 hover:bg-white/20 rounded-lg py-1.5 transition-colors">JOIN</button>
                  )}
                </div>
              ))}
            </div>

            {/* Achievements */}
            <div className="bg-white/[0.03] border border-white/5 rounded-2xl p-5">
              <h3 className="font-black text-sm mb-3 flex items-center gap-2"><Trophy className="w-4 h-4 text-yellow-400" /> Achievements</h3>
              <div className="grid grid-cols-2 gap-2">
                {achievements.map((a) => (
                  <div key={a.label} className={`flex flex-col items-center gap-1 p-3 rounded-xl border text-center ${a.earned ? 'border-yellow-500/30 bg-yellow-500/10' : 'border-white/5 opacity-40'}`}>
                    <span className="text-xl">{a.icon}</span>
                    <span className="text-[10px] font-bold text-zinc-400 leading-tight">{a.label}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Leaderboard teaser */}
            <Link href="/leaderboard" className="block">
              <motion.div whileHover={{ scale: 1.01 }} className="bg-white/[0.03] border border-white/5 rounded-2xl p-5 cursor-pointer hover:border-white/10 transition-all group">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-black text-sm">Top Players</h3>
                  <ArrowRight className="w-4 h-4 text-zinc-600 group-hover:text-white transition-colors" />
                </div>
                {topPlayers.map((p) => (
                  <div key={p.userId} className="flex items-center gap-3 py-2 border-b border-white/5 last:border-0">
                    <span className="text-xs font-black text-zinc-600 w-4">#{p.rank}</span>
                    <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-xs font-black">{p.avatar ?? p.username[0].toUpperCase()}</div>
                    <span className="text-sm font-bold flex-1 truncate">{p.username}</span>
                    <span className="text-xs text-zinc-500">{p.score.toLocaleString()} XP</span>
                  </div>
                ))}
              </motion.div>
            </Link>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
