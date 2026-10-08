'use client';

import { useCallback, useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Heart, RefreshCw, Trash2, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import AppLayout from '@/components/AppLayout';
import { useAuthStore } from '@/app/lib/store';
import { api, apiError, timeAgo, type PostView } from '@/app/lib/api';

const MAX_LENGTH = 1000;

const ROLE_BADGE: Record<string, string> = {
  STREAMER: 'text-red-400 bg-red-500/10',
  CREATOR: 'text-purple-400 bg-purple-500/10',
  ADMIN: 'text-yellow-400 bg-yellow-500/10',
  MODERATOR: 'text-blue-400 bg-blue-500/10',
  PLAYER: 'text-indigo-400 bg-indigo-500/10',
};

export default function FeedPage() {
  const { user } = useAuthStore();
  const [posts, setPosts] = useState<PostView[]>([]);
  const [loading, setLoading] = useState(true);
  const [newPost, setNewPost] = useState('');
  const [posting, setPosting] = useState(false);

  const fetchFeed = useCallback(() =>
    api.get<PostView[]>('/social/feed')
      .then((res) => setPosts(res.data))
      .catch((error) => toast.error(apiError(error, 'Could not load the feed')))
      .finally(() => setLoading(false)), []);

  const load = () => {
    setLoading(true);
    fetchFeed();
  };

  useEffect(() => { fetchFeed(); }, [fetchFeed]);

  const submit = async () => {
    if (!newPost.trim()) return;
    setPosting(true);
    try {
      const res = await api.post<PostView>('/social/posts', { content: newPost });
      setPosts((prev) => [res.data, ...prev]);
      setNewPost('');
    } catch (error) {
      toast.error(apiError(error, 'Could not publish your post'));
    } finally {
      setPosting(false);
    }
  };

  const toggleLike = async (id: number) => {
    // Optimistic update, reconciled with the server response
    setPosts((prev) => prev.map((p) => p.id === id ? { ...p, likedByMe: !p.likedByMe, likes: p.likes + (p.likedByMe ? -1 : 1) } : p));
    try {
      const res = await api.post<PostView>(`/social/posts/${id}/like`);
      setPosts((prev) => prev.map((p) => (p.id === id ? res.data : p)));
    } catch (error) {
      toast.error(apiError(error));
      load();
    }
  };

  const remove = async (id: number) => {
    try {
      await api.delete(`/social/posts/${id}`);
      setPosts((prev) => prev.filter((p) => p.id !== id));
      toast.success('Post deleted');
    } catch (error) {
      toast.error(apiError(error));
    }
  };

  const canDelete = (p: PostView) => p.author.id === user?.id || user?.role === 'ADMIN' || user?.role === 'MODERATOR';

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-8 space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Community</div>
            <h1 className="text-3xl font-black tracking-tighter">Social Feed</h1>
          </div>
          <button
            onClick={load}
            className="flex items-center gap-2 px-4 py-2.5 bg-white/5 border border-white/10 text-zinc-300 font-bold rounded-xl hover:bg-white/10 transition-all text-sm"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
          </button>
        </div>

        {/* Post Composer */}
        <div className="bg-white/[0.03] border border-white/8 rounded-2xl p-4 space-y-3">
          <div className="flex items-start gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-lg font-black flex-shrink-0">
              {user?.avatar ?? user?.username?.[0]?.toUpperCase()}
            </div>
            <textarea
              value={newPost}
              onChange={(e) => setNewPost(e.target.value.slice(0, MAX_LENGTH))}
              onKeyDown={(e) => { if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) submit(); }}
              placeholder="Share something with the arena..."
              rows={2}
              className="flex-1 bg-transparent text-white placeholder:text-zinc-600 text-sm outline-none resize-none pt-2"
            />
          </div>
          <div className="flex items-center justify-between pt-1 border-t border-white/5">
            <div className="flex gap-2 items-center">
              {['🎮', '🏆', '🔥', '💎'].map((emoji) => (
                <button key={emoji} onClick={() => setNewPost((t) => (t + emoji).slice(0, MAX_LENGTH))} className="text-lg hover:scale-110 transition-transform" aria-label={`Add ${emoji}`}>
                  {emoji}
                </button>
              ))}
              <span className="text-[11px] text-zinc-600 ml-2">{newPost.length}/{MAX_LENGTH}</span>
            </div>
            <button
              onClick={submit}
              disabled={!newPost.trim() || posting}
              className="px-5 py-2 bg-white text-black font-black rounded-xl text-sm disabled:opacity-30 hover:bg-zinc-100 transition-all flex items-center gap-2"
            >
              {posting && <Loader2 className="w-3.5 h-3.5 animate-spin" />} POST
            </button>
          </div>
        </div>

        {/* Posts */}
        <div className="space-y-4">
          {loading && posts.length === 0 && (
            <div className="flex justify-center py-12"><Loader2 className="w-6 h-6 animate-spin text-zinc-600" /></div>
          )}
          {!loading && posts.length === 0 && (
            <div className="text-center text-zinc-500 text-sm py-12 border border-dashed border-white/10 rounded-2xl">
              No posts yet — be the first to share something!
            </div>
          )}
          <AnimatePresence initial={false}>
            {posts.map((post, i) => (
              <motion.div
                key={post.id}
                layout
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ delay: Math.min(i, 5) * 0.05 }}
                className="bg-white/[0.03] border border-white/5 rounded-2xl overflow-hidden hover:border-white/10 transition-all"
              >
                <div className="flex items-center justify-between p-4 pb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-zinc-800 flex items-center justify-center text-xl">
                      {post.author.avatar ?? post.author.username[0].toUpperCase()}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-sm">{post.author.username}</span>
                        <span className={`text-[9px] font-black px-1.5 py-0.5 rounded-full ${ROLE_BADGE[post.author.role] ?? ROLE_BADGE.PLAYER}`}>
                          {post.author.role}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-[11px] text-zinc-500">
                        <span>Lv.{post.author.level}</span>
                        <span>·</span>
                        <span>{timeAgo(post.createdAt)}</span>
                      </div>
                    </div>
                  </div>
                  {canDelete(post) && (
                    <button onClick={() => remove(post.id)} className="text-zinc-600 hover:text-red-400 transition-colors" aria-label="Delete post">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>

                <div className="px-4 pb-3">
                  <p className="text-sm text-zinc-300 leading-relaxed whitespace-pre-wrap break-words">{post.content}</p>
                </div>

                {post.mediaUrl && (
                  <div className="mx-4 mb-3 rounded-xl overflow-hidden aspect-video bg-zinc-900">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={post.mediaUrl} alt="" className="w-full h-full object-cover" />
                  </div>
                )}

                <div className="flex items-center px-4 py-3 border-t border-white/5">
                  <button
                    onClick={() => toggleLike(post.id)}
                    className={`flex items-center gap-1.5 text-sm font-bold transition-all hover:scale-105 ${post.likedByMe ? 'text-red-400' : 'text-zinc-500 hover:text-white'}`}
                    aria-pressed={post.likedByMe}
                  >
                    <Heart className={`w-4 h-4 ${post.likedByMe ? 'fill-red-400' : ''}`} />
                    {post.likes}
                  </button>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </div>
    </AppLayout>
  );
}
