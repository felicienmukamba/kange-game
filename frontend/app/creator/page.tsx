'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Sparkles, Zap, Trophy, Users, ArrowRight, CheckCircle2, Play, RefreshCw, Loader2, Bot } from 'lucide-react';
import AppLayout from '@/components/AppLayout';
import { useAuthStore } from '@/app/lib/store';
import { toast } from 'sonner';
import { api, apiError, type Challenge, type QuizQuestion } from '@/app/lib/api';

const GAME_TYPES = [
  { id: 'trivia', icon: '⚡', label: 'Quiz Battle', desc: 'General knowledge, multiple choice', color: 'from-yellow-500/20 to-orange-500/20', border: 'border-yellow-500/30' },
  { id: 'math', icon: '🧮', label: 'Speed Math', desc: 'Rapid-fire arithmetic challenges', color: 'from-blue-500/20 to-cyan-500/20', border: 'border-blue-500/30' },
  { id: 'gaming', icon: '🎮', label: 'Gamer Trivia', desc: 'Video game knowledge', color: 'from-purple-500/20 to-violet-500/20', border: 'border-purple-500/30' },
  { id: 'words', icon: '📝', label: 'Word Rush', desc: 'Vocabulary and language challenges', color: 'from-green-500/20 to-emerald-500/20', border: 'border-green-500/30' },
];

const inputClass = 'w-full px-4 py-3.5 bg-white/5 border border-white/10 rounded-xl text-white placeholder:text-zinc-600 text-sm outline-none focus:border-white/30 transition-colors';

