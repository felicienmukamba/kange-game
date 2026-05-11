'use client';

import { useAuthStore } from '@/app/lib/store';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { motion } from 'framer-motion';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Gamepad2, Play, Trophy, Users, Zap, TrendingUp, Star, Sparkles, Bell, ArrowRight, Flame, Clock, ChevronRight } from 'lucide-react';
import Link from 'next/link';
import { toast } from 'sonner';
import AppLayout from '@/components/AppLayout';

const QUICK_GAMES = [
  { name: 'Quiz Battle', icon: '⚡', players: '2.4k', border: 'border-yellow-500/20 bg-yellow-500/5', href: '/games/quiz' },
  { name: 'Speed Math', icon: '🧮', players: '890', border: 'border-blue-500/20 bg-blue-500/5', href: '/games/math' },
  { name: 'Word Rush', icon: '📝', players: '1.2k', border: 'border-green-500/20 bg-green-500/5', href: '/games/words' },
  { name: 'Memory Pro', icon: '🧠', players: '560', border: 'border-purple-500/20 bg-purple-500/5', href: '/games/memory' },
];

const TOP_PLAYERS = ['Shadow_X', 'NeonByte', 'CosmicAce'];

export default function DashboardPage() {
  const { user } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    const t = setTimeout(() => {
      toast.info('Tournament starting soon!', {
        description: 'Join "Global Logic" arena now!',
        action: { label: 'Join', onClick: () => router.push('/live/tourney-1') },
      });
    }, 5000);
    return () => clearTimeout(t);
  }, [router]);

  if (!user) return null;

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-7xl mx-auto space-y-7">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Dashboard</div>
            <h1 className="text-3xl font-black tracking-tighter">Hey, {user.username} 👋</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="relative">
              <button className="w-10 h-10 bg-white/5 border border-white/10 rounded-xl flex items-center justify-center hover:bg-white/10 transition-colors">
                <Bell className="w-5 h-5 text-zinc-400" />
              </button>
              <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full text-[9px] font-black flex items-center justify-center">3</span>
            </div>
            <Link href="/creator">
              <button className="flex items-center gap-2 px-4 py-2.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all text-sm">
                <Sparkles className="w-4 h-4" /> Create
              </button>
            </Link>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label: 'Coins', value: user.coins, icon: Star, color: 'text-yellow-400', bg: 'bg-yellow-500/10' },
            { label: 'Level', value: user.level, icon: TrendingUp, color: 'text-indigo-400', bg: 'bg-indigo-500/10' },
            { label: 'Games', value: 24, icon: Gamepad2, color: 'text-green-400', bg: 'bg-green-500/10' },
            { label: 'Rank', value: '#412', icon: Trophy, color: 'text-orange-400', bg: 'bg-orange-500/10' },
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
            <span className="text-xs text-zinc-500 font-bold">{user.xp} / 1000 XP</span>
          </div>
          <Progress value={(user.xp / 1000) * 100} className="h-2 bg-white/10" />
          <div className="mt-1.5 text-xs text-zinc-500">{1000 - user.xp} XP to Level {user.level + 1}</div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main */}
          <div className="lg:col-span-2 space-y-6">
            {/* Live */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-black text-lg flex items-center gap-2">
                  <span className="w-2 h-2 bg-red-500 rounded-full animate-pulse" /> Live Now
                </h2>
                <Link href="/live" className="text-xs text-zinc-500 hover:text-white flex items-center gap-1 transition-colors">
                  See all <ChevronRight className="w-3 h-3" />
                </Link>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {[
                  { title: 'Global Trivia Night', viewers: '1.2k', host: 'xXProGamerXx', bg: 'from-indigo-900 to-purple-900', href: '/live/session-1' },
                  { title: 'Speed Run Challenge', viewers: '890', host: 'SpeedKing99', bg: 'from-rose-900 to-pink-900', href: '/live/session-2' },
                ].map((s) => (
                  <Link href={s.href} key={s.href}>
                    <motion.div whileHover={{ scale: 1.02, y: -2 }} whileTap={{ scale: 0.98 }}
                      className={`relative aspect-video rounded-2xl overflow-hidden bg-gradient-to-br ${s.bg} border border-white/5 cursor-pointer`}>
                      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent" />
                      <div className="absolute top-3 left-3 flex items-center gap-2">
                        <Badge className="bg-red-500 text-white border-none text-[10px] animate-pulse px-2">LIVE</Badge>
                        <span className="text-[10px] text-white/70 flex items-center gap-1"><Users className="w-3 h-3" /> {s.viewers}</span>
                      </div>
                      <div className="absolute bottom-3 left-3">
                        <div className="font-bold text-sm">{s.title}</div>
                        <div className="text-xs text-zinc-400">by {s.host}</div>
                      </div>
                      <div className="absolute top-3 right-3 w-8 h-8 bg-white/10 backdrop-blur-sm rounded-full flex items-center justify-center">
                        <Play className="w-4 h-4 fill-white text-white" />
                      </div>
                    </motion.div>
                  </Link>
                ))}
              </div>
            </div>

            {/* Quick Games */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-black text-lg flex items-center gap-2"><Zap className="w-5 h-5 text-yellow-400" /> Quick Games</h2>
                <Link href="/games" className="text-xs text-zinc-500 hover:text-white flex items-center gap-1 transition-colors">All <ChevronRight className="w-3 h-3" /></Link>
              </div>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {QUICK_GAMES.map((g) => (
                  <Link href={g.href} key={g.name}>
                    <motion.div whileHover={{ y: -4 }} whileTap={{ scale: 0.97 }}
                      className={`border ${g.border} rounded-2xl p-4 flex flex-col gap-2 cursor-pointer group hover:border-white/20 transition-all`}>
                      <span className="text-2xl">{g.icon}</span>
                      <div className="font-bold text-sm">{g.name}</div>
                      <div className="text-[11px] text-zinc-500 flex items-center gap-1"><Users className="w-3 h-3" />{g.players}</div>
                      <button className="mt-1 text-[11px] font-black text-white bg-white/10 rounded-lg py-1.5 group-hover:bg-white/20 transition-colors">PLAY</button>
                    </motion.div>
                  </Link>
                ))}
              </div>
            </div>
          </div>

          {/* Sidebar content */}
          <div className="space-y-5">
            <div className="bg-gradient-to-br from-indigo-600/20 to-purple-600/20 border border-indigo-500/30 rounded-2xl p-5">
              <div className="flex items-center gap-2 mb-2">
                <Flame className="w-5 h-5 text-orange-400" />
                <span className="font-black text-sm">Weekly Challenge</span>
              </div>
              <p className="text-zinc-400 text-sm mb-3">Win 5 quizzes → <span className="text-yellow-400 font-bold">+500 coins</span></p>
              <Progress value={40} className="h-1.5 bg-white/10 mb-2" />
              <div className="flex justify-between text-xs text-zinc-500">
                <span className="flex items-center gap-1"><Clock className="w-3 h-3" /> 3 days left</span>
                <span>2/5</span>
              </div>
            </div>

            {/* Achievements */}
            <div className="bg-white/[0.03] border border-white/5 rounded-2xl p-5">
              <h3 className="font-black text-sm mb-3 flex items-center gap-2"><Trophy className="w-4 h-4 text-yellow-400" /> Achievements</h3>
              <div className="grid grid-cols-2 gap-2">
                {[{ icon: '🏆', label: 'First Victory', earned: true }, { icon: '⚡', label: 'Speed Demon', earned: true }, { icon: '🎯', label: 'Sharp Shooter', earned: false }, { icon: '🌟', label: 'Rising Star', earned: false }].map((a) => (
                  <div key={a.label} className={`flex flex-col items-center gap-1 p-3 rounded-xl border text-center ${a.earned ? 'border-yellow-500/30 bg-yellow-500/10' : 'border-white/5 opacity-40'}`}>
                    <span className="text-xl">{a.icon}</span>
                    <span className="text-[10px] font-bold text-zinc-400 leading-tight">{a.label}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Leaderboard teaser */}
            <Link href="/leaderboard">
              <motion.div whileHover={{ scale: 1.01 }} className="bg-white/[0.03] border border-white/5 rounded-2xl p-5 cursor-pointer hover:border-white/10 transition-all group">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-black text-sm">Top Players</h3>
                  <ArrowRight className="w-4 h-4 text-zinc-600 group-hover:text-white transition-colors" />
                </div>
                {TOP_PLAYERS.map((name, i) => (
                  <div key={name} className="flex items-center gap-3 py-2 border-b border-white/5 last:border-0">
                    <span className="text-xs font-black text-zinc-600 w-4">#{i + 1}</span>
                    <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-xs font-black">{name[0]}</div>
                    <span className="text-sm font-bold flex-1">{name}</span>
                    <span className="text-xs text-zinc-500">{(3 - i) * 1240}pts</span>
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
