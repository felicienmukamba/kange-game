'use client';

import { useAuthStore } from '@/app/lib/store';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { motion } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Gamepad2, Play, Trophy, Users, Zap, TrendingUp, Star } from 'lucide-react';
import Link from 'next/link';

export default function DashboardPage() {
  const { user, logout } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    if (!user) {
      router.push('/auth');
    }
  }, [user, router]);

  if (!user) return null;

  return (
    <div className="min-h-screen bg-black text-white p-6 lg:p-10">
      <div className="max-w-7xl mx-auto space-y-10">
        
        {/* Header Section */}
        <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="flex items-center gap-4">
            <Avatar className="h-20 w-20 border-2 border-indigo-500 p-1">
              <AvatarImage src={user.avatar} />
              <AvatarFallback className="bg-zinc-800 text-2xl">{user.username[0].toUpperCase()}</AvatarFallback>
            </Avatar>
            <div>
              <h1 className="text-3xl font-bold font-heading">Welcome back, {user.username}!</h1>
              <div className="flex items-center gap-2 mt-1">
                <Badge variant="outline" className="bg-indigo-500/10 text-indigo-400 border-indigo-500/20">Level {user.level}</Badge>
                <span className="text-zinc-500 text-sm">{user.role}</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <div className="text-sm text-zinc-500 uppercase tracking-wider font-semibold">Balance</div>
              <div className="text-2xl font-bold flex items-center gap-2 justify-end">
                <Star className="w-5 h-5 text-yellow-500 fill-yellow-500" /> {user.coins}
              </div>
            </div>
            <Button variant="outline" onClick={logout} className="border-zinc-800 hover:bg-zinc-900">Logout</Button>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Stats Section */}
          <div className="lg:col-span-1 space-y-6">
            <Card className="bg-zinc-900/50 border-zinc-800 backdrop-blur-md">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <TrendingUp className="w-5 h-5 text-indigo-400" /> Progress
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-zinc-400">XP to next level</span>
                    <span className="text-white font-medium">{user.xp}/1000</span>
                  </div>
                  <Progress value={(user.xp / 1000) * 100} className="h-2 bg-zinc-800" />
                </div>
                <div className="grid grid-cols-2 gap-4 pt-4">
                  <div className="bg-zinc-800/50 p-4 rounded-xl text-center">
                    <div className="text-zinc-500 text-xs uppercase mb-1">Rank</div>
                    <div className="text-xl font-bold">#412</div>
                  </div>
                  <div className="bg-zinc-800/50 p-4 rounded-xl text-center">
                    <div className="text-zinc-500 text-xs uppercase mb-1">Games</div>
                    <div className="text-xl font-bold">24</div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-indigo-600/10 border-indigo-500/20">
               <CardContent className="p-6">
                 <div className="flex items-center gap-4">
                   <div className="p-3 bg-indigo-600 rounded-lg">
                     <Trophy className="w-6 h-6 text-white" />
                   </div>
                   <div>
                     <div className="text-indigo-300 font-semibold">Weekly Challenge</div>
                     <div className="text-sm text-indigo-200/70">Win 5 quizzes to get 500 bonus coins!</div>
                   </div>
                 </div>
               </CardContent>
            </Card>
          </div>

          {/* Main Content Section */}
          <div className="lg:col-span-2 space-y-8">
            <div>
              <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
                <Play className="w-5 h-5 text-green-400" /> Live Now
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[1, 2].map((i) => (
                  <motion.div
                    key={i}
                    whileHover={{ scale: 1.02 }}
                    className="group relative aspect-video rounded-2xl overflow-hidden bg-zinc-900 border border-zinc-800"
                  >
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent z-10" />
                    <div className="absolute top-4 left-4 z-20">
                      <Badge className="bg-red-500 text-white border-none animate-pulse">LIVE</Badge>
                    </div>
                    <div className="absolute bottom-4 left-4 z-20">
                      <div className="text-lg font-bold">Global Trivia Night #{i}</div>
                      <div className="text-sm text-zinc-400 flex items-center gap-2">
                        <Users className="w-4 h-4" /> 1.2k viewers
                      </div>
                    </div>
                    <Link href={`/live/session-${i}`} className="absolute inset-0 z-30" />
                  </motion.div>
                ))}
              </div>
            </div>

            <div>
              <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
                <Zap className="w-5 h-5 text-yellow-400" /> Quick Games
              </h2>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {['Quiz Battle', 'Speed Math', 'Word Rush'].map((game) => (
                  <Card key={game} className="bg-zinc-900 border-zinc-800 hover:border-zinc-700 transition-colors cursor-pointer group">
                    <CardContent className="p-4 flex flex-col items-center text-center space-y-3">
                      <div className="p-4 bg-zinc-800 rounded-2xl group-hover:bg-indigo-500/20 transition-colors">
                        <Gamepad2 className="w-8 h-8 text-indigo-400" />
                      </div>
                      <div className="font-semibold">{game}</div>
                      <Button variant="ghost" size="sm" className="w-full text-xs hover:bg-zinc-800">Play Now</Button>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
