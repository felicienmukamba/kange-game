'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Heart, MessageCircle, Share2, Bookmark, MoreHorizontal, Flame, Zap, Users, Plus } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import { useAuthStore } from '@/app/lib/store';

const POSTS = [
  {
    id: 1,
    user: { name: 'Shadow_X', avatar: '🥷', badge: 'PRO', level: 42 },
    time: '2m ago',
    content: 'Just hit a 20-win streak in Quiz Battle 🔥 The grind never stops. Who wants to challenge me?',
    image: null,
    likes: 248,
    comments: 34,
    shares: 12,
    liked: false,
    tag: 'Gaming',
    tagColor: 'text-indigo-400 bg-indigo-500/10',
  },
  {
    id: 2,
    user: { name: 'NeonByte', avatar: '🤖', badge: 'CREATOR', level: 38 },
    time: '15m ago',
    content: 'New stream starting in 5 mins! We\'re doing a LIVE tournament with 1000 coin prize pool 💰',
    image: '/images/streaming.png',
    likes: 512,
    comments: 89,
    shares: 67,
    liked: true,
    tag: 'Live',
    tagColor: 'text-red-400 bg-red-500/10',
  },
  {
    id: 3,
    user: { name: 'CosmicAce', avatar: '🦅', badge: 'TOP 10', level: 55 },
    time: '1h ago',
    content: 'The new Marketplace drop is insane 😱 Grabbed the legendary Dragon shield before it sold out. Limited items are back, grab yours now.',
    image: '/images/marketplace.png',
    likes: 1024,
    comments: 156,
    shares: 203,
    liked: false,
    tag: 'Market',
    tagColor: 'text-green-400 bg-green-500/10',
  },
];

const STORIES = [
  { name: 'You', avatar: '➕', isAdd: true },
  { name: 'Shadow_X', avatar: '🥷', active: true },
  { name: 'NeonByte', avatar: '🤖', active: true },
  { name: 'CosmicAce', avatar: '🦅', active: false },
  { name: 'SpeedKing', avatar: '⚡', active: true },
];

export default function FeedPage() {
  const { user } = useAuthStore();
  const [posts, setPosts] = useState(POSTS);
  const [newPost, setNewPost] = useState('');

  const toggleLike = (id: number) => {
    setPosts((prev) =>
      prev.map((p) => p.id === id ? { ...p, liked: !p.liked, likes: p.liked ? p.likes - 1 : p.likes + 1 } : p)
    );
  };

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-8 space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Community</div>
            <h1 className="text-3xl font-black tracking-tighter">Social Feed</h1>
          </div>
          <button className="flex items-center gap-2 px-4 py-2.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all text-sm">
            <Flame className="w-4 h-4" /> Trending
          </button>
        </div>

        {/* Stories */}
        <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
          {STORIES.map((s) => (
            <div key={s.name} className="flex flex-col items-center gap-1.5 flex-shrink-0 cursor-pointer group">
              <div className={`w-14 h-14 rounded-2xl flex items-center justify-center text-2xl transition-all group-hover:scale-105 ${
                s.isAdd ? 'bg-white/5 border-2 border-dashed border-white/20' :
                s.active ? 'ring-2 ring-indigo-500 ring-offset-2 ring-offset-black bg-zinc-900' :
                'bg-zinc-900 opacity-60'
              }`}>
                {s.avatar}
              </div>
              <span className="text-[10px] font-bold text-zinc-500 group-hover:text-white transition-colors">{s.name}</span>
            </div>
          ))}
        </div>

        {/* Post Composer */}
        <div className="bg-white/[0.03] border border-white/8 rounded-2xl p-4 space-y-3">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-lg font-black flex-shrink-0">
              {user?.username?.[0]?.toUpperCase()}
            </div>
            <input
              value={newPost}
              onChange={(e) => setNewPost(e.target.value)}
              placeholder="Share something with the arena..."
              className="flex-1 bg-transparent text-white placeholder:text-zinc-600 text-sm outline-none"
            />
          </div>
          <div className="flex items-center justify-between pt-1 border-t border-white/5">
            <div className="flex gap-2">
              {['🎮', '🏆', '📸', '🔗'].map((emoji) => (
                <button key={emoji} className="text-lg hover:scale-110 transition-transform">{emoji}</button>
              ))}
            </div>
            <button
              disabled={!newPost.trim()}
              className="px-5 py-2 bg-white text-black font-black rounded-xl text-sm disabled:opacity-30 hover:bg-zinc-100 transition-all"
            >
              POST
            </button>
          </div>
        </div>

        {/* Posts */}
        <div className="space-y-4">
          {posts.map((post, i) => (
            <motion.div
              key={post.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.08 }}
              className="bg-white/[0.03] border border-white/5 rounded-2xl overflow-hidden hover:border-white/10 transition-all"
            >
              {/* Post Header */}
              <div className="flex items-center justify-between p-4 pb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-zinc-800 flex items-center justify-center text-xl">{post.user.avatar}</div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm">{post.user.name}</span>
                      <span className={`text-[9px] font-black px-1.5 py-0.5 rounded-full ${post.tagColor}`}>{post.user.badge}</span>
                    </div>
                    <div className="flex items-center gap-2 text-[11px] text-zinc-500">
                      <span>Lv.{post.user.level}</span>
                      <span>·</span>
                      <span>{post.time}</span>
                      <span>·</span>
                      <span className={`font-bold ${post.tagColor}`}>{post.tag}</span>
                    </div>
                  </div>
                </div>
                <button className="text-zinc-600 hover:text-white transition-colors">
                  <MoreHorizontal className="w-5 h-5" />
                </button>
              </div>

              {/* Content */}
              <div className="px-4 pb-3">
                <p className="text-sm text-zinc-300 leading-relaxed">{post.content}</p>
              </div>

              {/* Image */}
              {post.image && (
                <div className="mx-4 mb-3 rounded-xl overflow-hidden aspect-video bg-zinc-900">
                  <img src={post.image} alt="" className="w-full h-full object-cover" />
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center justify-between px-4 py-3 border-t border-white/5">
                <div className="flex items-center gap-4">
                  <button
                    onClick={() => toggleLike(post.id)}
                    className={`flex items-center gap-1.5 text-sm font-bold transition-all hover:scale-105 ${post.liked ? 'text-red-400' : 'text-zinc-500 hover:text-white'}`}
                  >
                    <Heart className={`w-4 h-4 ${post.liked ? 'fill-red-400' : ''}`} />
                    {post.likes}
                  </button>
                  <button className="flex items-center gap-1.5 text-sm font-bold text-zinc-500 hover:text-white transition-colors">
                    <MessageCircle className="w-4 h-4" />{post.comments}
                  </button>
                  <button className="flex items-center gap-1.5 text-sm font-bold text-zinc-500 hover:text-white transition-colors">
                    <Share2 className="w-4 h-4" />{post.shares}
                  </button>
                </div>
                <button className="text-zinc-500 hover:text-white transition-colors">
                  <Bookmark className="w-4 h-4" />
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </AppLayout>
  );
}
