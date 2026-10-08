'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuthStore } from '@/app/lib/store';
import { motion, AnimatePresence } from 'framer-motion';
import {
  LayoutDashboard, Tv, Gamepad2, Trophy, ShoppingBag, Users,
  Settings, LogOut, Star, ChevronRight, Sparkles
} from 'lucide-react';
import { toast } from 'sonner';

const NAV_ITEMS: { href: string; icon: typeof Tv; label: string; badge?: string }[] = [
  { href: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { href: '/feed', icon: Users, label: 'Social Feed' },
  { href: '/live', icon: Tv, label: 'Live Rooms', badge: 'LIVE' },
  { href: '/games', icon: Gamepad2, label: 'Games' },
  { href: '/leaderboard', icon: Trophy, label: 'Leaderboard' },
  { href: '/marketplace', icon: ShoppingBag, label: 'Marketplace' },
  { href: '/creator', icon: Sparkles, label: 'Creator Studio' },
];

const SECONDARY_ITEMS = [
  { href: '/settings', icon: Settings, label: 'Settings' },
];

export default function Sidebar({ collapsed, onToggle }: { collapsed: boolean; onToggle: () => void }) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuthStore();

  const handleLogout = () => {
    logout();
    toast.success('See you in the arena!');
    router.push('/');
  };

  if (!user) return null;

  return (
    <motion.aside
      animate={{ width: collapsed ? 72 : 240 }}
      transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
      className="fixed left-0 top-0 h-full bg-black border-r border-white/5 flex flex-col z-40 overflow-hidden"
    >
      {/* Logo */}
      <div className="flex items-center justify-between p-4 h-16 border-b border-white/5">
        <AnimatePresence>
          {!collapsed && (
            <motion.div
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -10 }}
              className="flex items-center gap-2"
            >
              <div className="w-7 h-7 bg-white rounded-lg flex-shrink-0 flex items-center justify-center">
                <div className="w-3.5 h-3.5 bg-black rounded-sm" />
              </div>
              <span className="font-black tracking-tighter text-white text-lg">REWIFY</span>
            </motion.div>
          )}
        </AnimatePresence>
        {collapsed && (
          <div className="w-7 h-7 bg-white rounded-lg flex-shrink-0 flex items-center justify-center mx-auto">
            <div className="w-3.5 h-3.5 bg-black rounded-sm" />
          </div>
        )}
        <button
          onClick={onToggle}
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          className="w-6 h-6 flex items-center justify-center text-zinc-500 hover:text-white transition-colors ml-auto"
        >
          <motion.div animate={{ rotate: collapsed ? 0 : 180 }}>
            <ChevronRight className="w-4 h-4" />
          </motion.div>
        </button>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-2 py-4 space-y-0.5 overflow-y-auto">
        {NAV_ITEMS.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
          return (
            <Link key={item.href} href={item.href}>
              <motion.div
                whileHover={{ x: 2 }}
                whileTap={{ scale: 0.98 }}
                className={`relative flex items-center gap-3 rounded-xl px-3 py-2.5 transition-all group ${
                  isActive
                    ? 'bg-white text-black'
                    : 'text-zinc-400 hover:bg-white/5 hover:text-white'
                }`}
              >
                <item.icon className="w-5 h-5 flex-shrink-0" />
                <AnimatePresence>
                  {!collapsed && (
                    <motion.div
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="flex items-center justify-between flex-1 min-w-0"
                    >
                      <span className="font-semibold text-sm truncate">{item.label}</span>
                      {item.badge && (
                        <span className={`text-[10px] font-black px-1.5 py-0.5 rounded-full ${
                          item.badge === 'LIVE'
                            ? 'bg-red-500 text-white animate-pulse'
                            : 'bg-indigo-500/20 text-indigo-400'
                        }`}>
                          {item.badge}
                        </span>
                      )}
                    </motion.div>
                  )}
                </AnimatePresence>
                {isActive && (
                  <motion.div
                    layoutId="active-indicator"
                    className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-6 bg-white rounded-full -translate-x-2"
                  />
                )}
              </motion.div>
            </Link>
          );
        })}

        <div className="pt-4 border-t border-white/5 mt-4 space-y-0.5">
          {SECONDARY_ITEMS.map((item) => (
            <Link key={item.href} href={item.href}>
              <div className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-zinc-500 hover:bg-white/5 hover:text-white transition-all">
                <item.icon className="w-5 h-5 flex-shrink-0" />
                {!collapsed && <span className="font-semibold text-sm">{item.label}</span>}
              </div>
            </Link>
          ))}
        </div>
      </nav>

      {/* User Profile */}
      <div className="p-3 border-t border-white/5">
        <div className={`flex items-center gap-3 rounded-xl p-2 hover:bg-white/5 transition-all cursor-pointer group ${collapsed ? 'justify-center' : ''}`}>
          <Link href="/settings" className="w-8 h-8 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-sm font-black text-white flex-shrink-0">
            {user.avatar || user.username[0].toUpperCase()}
          </Link>
          {!collapsed && (
            <div className="flex-1 min-w-0">
              <div className="text-sm font-bold text-white truncate">{user.username}</div>
              <div className="flex items-center gap-1">
                <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                <span className="text-[11px] text-zinc-500 font-medium">{user.coins.toLocaleString()} coins · Lv.{user.level}</span>
              </div>
            </div>
          )}
          {!collapsed && (
            <button
              onClick={handleLogout}
              aria-label="Log out"
              title="Log out"
              className="text-zinc-500 hover:text-white transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    </motion.aside>
  );
}
