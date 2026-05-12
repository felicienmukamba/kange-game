'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Sparkles, Plus, Zap, Trophy, Clock, Users, ArrowRight, CheckCircle2, Play } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import { useAuthStore } from '@/app/lib/store';
import { toast } from 'sonner';

const GAME_TYPES = [
  { id: 'quiz', icon: '⚡', label: 'Quiz Battle', desc: 'Multiple choice questions with timer', color: 'from-yellow-500/20 to-orange-500/20', border: 'border-yellow-500/30' },
  { id: 'speed', icon: '🧮', label: 'Speed Math', desc: 'Rapid-fire arithmetic challenges', color: 'from-blue-500/20 to-cyan-500/20', border: 'border-blue-500/30' },
  { id: 'trivia', icon: '🎯', label: 'Trivia Night', desc: 'General knowledge tournament', color: 'from-purple-500/20 to-violet-500/20', border: 'border-purple-500/30' },
  { id: 'word', icon: '📝', label: 'Word Rush', desc: 'Vocabulary and language challenges', color: 'from-green-500/20 to-emerald-500/20', border: 'border-green-500/30' },
];

const MY_CHALLENGES = [
  { title: 'Epic Trivia #3', type: 'Trivia', players: 124, prize: 200, status: 'live' },
  { title: 'Speed Math Cup', type: 'Speed Math', players: 48, prize: 100, status: 'ended' },
  { title: 'Word Masters', type: 'Word Rush', players: 0, prize: 150, status: 'draft' },
];

const STATUS_STYLES: Record<string, string> = {
  live: 'bg-red-500/20 text-red-400 border border-red-500/30',
  ended: 'bg-zinc-700/50 text-zinc-400 border border-zinc-600/30',
  draft: 'bg-yellow-500/10 text-yellow-400 border border-yellow-500/20',
};

