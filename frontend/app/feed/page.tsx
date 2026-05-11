'use client';

import { useRef } from 'react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Heart, MessageCircle, Share2, Play, Plus, Zap, Music2, Trophy, Flame } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';

interface FeedItem {
  id: number;
  author: string;
  avatar: string;
  content: string;
  likes: string;
  comments: string;
  shares: string;
  category: string;
  isLive: boolean;
  music?: string;
}

const MOCK_FEED: FeedItem[] = [
  {
    id: 1,
    author: 'GamerLegend',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=GamerLegend',
    content: 'Just reached Master Rank in Global Trivia! 🔥 #RewifyArena #Gaming',
    likes: '45.2K',
    comments: '1.2K',
    shares: '8.4K',
    category: 'Gaming',
    isLive: true,
    music: 'Original Sound - GamerLegend'
  },
  {
    id: 2,
    author: 'TriviaQueen',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=TriviaQueen',
    content: 'Who can beat my score in Science Quiz? Join the live arena now! 🧪✨',
    likes: '12.8K',
    comments: '840',
    shares: '2.1K',
    category: 'Education',
    isLive: true,
    music: 'Science Vibes - StudyBeats'
  },
  {
    id: 3,
    author: 'RewifyOfficial',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Rewify',
    content: 'New Season Items are here! Check the marketplace for legendary skins. 💎',
    likes: '102K',
    comments: '5.6K',
    shares: '24K',
    category: 'Official',
    isLive: false,
    music: 'Rewify Theme - Electronic'
  }
];

