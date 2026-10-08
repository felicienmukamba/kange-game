'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Search, Star, Loader2, Package } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import { useAuthStore, type User } from '@/app/lib/store';
import { toast } from 'sonner';
import { api, apiError, type InventoryItem, type MarketplaceItem } from '@/app/lib/api';
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog';

const CATEGORIES: { label: string; type?: string }[] = [
  { label: 'All' },
  { label: 'Weapons', type: 'WEAPON' },
  { label: 'Shields', type: 'SHIELD' },
  { label: 'Crowns', type: 'CROWN' },
  { label: 'Avatars', type: 'AVATAR' },
  { label: 'Effects', type: 'EFFECT' },
  { label: 'Owned' },
];

const RARITY: Record<string, { label: string; badge: string; card: string }> = {
  COMMON: { label: 'Common', badge: 'text-zinc-400 bg-zinc-800', card: 'from-zinc-500/10 to-zinc-700/10 border-zinc-500/20' },
  RARE: { label: 'Rare', badge: 'text-blue-400 bg-blue-500/10', card: 'from-blue-500/20 to-cyan-500/20 border-blue-500/30' },
  EPIC: { label: 'Epic', badge: 'text-purple-400 bg-purple-500/10', card: 'from-purple-500/20 to-violet-500/20 border-purple-500/30' },
  LEGENDARY: { label: 'Legendary', badge: 'text-yellow-400 bg-yellow-500/10', card: 'from-yellow-500/20 to-orange-500/20 border-yellow-500/30' },
};

