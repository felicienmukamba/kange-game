'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card } from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Heart, MessageCircle, Share2, Play, Plus, Zap } from 'lucide-react';
import { Badge } from '@/components/ui/badge';

export default function FeedPage() {
  const [posts, setPosts] = useState([
    {
      id: 1,
      author: 'GamerX',
      content: 'Just won the global trivia! #winning #rewify',
      likes: 1240,
      comments: 45,
      role: 'PRO PLAYER',
    },
    {
      id: 2,
      author: 'StreamQueen',
      content: 'Live in 5 mins! Don\'t miss the battle. 🎮',
      likes: 850,
      comments: 12,
      role: 'STREAMER',
    }
  ]);

  return (
    <div className="min-h-screen bg-black text-white pb-20">
      <header className="sticky top-0 z-50 bg-black/60 backdrop-blur-xl border-b border-zinc-800 p-4 flex items-center justify-between">
        <h1 className="text-xl font-bold font-heading">Feed</h1>
        <div className="flex gap-2">
           <Button size="icon" variant="ghost" className="rounded-full bg-zinc-900"><Plus className="w-5 h-5" /></Button>
           <Button size="icon" variant="ghost" className="rounded-full bg-zinc-900"><Zap className="w-5 h-5 text-yellow-400" /></Button>
        </div>
      </header>

      <div className="max-w-2xl mx-auto space-y-6 p-4">
        {posts.map((post) => (
          <motion.div
            key={post.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="group"
          >
            <Card className="bg-zinc-900/50 border-zinc-800 overflow-hidden rounded-2xl shadow-xl">
               <div className="p-4 flex items-center gap-3">
                 <Avatar className="border-2 border-indigo-500/50">
                   <AvatarImage src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${post.author}`} />
                   <AvatarFallback>{post.author[0]}</AvatarFallback>
                 </Avatar>
                 <div>
                   <div className="flex items-center gap-2">
                     <span className="font-bold">{post.author}</span>
                     <Badge variant="secondary" className="text-[10px] bg-zinc-800 text-zinc-400">{post.role}</Badge>
                   </div>
                   <span className="text-xs text-zinc-500">2 hours ago</span>
                 </div>
               </div>

               <div className="px-4 pb-4">
                 <p className="text-zinc-300 leading-relaxed">{post.content}</p>
               </div>

               {/* Post Media Placeholder */}
               <div className="aspect-[4/5] bg-zinc-950 relative flex items-center justify-center group-hover:bg-zinc-900 transition-colors">
                  <Play className="w-16 h-16 text-white/20 group-hover:text-indigo-500/40 transition-colors" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
               </div>

               <div className="p-4 flex items-center justify-between">
                 <div className="flex items-center gap-6">
                   <button className="flex items-center gap-2 text-zinc-400 hover:text-red-500 transition-colors">
                     <Heart className="w-6 h-6" /> <span className="text-sm font-medium">{post.likes}</span>
                   </button>
                   <button className="flex items-center gap-2 text-zinc-400 hover:text-indigo-400 transition-colors">
                     <MessageCircle className="w-6 h-6" /> <span className="text-sm font-medium">{post.comments}</span>
                   </button>
                 </div>
                 <button className="text-zinc-400 hover:text-white transition-colors">
                   <Share2 className="w-6 h-6" />
                 </button>
               </div>
            </Card>
          </motion.div>
        ))}
      </div>

      {/* Bottom Tab Bar (Mobile style) */}
      <nav className="fixed bottom-0 inset-x-0 bg-black/80 backdrop-blur-2xl border-t border-zinc-800 p-3 flex justify-around z-50">
         <button className="flex flex-col items-center gap-1 text-white">
           <Zap className="w-6 h-6" />
           <span className="text-[10px] font-bold">Discover</span>
         </button>
         <button className="flex flex-col items-center gap-1 text-zinc-500">
           <Play className="w-6 h-6" />
           <span className="text-[10px] font-bold">Live</span>
         </button>
         <button className="flex flex-col items-center gap-1 text-zinc-500">
           <Trophy className="w-6 h-6" />
           <span className="text-[10px] font-bold">Arena</span>
         </button>
         <button className="flex flex-col items-center gap-1 text-zinc-500">
           <Avatar className="w-6 h-6">
             <AvatarFallback className="text-[8px]">ME</AvatarFallback>
           </Avatar>
           <span className="text-[10px] font-bold">Profile</span>
         </button>
      </nav>
    </div>
  );
}
