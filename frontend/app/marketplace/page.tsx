'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Search, Filter, ShoppingCart, Star, Zap, Shield, Sword, Crown } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import { useAuthStore } from '@/app/lib/store';
import { toast } from 'sonner';

const CATEGORIES = ['All', 'Weapons', 'Shields', 'Crowns', 'Avatars', 'Effects'];

const ITEMS = [
  { id: 1, name: 'Dragon Blade', icon: '⚔️', category: 'Weapons', price: 250, rarity: 'Legendary', color: 'from-orange-500/20 to-red-500/20', border: 'border-orange-500/30', badge: '🔥 HOT', sold: false },
  { id: 2, name: 'Neon Shield', icon: '🛡️', category: 'Shields', price: 120, rarity: 'Epic', color: 'from-blue-500/20 to-cyan-500/20', border: 'border-blue-500/30', badge: null, sold: false },
  { id: 3, name: 'Diamond Crown', icon: '👑', category: 'Crowns', price: 500, rarity: 'Legendary', color: 'from-yellow-500/20 to-amber-500/20', border: 'border-yellow-500/30', badge: '⚡ NEW', sold: false },
  { id: 4, name: 'Shadow Cloak', icon: '🥷', category: 'Avatars', price: 180, rarity: 'Rare', color: 'from-purple-500/20 to-violet-500/20', border: 'border-purple-500/30', badge: null, sold: true },
  { id: 5, name: 'Phoenix Wings', icon: '🦅', category: 'Effects', price: 320, rarity: 'Legendary', color: 'from-pink-500/20 to-rose-500/20', border: 'border-pink-500/30', badge: '🔥 HOT', sold: false },
  { id: 6, name: 'Thunder Bolt', icon: '⚡', category: 'Weapons', price: 95, rarity: 'Common', color: 'from-yellow-500/10 to-orange-500/10', border: 'border-yellow-500/20', badge: null, sold: false },
  { id: 7, name: 'Ice Crystal', icon: '❄️', category: 'Effects', price: 145, rarity: 'Rare', color: 'from-cyan-500/20 to-blue-500/20', border: 'border-cyan-500/30', badge: '⚡ NEW', sold: false },
  { id: 8, name: 'Gold Avatar', icon: '🤖', category: 'Avatars', price: 200, rarity: 'Epic', color: 'from-amber-500/20 to-yellow-500/20', border: 'border-amber-500/30', badge: null, sold: false },
];

const RARITY_COLORS: Record<string, string> = {
  Common: 'text-zinc-400 bg-zinc-800',
  Rare: 'text-blue-400 bg-blue-500/10',
  Epic: 'text-purple-400 bg-purple-500/10',
  Legendary: 'text-yellow-400 bg-yellow-500/10',
};

export default function MarketplacePage() {
  const { user } = useAuthStore();
  const [category, setCategory] = useState('All');
  const [search, setSearch] = useState('');
  const [cart, setCart] = useState<number[]>([]);

  const filtered = ITEMS.filter((item) => {
    const matchCat = category === 'All' || item.category === category;
    const matchSearch = item.name.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  const buy = (item: typeof ITEMS[0]) => {
    if (item.sold) return;
    if ((user?.coins ?? 0) < item.price) {
      toast.error('Not enough coins!', { description: `You need ${item.price - (user?.coins ?? 0)} more coins.` });
      return;
    }
    setCart((prev) => [...prev, item.id]);
    toast.success(`${item.name} added to cart!`, { description: `${item.price} coins will be deducted.` });
  };

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-7xl mx-auto space-y-7">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Shop</div>
            <h1 className="text-3xl font-black tracking-tighter">Marketplace</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 px-4 py-2.5 bg-yellow-500/10 border border-yellow-500/20 rounded-xl">
              <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
              <span className="font-black text-yellow-400">{user?.coins ?? 0}</span>
            </div>
            {cart.length > 0 && (
              <button
                onClick={() => { setCart([]); toast.success('Purchase complete! 🎉'); }}
                className="relative flex items-center gap-2 px-4 py-2.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all text-sm"
              >
                <ShoppingCart className="w-4 h-4" /> Checkout
                <span className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 rounded-full text-[10px] font-black flex items-center justify-center text-white">{cart.length}</span>
              </button>
            )}
          </div>
        </div>

        {/* Search + Filter */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-500" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search items..."
              className="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors"
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-sm text-zinc-400 hover:text-white hover:bg-white/8 transition-all">
            <Filter className="w-4 h-4" /> Filter
          </button>
        </div>

        {/* Categories */}
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-4 py-2 rounded-xl text-sm font-bold flex-shrink-0 transition-all ${
                category === cat ? 'bg-white text-black' : 'bg-white/5 text-zinc-400 hover:bg-white/10 hover:text-white border border-white/5'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        {/* Featured Banner */}
        <div className="relative rounded-2xl overflow-hidden bg-gradient-to-r from-indigo-600/30 to-purple-600/30 border border-indigo-500/30 p-6 flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-widest text-indigo-400 mb-1">LIMITED TIME</div>
            <h2 className="text-2xl font-black tracking-tighter">Weekend Drop 🎁</h2>
            <p className="text-zinc-400 text-sm mt-1">Legendary items at 30% off — 12h left</p>
          </div>
          <div className="text-6xl">🎉</div>
          <div className="absolute inset-0 bg-gradient-to-r from-transparent to-purple-600/10 pointer-events-none" />
        </div>

        {/* Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
          {filtered.map((item, i) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              whileHover={{ y: -4 }}
              className={`relative bg-gradient-to-br ${item.color} border ${item.border} rounded-2xl overflow-hidden group cursor-pointer ${item.sold ? 'opacity-50' : ''}`}
            >
              {item.badge && (
                <div className="absolute top-2 left-2 text-[10px] font-black bg-black/40 backdrop-blur-sm px-2 py-0.5 rounded-full text-white">
                  {item.badge}
                </div>
              )}
              {cart.includes(item.id) && (
                <div className="absolute top-2 right-2 w-6 h-6 bg-green-500 rounded-full flex items-center justify-center text-[10px]">✓</div>
              )}
              <div className="p-5 flex flex-col items-center gap-3">
                <div className="text-5xl group-hover:scale-110 transition-transform">{item.icon}</div>
                <div className="text-center">
                  <div className="font-black text-sm">{item.name}</div>
                  <span className={`text-[10px] font-black px-2 py-0.5 rounded-full ${RARITY_COLORS[item.rarity]}`}>{item.rarity}</span>
                </div>
                <button
                  onClick={() => buy(item)}
                  disabled={item.sold || cart.includes(item.id)}
                  className="w-full flex items-center justify-center gap-1.5 py-2.5 bg-black/30 hover:bg-black/50 rounded-xl text-sm font-black transition-all disabled:cursor-not-allowed border border-white/10 group-hover:border-white/20"
                >
                  {item.sold ? 'SOLD OUT' : cart.includes(item.id) ? 'ADDED ✓' : (
                    <><Star className="w-3.5 h-3.5 text-yellow-400 fill-yellow-400" /> {item.price}</>
                  )}
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </AppLayout>
  );
}