export default function CreatorPage() {
  const router = useRouter();
  const { user, setUser } = useAuthStore();
  const [aiEnabled, setAiEnabled] = useState(false);
  const [myChallenges, setMyChallenges] = useState<Challenge[]>([]);

  const [step, setStep] = useState(1);
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const [customTopic, setCustomTopic] = useState('');
  const [title, setTitle] = useState('');
  const [prize, setPrize] = useState('100');
  const [maxPlayers, setMaxPlayers] = useState('50');
  const [questionCount, setQuestionCount] = useState('5');
  const [questions, setQuestions] = useState<QuizQuestion[]>([]);
  const [generating, setGenerating] = useState(false);
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    api.get<{ aiEnabled: boolean }>('/ai/status').then((r) => setAiEnabled(r.data.aiEnabled)).catch(() => {});
    api.get<Challenge[]>('/challenges/my').then((r) => setMyChallenges(r.data)).catch(() => {});
  }, []);

  const topic = selectedType === 'trivia' && aiEnabled && customTopic.trim() ? customTopic.trim() : selectedType ?? 'trivia';
  const prizeValue = Math.max(0, parseInt(prize || '0', 10) || 0);

  const generate = async () => {
    setGenerating(true);
    try {
      const res = await api.get<QuizQuestion[]>('/ai/generate-quiz', { params: { topic, count: questionCount } });
      setQuestions(res.data);
      setStep(3);
    } catch (error) {
      toast.error(apiError(error, 'Could not generate questions'));
    } finally {
      setGenerating(false);
    }
  };

  const reset = () => {
    setStep(1); setTitle(''); setSelectedType(null); setCustomTopic('');
    setPrize('100'); setMaxPlayers('50'); setQuestionCount('5'); setQuestions([]);
  };

  const handleCreate = async () => {
    if (prizeValue > (user?.coins ?? 0)) {
      toast.error('Not enough coins for this prize pool');
      return;
    }
    setCreating(true);
    try {
      const res = await api.post<Challenge>('/challenges', {
        title, topic, prizePool: prizeValue, maxPlayers: parseInt(maxPlayers, 10), questions,
      });
      if (user) setUser({ ...user, coins: user.coins - prizeValue });
      toast.success('Challenge launched! 🎉', { description: `"${title}" is open. Share the room with your friends.` });
      reset();
      router.push(`/live/challenge-${res.data.id}`);
    } catch (error) {
      toast.error(apiError(error, 'Could not create the challenge'));
    } finally {
      setCreating(false);
    }
  };

  const totalPrize = myChallenges.reduce((a, c) => a + (c.prizePool ?? 0), 0);

  return (
    <AppLayout>
      <div className="p-6 lg:p-8 max-w-6xl mx-auto space-y-8">
        <div className="flex items-center justify-between gap-4 flex-wrap">
          <div>
            <div className="text-[11px] font-black tracking-[0.3em] text-zinc-500 uppercase mb-1">Creator</div>
            <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3">
              <Sparkles className="w-7 h-7 text-indigo-400" /> Creator Studio
            </h1>
          </div>
          <div className={`flex items-center gap-2 px-4 py-2.5 rounded-xl border ${aiEnabled ? 'bg-green-500/10 border-green-500/30 text-green-300' : 'bg-white/5 border-white/10 text-zinc-400'}`}>
            <Bot className="w-4 h-4" />
            <span className="text-sm font-bold">{aiEnabled ? 'AI question generator on' : 'Built-in question bank'}</span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <div className="bg-white/[0.03] border border-white/8 rounded-3xl p-6 space-y-6">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1">
                  {[1, 2, 3].map((s) => (
                    <div key={s} className="flex items-center gap-1">
                      <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-black transition-all ${step >= s ? 'bg-white text-black' : 'bg-white/10 text-zinc-500'}`}>
                        {step > s ? <CheckCircle2 className="w-4 h-4" /> : s}
                      </div>
                      {s < 3 && <div className={`w-8 h-0.5 ${step > s ? 'bg-white' : 'bg-white/10'}`} />}
                    </div>
                  ))}
                </div>
                <span className="text-sm text-zinc-400 font-bold ml-2">
                  {step === 1 ? 'Choose type' : step === 2 ? 'Configure' : 'Review & launch'}
                </span>
              </div>

              {step === 1 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-4">
                  <h2 className="font-black text-lg">What kind of challenge?</h2>
                  <div className="grid grid-cols-2 gap-3">
                    {GAME_TYPES.map((type) => (
                      <button
                        key={type.id}
                        onClick={() => setSelectedType(type.id)}
                        className={`text-left p-4 rounded-2xl border transition-all ${
                          selectedType === type.id ? `bg-gradient-to-br ${type.color} ${type.border} scale-[0.98]` : 'bg-white/[0.02] border-white/5 hover:bg-white/5'
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

              {step === 2 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-5">
                  <h2 className="font-black text-lg">Configure your challenge</h2>
                  <div className="space-y-3">
                    <div>
                      <label htmlFor="title" className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Challenge Title</label>
                      <input id="title" value={title} maxLength={60} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Epic Trivia Night #4" className={inputClass} />
                    </div>
                    {selectedType === 'trivia' && aiEnabled && (
                      <div>
                        <label htmlFor="topic" className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Topic (AI)</label>
                        <input id="topic" value={customTopic} maxLength={80} onChange={(e) => setCustomTopic(e.target.value)} placeholder="e.g. African geography, 90s movies, football…" className={inputClass} />
                      </div>
                    )}
                    <div className="grid grid-cols-3 gap-3">
                      <div>
                        <label htmlFor="prize" className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Prize (coins)</label>
                        <input id="prize" value={prize} onChange={(e) => setPrize(e.target.value)} type="number" min="0" max={user?.coins ?? 0} className={inputClass} />
                      </div>
                      <div>
                        <label htmlFor="max" className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Max Players</label>
                        <input id="max" value={maxPlayers} onChange={(e) => setMaxPlayers(e.target.value)} type="number" min="2" max="500" className={inputClass} />
                      </div>
                      <div>
                        <label htmlFor="count" className="text-xs font-black text-zinc-400 uppercase tracking-widest block mb-2">Questions</label>
                        <input id="count" value={questionCount} onChange={(e) => setQuestionCount(e.target.value)} type="number" min="1" max="20" className={inputClass} />
                      </div>
                    </div>
                    {prizeValue > (user?.coins ?? 0) && (
                      <p className="text-xs text-red-400 font-bold">You only have {user?.coins} coins.</p>
                    )}
                  </div>
                  <div className="flex gap-3">
                    <button onClick={() => setStep(1)} className="px-5 py-3.5 border border-white/10 text-zinc-400 font-black rounded-xl hover:text-white hover:border-white/20 transition-all">
                      BACK
                    </button>
                    <button
                      disabled={!title.trim() || generating || prizeValue > (user?.coins ?? 0)}
                      onClick={generate}
                      className="flex-1 flex items-center justify-center gap-2 py-3.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all disabled:opacity-30 disabled:cursor-not-allowed"
                    >
                      {generating ? <><Loader2 className="w-4 h-4 animate-spin" /> GENERATING…</> : <>GENERATE QUESTIONS <ArrowRight className="w-4 h-4" /></>}
                    </button>
                  </div>
                </motion.div>
              )}

              {step === 3 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-5">
                  <div className="flex items-center justify-between">
                    <h2 className="font-black text-lg">Review & Launch</h2>
                    <button onClick={generate} disabled={generating} className="flex items-center gap-1.5 text-xs font-bold text-zinc-400 hover:text-white transition-colors">
                      <RefreshCw className={`w-3.5 h-3.5 ${generating ? 'animate-spin' : ''}`} /> Regenerate
                    </button>
                  </div>
                  <div className="bg-gradient-to-br from-indigo-600/10 to-purple-600/10 border border-indigo-500/20 rounded-2xl p-5 space-y-3">
                    {[
                      { label: 'Type', value: GAME_TYPES.find((t) => t.id === selectedType)?.label },
                      { label: 'Title', value: title },
                      { label: 'Topic', value: topic },
                      { label: 'Prize Pool', value: `${prizeValue} coins` },
                      { label: 'Max Players', value: maxPlayers },
                    ].map((row) => (
                      <div key={row.label} className="flex justify-between items-center gap-4">
                        <span className="text-xs text-zinc-500 font-black uppercase">{row.label}</span>
                        <span className="text-sm font-bold text-white truncate">{row.value}</span>
                      </div>
                    ))}
                  </div>

                  <div className="space-y-2 max-h-80 overflow-y-auto pr-1">
                    {questions.map((q, i) => (
                      <div key={q.id ?? i} className="bg-white/[0.03] border border-white/5 rounded-xl p-3">
                        <div className="text-sm font-bold mb-2">{i + 1}. {q.question}</div>
                        <div className="grid grid-cols-2 gap-1.5">
                          {q.options.map((o, j) => (
                            <span key={j} className={`text-xs px-2 py-1 rounded-lg ${j === q.correctAnswerIndex ? 'bg-green-500/15 text-green-300 font-bold' : 'bg-white/5 text-zinc-400'}`}>
                              {String.fromCharCode(65 + j)}. {o}
                            </span>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>

                  {prizeValue > 0 && (
                    <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-xl p-4">
                      <p className="text-xs text-yellow-400 font-bold">
                        ⚠️ {prizeValue} coins will be deducted from your balance now and paid to the first player who wins this challenge.
                      </p>
                    </div>
                  )}
                  <div className="flex gap-3">
                    <button onClick={() => setStep(2)} className="px-5 py-3.5 border border-white/10 text-zinc-400 font-black rounded-xl hover:text-white hover:border-white/20 transition-all">
                      BACK
                    </button>
                    <button
                      onClick={handleCreate}
                      disabled={creating || questions.length === 0}
                      className="flex-1 flex items-center justify-center gap-2 py-3.5 bg-white text-black font-black rounded-xl hover:bg-zinc-100 transition-all active:scale-[0.98] disabled:opacity-70"
                    >
                      {creating ? 'LAUNCHING...' : <><Play className="w-4 h-4 fill-black" /> LAUNCH NOW</>}
                    </button>
                  </div>
                </motion.div>
              )}
            </div>
          </div>

          <div className="space-y-5">
            <div>
              <h2 className="font-black text-lg mb-4 flex items-center gap-2">
                <Trophy className="w-5 h-5 text-yellow-400" /> My Challenges
              </h2>
              <div className="space-y-3">
                {myChallenges.length === 0 && (
                  <div className="text-sm text-zinc-500 border border-dashed border-white/10 rounded-2xl p-5 text-center">
                    You haven&apos;t created any challenges yet.
                  </div>
                )}
                {myChallenges.map((c, i) => (
                  <Link key={c.id} href={`/live/challenge-${c.id}`}>
                    <motion.div
                      initial={{ opacity: 0, x: 20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: i * 0.06 }}
                      className="bg-white/[0.03] border border-white/5 rounded-2xl p-4 hover:border-white/10 transition-all cursor-pointer mb-3"
                    >
                      <div className="flex items-start justify-between mb-2 gap-2">
                        <div className="font-bold text-sm">{c.title}</div>
                        <span className={`text-[10px] font-black px-2 py-0.5 rounded-full whitespace-nowrap ${
                          c.prizeWinner ? 'bg-zinc-700/50 text-zinc-400 border border-zinc-600/30' : 'bg-green-500/10 text-green-400 border border-green-500/20'
                        }`}>
                          {c.prizeWinner ? `WON BY ${c.prizeWinner}` : 'OPEN'}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 text-[11px] text-zinc-500">
                        <span className="flex items-center gap-1"><Users className="w-3 h-3" /> {c.maxPlayers}</span>
                        <span className="flex items-center gap-1"><Trophy className="w-3 h-3 text-yellow-500" /> {c.prizePool}</span>
                        <span className="flex items-center gap-1 text-zinc-600"><Zap className="w-3 h-3" /> {c.questions.length} Q · {c.topic}</span>
                      </div>
                    </motion.div>
                  </Link>
                ))}
              </div>
            </div>

            <div className="bg-white/[0.03] border border-white/5 rounded-2xl p-5 space-y-4">
              <h3 className="font-black text-sm text-zinc-400 uppercase tracking-wider">Creator Stats</h3>
              {[
                { label: 'Total Challenges', value: myChallenges.length, icon: Sparkles },
                { label: 'Prizes Awarded', value: myChallenges.filter((c) => c.prizeWinner).length, icon: Users },
                { label: 'Coins in Prize Pools', value: totalPrize, icon: Trophy },
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
