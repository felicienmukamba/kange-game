'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Coins, Zap, Shield, Crown, Star } from 'lucide-react';
import { toast } from 'sonner';

export default function MarketplacePage() {
  const [items, setItems] = useState([
    { id: 1, name: 'Double XP Boost', price: 500, icon: <Zap className="w-6 h-6 text-yellow-400" />, type: 'BOOST' },
    { id: 2, name: 'Elite Shield', price: 1200, icon: <Shield className="w-6 h-6 text-blue-400" />, type: 'ITEM' },
    { id: 3, name: 'Premium Pass', price: 5000, icon: <Crown className="w-6 h-6 text-purple-400" />, type: 'PASS' },
    { id: 4, name: 'Lucky Star', price: 300, icon: <Star className="w-6 h-6 text-pink-400" />, type: 'REWARD' },
  ]);

  const buyItem = (itemName: string) => {
    toast.success(`Purchased ${itemName}!`, {
      description: 'The item has been added to your inventory.',
    });
  };

  return (
    <div className="min-h-screen bg-black text-white p-6">
      <div className="max-w-6xl mx-auto space-y-10">
        
        <header className="flex items-center justify-between">
           <div>
             <h1 className="text-3xl font-bold font-heading">Marketplace</h1>
             <p className="text-zinc-500">Gear up for the next challenge</p>
           </div>
           <div className="bg-zinc-900 px-4 py-2 rounded-full border border-zinc-800 flex items-center gap-2">
             <Coins className="w-5 h-5 text-yellow-500" />
             <span className="font-bold">12,450</span>
           </div>
        </header>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {items.map((item) => (
            <motion.div key={item.id} whileHover={{ y: -5 }}>
              <Card className="bg-zinc-900/50 border-zinc-800 overflow-hidden hover:border-indigo-500/50 transition-colors">
                <CardHeader className="flex items-center justify-center py-10 bg-zinc-950/50">
                   {item.icon}
                </CardHeader>
                <CardContent className="p-4 space-y-2">
                   <div className="flex justify-between items-start">
                     <CardTitle className="text-lg">{item.name}</CardTitle>
                     <Badge className="bg-zinc-800 text-[10px]">{item.type}</Badge>
                   </div>
                   <p className="text-sm text-zinc-500">Enhance your gameplay with this special {item.type.toLowerCase()}.</p>
                </CardContent>
                <CardFooter className="p-4 border-t border-zinc-800 flex justify-between items-center">
                   <div className="flex items-center gap-1.5 font-bold">
                     <Coins className="w-4 h-4 text-yellow-500" />
                     {item.price}
                   </div>
                   <Button onClick={() => buyItem(item.name)} size="sm" className="bg-indigo-600 hover:bg-indigo-500">Buy Now</Button>
                </CardFooter>
              </Card>
            </motion.div>
          ))}
        </div>

      </div>
    </div>
  );
}