export default function CreatorPage() {
  const { user } = useAuthStore();
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const [step, setStep] = useState(1);
  const [title, setTitle] = useState('');
  const [prize, setPrize] = useState('100');
  const [maxPlayers, setMaxPlayers] = useState('50');
  const [creating, setCreating] = useState(false);

  const handleCreate = () => {
    if (!title.trim() || !selectedType) {
      toast.error('Please fill all fields!');
      return;
    }
    setCreating(true);
    setTimeout(() => {
      setCreating(false);
      toast.success('Challenge created! 🎉', { description: `"${title}" is now live for players to join.` });
      setStep(1); setTitle(''); setSelectedType(null); setPrize('100'); setMaxPlayers('50');
    }, 1500);
  };

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-6xl mx-auto space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Creator</div>
            <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
              <Sparkles className="w-7 h-7 text-indigo-400" /> Creator Studio
            </h1>
          </div>
          <div className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600/10 border border-indigo-500/30 rounded-xl">
            <Zap className="w-4 h-4 text-indigo-400" />
            <span className="text-sm font-bold text-indigo-300">{user?.coins ?? 0} coins earned</span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Create Form */}
          <div className="lg:col-span-2">
            <div className="bg-white/[0.03] border border-white/8 rounded-3xl p-6 space-y-6">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1">
                  {[1, 2, 3].map((s) => (
                    <div key={s} className="flex items-center gap-1">
                      <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-black transition-all ${
                        step >= s ? 'bg-white text-black' : 'bg-white/10 text-zinc-500'
                      }`}>
                        {step > s ? <CheckCircle2 className="w-4 h-4" /> : s}
                      </div>
                      {s < 3 && <div className={`w-8 h-0.5 ${step > s ? 'bg-white' : 'bg-white/10'}`} />}
                    </div>
                  ))}
                </div>
                <span className="text-sm text-zinc-400 font-bold ml-2">
                  {step === 1 ? 'Choose type' : step === 2 ? 'Configure' : 'Review'}
                </span>
              </div>

              {/* Step 1: Game Type */}
              {step === 1 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-4">
                  <h2 className="font-black text-lg">What kind of challenge?</h2>
                  <div className="grid grid-cols-2 gap-3">
                    {GAME_TYPES.map((type) => (
                      <button
                        key={type.id}
                        onClick={() => setSelectedType(type.id)}
                        className={`text-left p-4 rounded-2xl border transition-all ${
                          selectedType === type.id
                            ? `bg-gradient-to-br ${type.color} ${type.border} scale-[0.98]`
                            : 'bg-white/[0.02] border-white/5 hover:bg-white/5'
                        }`}
                      >
                        <div className="text-3xl mb-2">{type.icon}</div>
                        <div className="font-black text-sm">{type.label}</div>
                        <div className="text-xs text-zinc-500 mt-1">{type.desc}</div>
                      </button>
                    ))}
                  </div>
                  <button
                    disabled={!selectedType}
                    onClick={() => setStep(2)}
                    className="w-full flex items-center justify-center gap-2 py-3.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all disabled:opacity-30 disabled:cursor-not-allowed"
                  >
                    NEXT <ArrowRight className="w-4 h-4" />
                  </button>
                </motion.div>
              )}

              {/* Step 2: Configure */}
              {step === 2 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-5">
                  <h2 className="font-black text-lg">Configure your challenge</h2>
                  <div className="space-y-3">
                    <div>
                      <label className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Challenge Title</label>
                      <input
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                        placeholder="e.g. Epic Trivia Night #4"
                        className="w-full px-4 py-3.5 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors"
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Prize Pool (coins)</label>
                        <input
                          value={prize}
                          onChange={(e) => setPrize(e.target.value)}
                          type="number"
                          min="50"
                          placeholder="100"
                          className="w-full px-4 py-3.5 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors"
                        />
                      </div>
                      <div>
                        <label className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Max Players</label>
                        <input
                          value={maxPlayers}
                          onChange={(e) => setMaxPlayers(e.target.value)}
                          type="number"
                          min="2"
                          max="500"
                          placeholder="50"
                          className="w-full px-4 py-3.5 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors"
                        />
                      </div>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <button onClick={() => setStep(1)} className="px-5 py-3.5 border border-white/10 text-zinc-400 font-black rounded-xl hover:text-white hover:border-white/20 transition-all">
                      BACK
                    </button>
                    <button
                      disabled={!title.trim()}
                      onClick={() => setStep(3)}
                      className="flex-1 flex items-center justify-center gap-2 py-3.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all disabled:opacity-30 disabled:cursor-not-allowed"
                    >
                      REVIEW <ArrowRight className="w-4 h-4" />
                    </button>
                  </div>
                </motion.div>
              )}

              {/* Step 3: Review */}
              {step === 3 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-5">
                  <h2 className="font-black text-lg">Review & Launch</h2>
                  <div className="bg-gradient-to-br from-indigo-600/10 to-purple-600/10 border border-indigo-500/20 rounded-2xl p-5 space-y-3">
                    {[
                      { label: 'Type', value: GAME_TYPES.find(t => t.id === selectedType)?.label },
                      { label: 'Title', value: title },
                      { label: 'Prize Pool', value: `${prize} coins` },
                      { label: 'Max Players', value: maxPlayers },
                    ].map((row) => (
                      <div key={row.label} className="flex justify-between items-center">
                        <span className="text-xs text-zinc-500 font-black uppercase">{row.label}</span>
                        <span className="text-sm font-bold text-white">{row.value}</span>
                      </div>
                    ))}
                  </div>
                  <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-xl p-4">
                    <p className="text-xs text-yellow-400 font-bold">
                      ⚠️ {prize} coins will be deducted from your balance as the prize pool when you launch.
                    </p>
                  </div>
                  <div className="flex gap-3">
                    <button onClick={() => setStep(2)} className="px-5 py-3.5 border border-white/10 text-zinc-400 font-black rounded-xl hover:text-white hover:border-white/20 transition-all">
                      BACK
                    </button>
                    <button
                      onClick={handleCreate}
                      disabled={creating}
                      className="flex-1 flex items-center justify-center gap-2 py-3.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all active:scale-[0.98] disabled:opacity-70"
                    >
                      {creating ? 'LAUNCHING...' : <><Play className="w-4 h-4 fill-black" /> LAUNCH NOW</>}
                    </button>
                  </div>
                </motion.div>
              )}
            </div>
          </div>

          {/* My Challenges */}
          <div className="space-y-5">
            <div>
              <h2 className="font-black text-lg mb-4 flex items-center gap-2">
                <Trophy className="w-5 h-5 text-yellow-400" /> My Challenges
              </h2>
              <div className="space-y-3">
                {MY_CHALLENGES.map((c, i) => (
                  <motion.div
                    key={c.title}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.08 }}
                    className="bg-white/[0.03] border border-white/5 rounded-2xl p-4 hover:border-white/10 transition-all cursor-pointer group"
                  >
                    <div className="flex items-start justify-between mb-2">
                      <div className="font-bold text-sm">{c.title}</div>
                      <span className={`text-[10px] font-black px-2 py-0.5 rounded-full capitalize ${STATUS_STYLES[c.status]}`}>
                        {c.status === 'live' ? '● LIVE' : c.status.toUpperCase()}
                      </span>
                    </div>
                    <div className="flex items-center gap-3 text-[11px] text-zinc-500">
                      <span className="flex items-center gap-1"><Users className="w-3 h-3" /> {c.players}</span>
                      <span className="flex items-center gap-1"><Trophy className="w-3 h-3 text-yellow-500" /> {c.prize}</span>
                      <span className="flex items-center gap-1 text-zinc-600"><Zap className="w-3 h-3" /> {c.type}</span>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>

            {/* Stats */}
            <div className="bg-white/[0.03] border border-white/5 rounded-2xl p-5 space-y-4">
              <h3 className="font-black text-sm text-zinc-400 uppercase tracking-wider">Creator Stats</h3>
              {[
                { label: 'Total Challenges', value: '3', icon: Sparkles },
                { label: 'Total Players', value: '172', icon: Users },
                { label: 'Coins Distributed', value: '450', icon: Trophy },
              ].map((s) => (
                <div key={s.label} className="flex items-center justify-between">
                  <div className="flex items-center gap-2 text-zinc-400 text-sm">
                    <s.icon className="w-4 h-4" />{s.label}
                  </div>
                  <span className="font-black text-white">{s.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
