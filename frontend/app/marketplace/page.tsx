'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Star, ShoppingCart, Zap, Shield, Sparkles, Filter, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import axios from 'axios';
import { useAuthStore } from '@/app/lib/store';
import { toast } from 'sonner';

interface Item {
  id: number;
  name: string;
  description: string;
  price: number;
  type: string;
  imageUrl: string;
}

export default function MarketplacePage() {
  const [items, setItems] = useState<Item[]>([]);
  const { user, token } = useAuthStore();
  const [selectedCategory, setSelectedCategory] = useState('ALL');

  useEffect(() => {
    const fetchItems = async () => {
      try {
        const res = await axios.get('http://localhost:8080/api/v1/marketplace/items', {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (res.data.length > 0) {
          setItems(res.data);
        } else {
          // Fallback to mock data if DB is empty
          setItems([
            { id: 1, name: 'Neon Samurai', description: 'Legendary skin with glow effects', price: 2500, type: 'SKIN', imageUrl: '' },
            { id: 2, name: 'Cyber Cat', description: 'Rare animated avatar', price: 1200, type: 'AVATAR', imageUrl: '' },
            { id: 3, name: 'XP Booster 2x', description: 'Double XP for 24 hours', price: 500, type: 'BOOST', imageUrl: '' },
            { id: 4, name: 'Golden Frame', description: 'Elite profile decoration', price: 800, type: 'AVATAR', imageUrl: '' },
            { id: 5, name: 'Shadow Assassin', description: 'Epic stealth skin', price: 1800, type: 'SKIN', imageUrl: '' },
          ]);
        }
      } catch (err) {
        console.error('Failed to fetch marketplace items', err);
        // Fallback to mock data on error
        setItems([
          { id: 1, name: 'Neon Samurai', description: 'Legendary skin with glow effects', price: 2500, type: 'SKIN', imageUrl: '' },
          { id: 2, name: 'Cyber Cat', description: 'Rare animated avatar', price: 1200, type: 'AVATAR', imageUrl: '' },
          { id: 3, name: 'XP Booster 2x', description: 'Double XP for 24 hours', price: 500, type: 'BOOST', imageUrl: '' },
          { id: 4, name: 'Golden Frame', description: 'Elite profile decoration', price: 800, type: 'AVATAR', imageUrl: '' },
          { id: 5, name: 'Shadow Assassin', description: 'Epic stealth skin', price: 1800, type: 'SKIN', imageUrl: '' },
        ]);
      }
    };
    fetchItems();
  }, [token]);

  const handlePurchase = async (item: Item) => {
    if (!user || user.coins < item.price) {
      toast.error('Insufficient coins!');
      return;
    }

    try {
      await axios.post(`http://localhost:8080/api/v1/marketplace/purchase/${item.id}`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      toast.success(`Successfully purchased ${item.name}!`);
      // Update local user state if necessary or trigger a profile refresh
    } catch (error) {
      toast.error('Purchase failed');
    }
  };

  const filteredItems = selectedCategory === 'ALL' 
    ? items 
    : items.filter(item => item.type === selectedCategory);

  return (
    <div className="min-h-screen bg-black text-white p-6 lg:p-10">
      <div className="max-w-7xl mx-auto space-y-10">
        
        <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
          <div className="space-y-2">
            <h1 className="text-4xl font-black font-heading flex items-center gap-4 tracking-tighter">
              MARKETPLACE <ShoppingCart className="w-8 h-8 text-indigo-500" />
            </h1>
            <p className="text-zinc-500 font-medium">Upgrade your presence with exclusive items and boosts.</p>
          </div>
          <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-4 flex items-center gap-4 shadow-xl">
             <div className="w-10 h-10 bg-yellow-500/20 rounded-full flex items-center justify-center border border-yellow-500/40">
                <Star className="w-5 h-5 text-yellow-500 fill-yellow-500" />
             </div>
             <div>
                <p className="text-xs text-zinc-500 uppercase font-black">Your Balance</p>
                <p className="text-xl font-bold text-white">{user?.coins || 0} Coins</p>
             </div>
             <Button className="ml-4 bg-indigo-600 hover:bg-indigo-500 text-xs font-bold">TOP UP</Button>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-10">
          
          {/* Sidebar Filters */}
          <aside className="lg:col-span-1 space-y-8">
             <div className="relative">
                <Search className="w-4 h-4 text-zinc-500 absolute left-3 top-1/2 -translate-y-1/2" />
                <Input placeholder="Search items..." className="bg-zinc-900 border-zinc-800 pl-10" />
             </div>

             <div className="space-y-4">
                <h3 className="text-sm font-black text-zinc-500 uppercase tracking-widest flex items-center gap-2">
                   <Filter className="w-4 h-4" /> Categories
                </h3>
                <div className="space-y-2">
                   {['ALL', 'SKIN', 'AVATAR', 'BOOST'].map((cat) => (
                      <button
                        key={cat}
                        onClick={() => setSelectedCategory(cat)}
                        className={`w-full text-left px-4 py-3 rounded-xl transition-all font-bold text-sm ${
                          selectedCategory === cat ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-500/20' : 'text-zinc-500 hover:bg-zinc-900 hover:text-white'
                        }`}
                      >
                         {cat}
                      </button>
                   ))}
                </div>
             </div>

             <Card className="bg-linear-to-br from-indigo-900/20 to-purple-900/20 border-indigo-500/20">
                <CardContent className="p-6 text-center space-y-4">
                   <Sparkles className="w-10 h-10 text-indigo-400 mx-auto" />
                   <h4 className="font-bold">PRO PASS</h4>
                   <p className="text-xs text-zinc-400">Unlock 50+ legendary items with the Season 1 Pro Pass.</p>
                   <Button variant="outline" className="w-full border-indigo-500/50 text-indigo-400 hover:bg-indigo-500 hover:text-white">GET NOW</Button>
                </CardContent>
             </Card>
          </aside>

          {/* Items Grid */}
          <main className="lg:col-span-3">
             <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                <AnimatePresence mode="popLayout">
                  {filteredItems.map((item) => (
                    <motion.div
                      key={item.id}
                      layout
                      initial={{ opacity: 0, scale: 0.9 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.9 }}
                    >
                       <Card className="bg-zinc-900 border-zinc-800 group hover:border-indigo-500/50 transition-all overflow-hidden flex flex-col h-full shadow-lg">
                          <div className="aspect-square bg-zinc-950 relative flex items-center justify-center p-8 overflow-hidden">
                             <div className="absolute inset-0 bg-linear-to-t from-zinc-900/80 to-transparent" />
                             {item.type === 'SKIN' && <Shield className="w-20 h-20 text-indigo-500/20 group-hover:scale-110 group-hover:text-indigo-500 transition-all duration-500" />}
                             {item.type === 'AVATAR' && <Sparkles className="w-20 h-20 text-purple-500/20 group-hover:scale-110 group-hover:text-purple-500 transition-all duration-500" />}
                             {item.type === 'BOOST' && <Zap className="w-20 h-20 text-yellow-500/20 group-hover:scale-110 group-hover:text-yellow-500 transition-all duration-500" />}
                             
                             <div className="absolute top-4 right-4">
                                <Badge className="bg-black/50 backdrop-blur-md border-white/10">{item.type}</Badge>
                             </div>
                          </div>
                          
                          <CardHeader className="flex-1">
                             <div className="flex justify-between items-start mb-2">
                                <CardTitle className="text-xl font-bold">{item.name}</CardTitle>
                             </div>
                             <CardDescription className="text-zinc-500">{item.description}</CardDescription>
                          </CardHeader>

                          <CardFooter className="p-6 pt-0 border-t border-zinc-800/50 flex items-center justify-between mt-auto">
                             <div className="flex items-center gap-2">
                                <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                                <span className="font-bold text-lg">{item.price}</span>
                             </div>
                             <Button 
                                onClick={() => handlePurchase(item)}
                                className="bg-indigo-600 hover:bg-indigo-500 font-bold px-6 rounded-xl"
                             >
                                BUY
                             </Button>
                          </CardFooter>
                       </Card>
                    </motion.div>
                  ))}
                </AnimatePresence>
             </div>

             {filteredItems.length === 0 && (
                <div className="py-40 text-center space-y-4">
                   <div className="w-20 h-20 bg-zinc-900 rounded-full flex items-center justify-center mx-auto">
                      <Search className="w-8 h-8 text-zinc-700" />
                   </div>
                   <h3 className="text-zinc-500 font-medium">No items found in this category</h3>
                </div>
             )}
          </main>
        </div>
      </div>
    </div>
  );
}