export default function FeedPage() {
  const containerRef = useRef<HTMLDivElement>(null);

  const handleShare = (author: string) => {
    navigator.clipboard.writeText(`Check out ${author}'s stream on REWIFY!`);
    toast.success('Link copied to clipboard!');
  };

  return (
    <div className="h-screen w-full bg-black overflow-hidden flex flex-col md:flex-row">
      
      {/* Desktop Sidebar (Optional/Hidden on Mobile) */}
      <aside className="hidden md:flex w-24 bg-zinc-950 border-r border-zinc-800 flex-col items-center py-10 gap-10">
         <div className="w-12 h-12 bg-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-indigo-600/20">
            <Zap className="w-8 h-8 text-white fill-white" />
         </div>
         <nav className="flex flex-col gap-8">
            <button className="p-3 text-white hover:bg-zinc-900 rounded-2xl transition-colors"><Trophy className="w-6 h-6" /></button>
            <button className="p-3 text-zinc-500 hover:bg-zinc-900 rounded-2xl transition-colors"><Flame className="w-6 h-6" /></button>
            <button className="p-3 text-zinc-500 hover:bg-zinc-900 rounded-2xl transition-colors"><MessageCircle className="w-6 h-6" /></button>
         </nav>
      </aside>

      {/* Main Swipe Container */}
      <div 
        ref={containerRef}
        className="flex-1 h-full overflow-y-scroll snap-y snap-mandatory hide-scrollbar"
      >
        {MOCK_FEED.map((item) => (
          <section 
            key={item.id}
            className="h-full w-full snap-start relative flex items-center justify-center bg-zinc-900"
          >
            {/* Background Content (Video Placeholder) */}
            <div className="absolute inset-0 bg-linear-to-b from-black/40 via-transparent to-black/80 z-10" />
            <div className="w-full h-full relative overflow-hidden">
               {/* Animated Background Placeholder */}
               <div className={`absolute inset-0 bg-linear-to-br transition-all duration-1000 ${item.id % 2 === 0 ? 'from-indigo-900/40 to-purple-900/40' : 'from-zinc-900 to-black'}`} />
               <Play className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-20 h-20 text-white/10" />
            </div>

            {/* Interaction Buttons (Right Side) */}
            <div className="absolute right-4 bottom-32 z-30 flex flex-col items-center gap-6">
               <div className="relative mb-2">
                  <Avatar className="w-12 h-12 border-2 border-white ring-2 ring-indigo-500 p-0.5">
                     <AvatarImage src={item.avatar} />
                     <AvatarFallback>{item.author[0]}</AvatarFallback>
                  </Avatar>
                  <button className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center border-2 border-black">
                     <Plus className="w-3 h-3 text-white" />
                  </button>
               </div>

               <button className="flex flex-col items-center gap-1 group">
                  <div className="w-12 h-12 bg-black/40 backdrop-blur-md rounded-full flex items-center justify-center group-hover:bg-red-500/20 transition-all">
                     <Heart className="w-7 h-7 text-white group-hover:text-red-500 group-hover:fill-red-500 transition-all" />
                  </div>
                  <span className="text-[10px] font-black">{item.likes}</span>
               </button>

               <button className="flex flex-col items-center gap-1 group">
                  <div className="w-12 h-12 bg-black/40 backdrop-blur-md rounded-full flex items-center justify-center group-hover:bg-indigo-500/20 transition-all">
                     <MessageCircle className="w-7 h-7 text-white group-hover:text-indigo-400 transition-all" />
                  </div>
                  <span className="text-[10px] font-black">{item.comments}</span>
               </button>

               <button onClick={() => handleShare(item.author)} className="flex flex-col items-center gap-1 group">
                  <div className="w-12 h-12 bg-black/40 backdrop-blur-md rounded-full flex items-center justify-center group-hover:bg-green-500/20 transition-all">
                     <Share2 className="w-7 h-7 text-white group-hover:text-green-400 transition-all" />
                  </div>
                  <span className="text-[10px] font-black">{item.shares}</span>
               </button>
               
               {/* Music Disk Animation */}
               <div className="w-12 h-12 bg-zinc-800 rounded-full border-4 border-zinc-700 mt-4 animate-spin-slow overflow-hidden flex items-center justify-center">
                  <div className="w-4 h-4 bg-zinc-600 rounded-full border-2 border-zinc-500" />
               </div>
            </div>

            {/* Content Overlay (Bottom Left) */}
            <div className="absolute left-4 bottom-10 z-30 max-w-[80%] space-y-4">
               <div className="flex items-center gap-2">
                  <h3 className="text-lg font-black tracking-tight">{item.author}</h3>
                  {item.isLive && (
                    <Badge className="bg-red-500 animate-pulse border-none text-[10px] h-5">LIVE</Badge>
                  )}
               </div>
               <p className="text-sm font-medium leading-relaxed drop-shadow-lg">
                  {item.content}
               </p>
               <div className="flex items-center gap-2 text-xs font-bold text-zinc-300">
                  <Music2 className="w-4 h-4 animate-bounce" />
                  <span className="overflow-hidden whitespace-nowrap marquee">
                     {item.music}
                  </span>
               </div>
            </div>
          </section>
        ))}
      </div>

      {/* Bottom Tab Bar (Mobile) */}
      <nav className="md:hidden fixed bottom-0 inset-x-0 bg-black/80 backdrop-blur-2xl border-t border-zinc-800/50 p-4 flex justify-around z-50">
         <button className="text-white"><Zap className="w-6 h-6 fill-white" /></button>
         <button className="text-zinc-500"><Trophy className="w-6 h-6" /></button>
         <div className="relative -top-8">
            <button className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-[0_0_20px_rgba(255,255,255,0.3)] border-4 border-black">
               <Plus className="w-8 h-8 text-black" />
            </button>
         </div>
         <button className="text-zinc-500"><MessageCircle className="w-6 h-6" /></button>
         <button className="text-zinc-500">
            <Avatar className="w-6 h-6 border border-zinc-800">
               <AvatarFallback className="text-[8px]">ME</AvatarFallback>
            </Avatar>
         </button>
      </nav>

      {/* Mobile Top Header */}
      <header className="md:hidden fixed top-0 inset-x-0 p-4 flex justify-center gap-6 z-50">
         <button className="text-sm font-black tracking-tighter text-zinc-400">Following</button>
         <button className="text-sm font-black tracking-tighter text-white border-b-2 border-white pb-1">For You</button>
      </header>

    </div>
  );
}
