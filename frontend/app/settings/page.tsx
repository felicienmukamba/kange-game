'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Settings, LogOut, Loader2, Save, Package } from 'lucide-react';
import { toast } from 'sonner';
import AppLayout from '@/components/AppLayout';
import { useAuthStore, type User } from '@/app/lib/store';
import { api, apiError, type InventoryItem } from '@/app/lib/api';

const AVATARS = ['🥷', '🤖', '👾', '🧙', '🐉', '🦅', '🦊', '🐼', '🚀', '⚡', '🎮', '👑'];

export default function SettingsPage() {
  const user = useAuthStore((s) => s.user);
  return (
    <AppLayout>
      {/* Keyed by user so the form initialises from the loaded profile */}
      {user && <SettingsForm key={user.id} user={user} />}
    </AppLayout>
  );
}

function SettingsForm({ user }: { user: User }) {
  const router = useRouter();
  const { setUser, logout } = useAuthStore();
  const [avatar, setAvatar] = useState<string | null>(user.avatar ?? null);
  const [bio, setBio] = useState(user.bio ?? '');
  const [saving, setSaving] = useState(false);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);

  useEffect(() => {
    api.get<InventoryItem[]>('/marketplace/inventory').then((r) => setInventory(r.data)).catch(() => {});
  }, []);

  const save = async () => {
    setSaving(true);
    try {
      const res = await api.put<User>('/profile/update', { avatar: avatar ?? '', bio });
      setUser(res.data);
      toast.success('Profile saved');
    } catch (error) {
      toast.error(apiError(error, 'Could not save your profile'));
    } finally {
      setSaving(false);
    }
  };

  const signOut = () => {
    logout();
    toast.success('See you in the arena!');
    router.push('/');
  };

  return (
      <div className="p-6 lg:p-8 max-w-3xl mx-auto space-y-8">
        <div>
          <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Account</div>
          <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
            <Settings className="w-7 h-7 text-zinc-400" /> Settings
          </h1>
        </div>

        <section className="bg-white/[0.03] border border-white/5 rounded-2xl p-6 space-y-5">
          <h2 className="font-black">Profile</h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
            {[
              ['Username', user.username],
              ['Email', user.email],
              ['Role', user.role],
              ['Level', `${user.level} (${user.xp.toLocaleString()} XP)`],
            ].map(([label, value]) => (
              <div key={label} className="min-w-0">
                <div className="text-[11px] text-zinc-500 font-bold uppercase">{label}</div>
                <div className="font-bold truncate" title={value}>{value}</div>
              </div>
            ))}
          </div>

          <div>
            <div className="text-xs font-black text-zinc-400 uppercase tracking-widest mb-2">Avatar</div>
            <div className="flex flex-wrap gap-2">
              {AVATARS.map((a) => (
                <button
                  key={a}
                  onClick={() => setAvatar(a)}
                  aria-pressed={avatar === a}
                  className={`w-12 h-12 rounded-xl text-2xl flex items-center justify-center border transition-all ${avatar === a ? 'border-white bg-white/10 scale-105' : 'border-white/10 bg-white/[0.02] hover:bg-white/5'}`}
                >
                  {a}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label htmlFor="bio" className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Bio</label>
            <textarea
              id="bio"
              value={bio}
              onChange={(e) => setBio(e.target.value.slice(0, 280))}
              rows={3}
              placeholder="Tell the arena who you are…"
              className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 resize-none"
            />
            <div className="text-[11px] text-zinc-600 text-right">{bio.length}/280</div>
          </div>

          <button onClick={save} disabled={saving} className="flex items-center gap-2 px-5 py-3 bg-white text-black font-black rounded-xl text-sm hover:bg-zinc-100 disabled:opacity-50">
            {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />} Save changes
          </button>
        </section>

        <section className="bg-white/[0.03] border border-white/5 rounded-2xl p-6 space-y-4">
          <h2 className="font-black flex items-center gap-2"><Package className="w-4 h-4" /> Inventory</h2>
          {inventory.length === 0 ? (
            <p className="text-sm text-zinc-500">No items yet — visit the marketplace.</p>
          ) : (
            <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
              {inventory.map((inv) => (
                <div key={inv.id} className="flex flex-col items-center gap-1 p-3 rounded-xl bg-white/5 border border-white/5 text-center" title={inv.item.description}>
                  <span className="text-3xl">{inv.item.icon ?? '🎁'}</span>
                  <span className="text-[10px] font-bold text-zinc-400 leading-tight">{inv.item.name}</span>
                </div>
              ))}
            </div>
          )}
        </section>

        <section className="bg-red-500/5 border border-red-500/20 rounded-2xl p-6 flex items-center justify-between gap-4">
          <div>
            <h2 className="font-black">Sign out</h2>
            <p className="text-sm text-zinc-500">You can sign back in any time.</p>
          </div>
          <button onClick={signOut} className="flex items-center gap-2 px-5 py-3 bg-red-500/10 border border-red-500/30 text-red-300 font-black rounded-xl text-sm hover:bg-red-500/20">
            <LogOut className="w-4 h-4" /> Log out
          </button>
        </section>
      </div>
  );
}