export default function MarketplacePage() {
  const { user, setUser } = useAuthStore();
  const [items, setItems] = useState<MarketplaceItem[]>([]);
  const [owned, setOwned] = useState<Set<number>>(new Set());
  const [loading, setLoading] = useState(true);
  const [category, setCategory] = useState('All');
  const [search, setSearch] = useState('');
  const [confirming, setConfirming] = useState<MarketplaceItem | null>(null);
  const [buying, setBuying] = useState(false);

  useEffect(() => {
    Promise.all([
      api.get<MarketplaceItem[]>('/marketplace/items'),
      api.get<InventoryItem[]>('/marketplace/inventory'),
    ])
      .then(([all, inv]) => {
        setItems(all.data);
        setOwned(new Set(inv.data.map((i) => i.item.id)));
      })
      .catch((error) => toast.error(apiError(error, 'Could not load the marketplace')))
      .finally(() => setLoading(false));
  }, []);

  const activeCategory = CATEGORIES.find((c) => c.label === category);
  const filtered = items.filter((item) => {
    const matchCat = category === 'All' || (category === 'Owned' ? owned.has(item.id) : item.type === activeCategory?.type);
    return matchCat && item.name.toLowerCase().includes(search.toLowerCase());
  });

  const confirmPurchase = async () => {
    if (!confirming) return;
    setBuying(true);
    try {
      const res = await api.post<User>(`/marketplace/purchase/${confirming.id}`);
      setUser(res.data);
      setOwned((prev) => new Set(prev).add(confirming.id));
      toast.success(`${confirming.name} is yours! 🎉`, { description: `${confirming.price} coins spent.` });
      setConfirming(null);
    } catch (error) {
      toast.error(apiError(error, 'Purchase failed'));
    } finally {
      setBuying(false);
    }
  };

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-7xl mx-auto space-y-7">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Shop</div>
            <h1 className="text-3xl font-black tracking-tighter">Marketplace</h1>
          </div>
          <div className="flex items-center gap-1.5 px-4 py-2.5 bg-yellow-500/10 border border-yellow-500/20 rounded-xl">
            <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
            <span className="font-black text-yellow-400">{(user?.coins ?? 0).toLocaleString()}</span>
          </div>
        </div>

        <div className="relative">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-500" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search items..."
            className="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors"
          />
        </div>

        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          {CATEGORIES.map((cat) => (
            <button
              key={cat.label}
              onClick={() => setCategory(cat.label)}
              className={`px-4 py-2 rounded-xl text-sm font-bold flex-shrink-0 transition-all flex items-center gap-1.5 ${
                category === cat.label ? 'bg-white text-black' : 'bg-white/5 text-zinc-400 hover:bg-white/10 hover:text-white border border-white/5'
              }`}
            >
              {cat.label === 'Owned' && <Package className="w-3.5 h-3.5" />}
              {cat.label}{cat.label === 'Owned' ? ` (${owned.size})` : ''}
            </button>
          ))}
        </div>

        <div className="relative rounded-2xl overflow-hidden bg-gradient-to-r from-indigo-600/30 to-purple-600/30 border border-indigo-500/30 p-6 flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-widest text-indigo-400 mb-1">EARN COINS</div>
            <h2 className="text-2xl font-black tracking-tighter">Win games, win loot 🎁</h2>
            <p className="text-zinc-400 text-sm mt-1">Every quiz point earns 1 coin, and each victory adds a 50-coin bonus.</p>
          </div>
          <div className="text-6xl hidden sm:block">🎉</div>
        </div>

        {loading && <div className="flex justify-center py-12"><Loader2 className="w-6 h-6 animate-spin text-zinc-600" /></div>}
        {!loading && filtered.length === 0 && (
          <div className="text-center text-zinc-500 text-sm py-12 border border-dashed border-white/10 rounded-2xl">
            {category === 'Owned' ? "You don't own any items yet." : 'No items match your search.'}
          </div>
        )}

        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
          {filtered.map((item, i) => {
            const rarity = RARITY[item.rarity] ?? RARITY.COMMON;
            const isOwned = owned.has(item.id);
            const affordable = (user?.coins ?? 0) >= item.price;
            return (
              <motion.div
                key={item.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.04 }}
                whileHover={{ y: -4 }}
                className={`relative bg-gradient-to-br ${rarity.card} border rounded-2xl overflow-hidden group`}
              >
                {isOwned && (
                  <div className="absolute top-2 right-2 text-[10px] font-black bg-green-500 text-white px-2 py-0.5 rounded-full">OWNED</div>
                )}
                <div className="p-5 flex flex-col items-center gap-3">
                  <div className="text-5xl group-hover:scale-110 transition-transform">{item.icon ?? '🎁'}</div>
                  <div className="text-center">
                    <div className="font-black text-sm">{item.name}</div>
                    <span className={`text-[10px] font-black px-2 py-0.5 rounded-full ${rarity.badge}`}>{rarity.label}</span>
                    <p className="text-[11px] text-zinc-500 mt-2 leading-snug">{item.description}</p>
                  </div>
                  <button
                    onClick={() => setConfirming(item)}
                    disabled={isOwned}
                    title={!affordable && !isOwned ? `You need ${item.price - (user?.coins ?? 0)} more coins` : undefined}
                    className={`w-full flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-sm font-black transition-all border border-white/10 disabled:cursor-not-allowed ${
                      affordable || isOwned ? 'bg-black/30 hover:bg-black/50 group-hover:border-white/20' : 'bg-black/30 opacity-50'
                    }`}
                  >
                    {isOwned ? 'IN INVENTORY ✓' : <><Star className="w-3.5 h-3.5 text-yellow-400 fill-yellow-400" /> {item.price}</>}
                  </button>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>

      <Dialog open={confirming !== null} onOpenChange={(open) => !open && setConfirming(null)}>
        <DialogContent className="bg-zinc-950 border-white/10 text-white">
          <DialogHeader>
            <DialogTitle>Buy {confirming?.name}?</DialogTitle>
            <DialogDescription>
              {confirming && (user?.coins ?? 0) >= confirming.price
                ? `${confirming.price} coins will be deducted. You'll have ${((user?.coins ?? 0) - confirming.price).toLocaleString()} left.`
                : `You need ${(confirming?.price ?? 0) - (user?.coins ?? 0)} more coins. Win some games first!`}
            </DialogDescription>
          </DialogHeader>
          <div className="text-6xl text-center py-2">{confirming?.icon ?? '🎁'}</div>
          <DialogFooter>
            <button onClick={() => setConfirming(null)} className="px-5 py-2.5 border border-white/10 text-zinc-400 font-bold rounded-xl hover:text-white transition-all">
              Cancel
            </button>
            <button
              onClick={confirmPurchase}
              disabled={buying || !confirming || (user?.coins ?? 0) < confirming.price}
              className="px-5 py-2.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all disabled:opacity-30 flex items-center gap-2"
            >
              {buying && <Loader2 className="w-4 h-4 animate-spin" />} Confirm purchase
            </button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AppLayout>
  );
}
