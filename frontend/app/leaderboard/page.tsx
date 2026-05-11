'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Trophy, Medal, Crown, TrendingUp, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import axios from 'axios';
import { useAuthStore } from '@/app/lib/store';

interface LeaderboardEntry {
  username: string;
  score: number;
}

export default function LeaderboardPage() {
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { token } = useAuthStore();

  useEffect(() => {
    const fetchLeaderboard = async () => {
      try {
        const res = await axios.get('http://localhost:8080/api/v1/leaderboard/global?limit=50', {
          headers: { Authorization: `Bearer ${token}` }
        });
        setEntries(res.data);
      } catch (error) {
        console.error('Failed to fetch leaderboard', error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchLeaderboard();
  }, [token]);

  const topThree = entries.slice(0, 3);
  const rest = entries.slice(3);

  return (
    <div className="min-h-screen bg-black text-white p-6 lg:p-10">
      <div className="max-w-4xl mx-auto space-y-10">
        
        <header className="text-center space-y-4">
          <motion.div 
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-20 h-20 bg-yellow-500/20 rounded-full flex items-center justify-center mx-auto border border-yellow-500/40 shadow-[0_0_30px_rgba(234,179,8,0.2)]"
          >
            <Trophy className="w-10 h-10 text-yellow-500" />
          </motion.div>
          <h1 className="text-4xl font-black font-heading tracking-tighter">GLOBAL LEGENDS</h1>
          <p className="text-zinc-500 max-w-md mx-auto">The elite players of REWIFY. Can you climb to the top of the hall of fame?</p>
        </header>

        {/* Podium */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-end pb-10">
          {/* Second Place */}
          {topThree[1] && (
            <motion.div 
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="order-2 md:order-1"
            >
              <Card className="bg-zinc-900 border-zinc-800 text-center pt-10 pb-6 relative overflow-hidden group">
                <div className="absolute top-0 inset-x-0 h-1 bg-zinc-400/50" />
                <Avatar className="w-20 h-20 mx-auto border-4 border-zinc-400/30">
                   <AvatarFallback className="bg-zinc-800 text-xl font-bold">{topThree[1].username[0]}</AvatarFallback>
                </Avatar>
                <div className="mt-4">
                  <h3 className="font-bold text-lg">{topThree[1].username}</h3>
                  <p className="text-zinc-400 font-medium">{topThree[1].score} XP</p>
                </div>
                <div className="mt-4 inline-flex items-center gap-2 bg-zinc-800 px-4 py-1 rounded-full text-xs font-bold text-zinc-400">
                  <Medal className="w-3 h-3" /> 2ND PLACE
                </div>
              </Card>
            </motion.div>
          )}

          {/* First Place */}
          {topThree[0] && (
            <motion.div 
              initial={{ y: -20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              className="order-1 md:order-2"
            >
              <Card className="bg-zinc-900 border-indigo-500/50 text-center pt-14 pb-10 relative overflow-hidden shadow-[0_20px_50px_rgba(79,70,229,0.15)] group">
                <div className="absolute top-0 inset-x-0 h-2 bg-indigo-500" />
                <div className="absolute -top-4 -right-4 w-24 h-24 bg-indigo-500/10 rounded-full blur-2xl group-hover:bg-indigo-500/20 transition-all" />
                <div className="relative inline-block">
                   <Crown className="w-8 h-8 text-yellow-500 absolute -top-8 left-1/2 -translate-x-1/2 animate-bounce" />
                   <Avatar className="w-28 h-28 mx-auto border-4 border-indigo-500 ring-4 ring-indigo-500/20">
                      <AvatarFallback className="bg-zinc-800 text-2xl font-black">{topThree[0].username[0]}</AvatarFallback>
                   </Avatar>
                </div>
                <div className="mt-6">
                  <h3 className="font-black text-2xl tracking-tight">{topThree[0].username}</h3>
                  <p className="text-indigo-400 font-bold text-xl">{topThree[0].score} XP</p>
                </div>
                <div className="mt-6 inline-flex items-center gap-2 bg-indigo-500 px-6 py-2 rounded-full text-sm font-black text-white shadow-lg shadow-indigo-500/20">
                  REALTIVE CHAMPION
                </div>
              </Card>
            </motion.div>
          )}

          {/* Third Place */}
          {topThree[2] && (
            <motion.div 
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.2 }}
              className="order-3"
            >
              <Card className="bg-zinc-900 border-zinc-800 text-center pt-10 pb-6 relative overflow-hidden group">
                <div className="absolute top-0 inset-x-0 h-1 bg-amber-700/50" />
                <Avatar className="w-20 h-20 mx-auto border-4 border-amber-700/30">
                   <AvatarFallback className="bg-zinc-800 text-xl font-bold">{topThree[2].username[0]}</AvatarFallback>
                </Avatar>
                <div className="mt-4">
                  <h3 className="font-bold text-lg">{topThree[2].username}</h3>
                  <p className="text-zinc-400 font-medium">{topThree[2].score} XP</p>
                </div>
                <div className="mt-4 inline-flex items-center gap-2 bg-zinc-800 px-4 py-1 rounded-full text-xs font-bold text-amber-600">
                  <Medal className="w-3 h-3" /> 3RD PLACE
                </div>
              </Card>
            </motion.div>
          )}
        </div>

        {/* Search & List */}
        <div className="space-y-4">
           <div className="relative">
              <Search className="w-5 h-5 text-zinc-500 absolute left-4 top-1/2 -translate-y-1/2" />
              <Input 
                placeholder="Search players..." 
                className="bg-zinc-900 border-zinc-800 pl-12 h-14 rounded-2xl focus:ring-indigo-500"
              />
           </div>

           <Card className="bg-zinc-900 border-zinc-800 overflow-hidden">
              <div className="divide-y divide-zinc-800">
                {rest.length > 0 ? rest.map((entry, i) => (
                  <motion.div 
                    key={entry.username}
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    className="flex items-center justify-between p-4 hover:bg-zinc-800/50 transition-colors"
                  >
                    <div className="flex items-center gap-4">
                      <span className="text-zinc-500 font-bold w-6">{i + 4}</span>
                      <Avatar className="w-10 h-10 border border-zinc-700">
                        <AvatarFallback className="bg-zinc-800 text-sm">{entry.username[0]}</AvatarFallback>
                      </Avatar>
                      <span className="font-bold">{entry.username}</span>
                    </div>
                    <div className="flex items-center gap-6">
                       <div className="text-right">
                          <p className="font-bold text-white">{entry.score}</p>
                          <p className="text-[10px] text-zinc-500 uppercase font-black">TOTAL XP</p>
                       </div>
                       <TrendingUp className="w-4 h-4 text-green-500" />
                    </div>
                  </motion.div>
                )) : (
                  <div className="p-20 text-center space-y-4">
                     <p className="text-zinc-500 font-medium">No other legends found yet...</p>
                  </div>
                )}
              </div>
           </Card>
        </div>
      </div>
    </div>
  );
}
