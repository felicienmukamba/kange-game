'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/app/lib/store';
import { Gamepad2, Tv, ShoppingBag, CheckCircle2, ArrowRight, Zap, Trophy, Users } from 'lucide-react';

const STEPS = [
  {
    id: 'welcome',
    title: 'Welcome to\nREWIFY',
    subtitle: 'The arena awaits you.',
    description: "You're about to join a platform where gaming, streaming, and social power collide. Let's set you up in 3 steps.",
    visual: '🎮',
  },
  {
    id: 'interests',
    title: 'What\'s your\nstyle?',
    subtitle: 'Pick what excites you.',
    description: 'Select your interests so we can personalize your experience from day one.',
    visual: '⚡',
  },
  {
    id: 'avatar',
    title: 'Choose your\narena persona',
    subtitle: 'Who are you in the arena?',
    description: 'Your avatar represents you in battles, streams, and the community.',
    visual: '🏆',
  },
  {
    id: 'ready',
    title: 'You\'re ready\nto dominate.',
    subtitle: 'Let the games begin.',
    description: 'Your profile is set up. Jump into live games, watch streams, or browse the marketplace.',
    visual: '🚀',
  },
];

const INTERESTS = [
  { id: 'quiz', icon: Zap, label: 'Quiz Battles', color: 'from-yellow-500 to-orange-500' },
  { id: 'stream', icon: Tv, label: 'Live Streams', color: 'from-pink-500 to-rose-500' },
  { id: 'tournament', icon: Trophy, label: 'Tournaments', color: 'from-indigo-500 to-purple-500' },
  { id: 'social', icon: Users, label: 'Social Feed', color: 'from-blue-500 to-cyan-500' },
  { id: 'marketplace', icon: ShoppingBag, label: 'Marketplace', color: 'from-green-500 to-emerald-500' },
  { id: 'gaming', icon: Gamepad2, label: 'Casual Games', color: 'from-purple-500 to-violet-500' },
];

const AVATARS = [
  { id: 'ninja', emoji: '🥷', label: 'Ninja', color: '#4f46e5' },
  { id: 'robot', emoji: '🤖', label: 'Robot', color: '#0ea5e9' },
  { id: 'alien', emoji: '👾', label: 'Alien', color: '#8b5cf6' },
  { id: 'wizard', emoji: '🧙', label: 'Wizard', color: '#ec4899' },
  { id: 'dragon', emoji: '🐉', label: 'Dragon', color: '#f59e0b' },
  { id: 'phoenix', emoji: '🦅', label: 'Phoenix', color: '#ef4444' },
];

export default function OnboardingPage() {
  const [step, setStep] = useState(0);
  const [selectedInterests, setSelectedInterests] = useState<string[]>([]);
  const [selectedAvatar, setSelectedAvatar] = useState<string | null>(null);
  const router = useRouter();
  const user = useAuthStore((s) => s.user);

  const toggleInterest = (id: string) => {
    setSelectedInterests((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id]
    );
  };

  const next = () => {
    if (step < STEPS.length - 1) setStep((s) => s + 1);
    else router.push('/dashboard');
  };

  const canProceed = () => {
    if (step === 1) return selectedInterests.length > 0;
    if (step === 2) return selectedAvatar !== null;
    return true;
  };

  const progress = ((step) / (STEPS.length - 1)) * 100;

  return (
    <div className="min-h-screen bg-black text-white flex flex-col overflow-hidden font-sans">
      {/* Progress Bar */}
      <div className="fixed top-0 left-0 w-full h-0.5 bg-white/5 z-50">
        <motion.div
          className="h-full bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500"
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
        />
      </div>

      {/* Step counter */}
      <div className="fixed top-6 right-8 z-50 flex items-center gap-2">
        {STEPS.map((_, i) => (
          <div
            key={i}
            className={`h-1.5 rounded-full transition-all duration-500 ${
              i === step ? 'w-8 bg-white' : i < step ? 'w-4 bg-white/60' : 'w-4 bg-white/15'
            }`}
          />
        ))}
      </div>

      {/* Logo */}
      <div className="fixed top-6 left-8 z-50 flex items-center gap-2">
        <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center">
          <div className="w-4 h-4 bg-black rounded-sm" />
        </div>
        <span className="text-white font-black tracking-tighter text-lg">REWIFY</span>
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={step}
          initial={{ opacity: 0, x: 60 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -60 }}
          transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
          className="flex-1 flex flex-col lg:flex-row min-h-screen"
        >
          {/* Left Panel - Text */}
          <div className="flex-1 flex flex-col justify-center px-8 lg:px-20 pt-24 pb-12 lg:py-32 relative">
            {/* Background glow */}
            <div className="absolute top-1/3 left-0 w-64 h-64 bg-indigo-600/20 blur-[100px] rounded-full pointer-events-none" />

            <div className="relative max-w-lg">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="text-5xl mb-6"
              >
                {STEPS[step].visual}
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.15 }}
                className="text-xs font-black tracking-[0.3em] text-indigo-400 uppercase mb-4"
              >
                Step {step + 1} of {STEPS.length} — {STEPS[step].subtitle}
              </motion.div>

              <motion.h1
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="text-5xl lg:text-7xl font-black tracking-tighter leading-[0.9] mb-6"
                style={{ whiteSpace: 'pre-line' }}
              >
                {STEPS[step].title}
              </motion.h1>

              <motion.p
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.3 }}
                className="text-zinc-400 text-lg leading-relaxed mb-10 max-w-md"
              >
                {user && step === 0 ? `Hey ${user.username}! ` : ''}{STEPS[step].description}
              </motion.p>

              {step !== 1 && step !== 2 && (
                <motion.button
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 }}
                  onClick={next}
                  className="group flex items-center gap-3 px-10 py-5 bg-white text-black font-black rounded-full hover:bg-zinc-100 transition-all active:scale-[0.98] w-fit"
                >
                  {step === STEPS.length - 1 ? 'ENTER THE ARENA' : 'CONTINUE'}
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </motion.button>
              )}
            </div>
          </div>

          {/* Right Panel - Interactive */}
          <div className="flex-1 flex flex-col justify-center px-8 lg:px-16 pb-24 lg:py-32">

            {/* Step 0: Welcome visual */}
            {step === 0 && (
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.2 }}
                className="grid grid-cols-2 gap-4 max-w-sm mx-auto"
              >
                {[
                  { icon: Gamepad2, label: 'Gaming', color: 'bg-indigo-500/20 border-indigo-500/30 text-indigo-400' },
                  { icon: Tv, label: 'Streaming', color: 'bg-pink-500/20 border-pink-500/30 text-pink-400' },
                  { icon: Trophy, label: 'Compete', color: 'bg-yellow-500/20 border-yellow-500/30 text-yellow-400' },
                  { icon: ShoppingBag, label: 'Market', color: 'bg-green-500/20 border-green-500/30 text-green-400' },
                ].map((item, i) => (
                  <motion.div
                    key={item.label}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.3 + i * 0.08 }}
                    className={`border rounded-2xl p-6 flex flex-col items-center gap-3 ${item.color}`}
                  >
                    <item.icon className="w-8 h-8" />
                    <span className="font-bold text-white text-sm">{item.label}</span>
                  </motion.div>
                ))}
              </motion.div>
            )}

            {/* Step 1: Interests */}
            {step === 1 && (
              <div className="space-y-4 max-w-sm mx-auto w-full">
                <div className="grid grid-cols-2 gap-3">
                  {INTERESTS.map((interest, i) => {
                    const selected = selectedInterests.includes(interest.id);
                    return (
                      <motion.button
                        key={interest.id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.1 + i * 0.06 }}
                        onClick={() => toggleInterest(interest.id)}
                        className={`relative flex flex-col items-center gap-2 p-5 rounded-2xl border transition-all duration-300 ${
                          selected
                            ? 'border-white/30 bg-white/10 scale-[0.97]'
                            : 'border-white/5 bg-white/[0.03] hover:bg-white/5'
                        }`}
                      >
                        {selected && (
                          <motion.div
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            className="absolute top-2 right-2"
                          >
                            <CheckCircle2 className="w-4 h-4 text-white" />
                          </motion.div>
                        )}
                        <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${interest.color} flex items-center justify-center`}>
                          <interest.icon className="w-5 h-5 text-white" />
                        </div>
                        <span className="text-xs font-bold text-white">{interest.label}</span>
                      </motion.button>
                    );
                  })}
                </div>
                <motion.button
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.5 }}
                  onClick={next}
                  disabled={!canProceed()}
                  className="w-full flex items-center justify-center gap-3 px-10 py-4 bg-white text-black font-black rounded-full hover:bg-zinc-100 transition-all active:scale-[0.98] disabled:opacity-30 disabled:cursor-not-allowed mt-2"
                >
                  CONTINUE <ArrowRight className="w-4 h-4" />
                </motion.button>
              </div>
            )}

            {/* Step 2: Avatar */}
            {step === 2 && (
              <div className="space-y-4 max-w-sm mx-auto w-full">
                <div className="grid grid-cols-3 gap-3">
                  {AVATARS.map((avatar, i) => {
                    const selected = selectedAvatar === avatar.id;
                    return (
                      <motion.button
                        key={avatar.id}
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: 0.1 + i * 0.06 }}
                        onClick={() => setSelectedAvatar(avatar.id)}
                        className={`relative flex flex-col items-center gap-2 p-4 rounded-2xl border transition-all duration-300 ${
                          selected
                            ? 'border-white/40 bg-white/10 scale-[0.97]'
                            : 'border-white/5 bg-white/[0.03] hover:bg-white/5'
                        }`}
                      >
                        {selected && (
                          <motion.div
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            className="absolute top-2 right-2"
                          >
                            <CheckCircle2 className="w-4 h-4 text-white" />
                          </motion.div>
                        )}
                        <div
                          className="w-14 h-14 rounded-2xl flex items-center justify-center text-3xl"
                          style={{ backgroundColor: avatar.color + '33', boxShadow: selected ? `0 0 20px ${avatar.color}55` : 'none' }}
                        >
                          {avatar.emoji}
                        </div>
                        <span className="text-[11px] font-bold text-zinc-400">{avatar.label}</span>
                      </motion.button>
                    );
                  })}
                </div>
                <motion.button
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.5 }}
                  onClick={next}
                  disabled={!canProceed()}
                  className="w-full flex items-center justify-center gap-3 px-10 py-4 bg-white text-black font-black rounded-full hover:bg-zinc-100 transition-all active:scale-[0.98] disabled:opacity-30 disabled:cursor-not-allowed mt-2"
                >
                  CONTINUE <ArrowRight className="w-4 h-4" />
                </motion.button>
              </div>
            )}

            {/* Step 3: Ready */}
            {step === 3 && (
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.2 }}
                className="flex flex-col items-center gap-6 max-w-sm mx-auto"
              >
                <div className="relative">
                  <div className="w-32 h-32 rounded-3xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-6xl shadow-2xl shadow-indigo-500/40">
                    {selectedAvatar ? AVATARS.find(a => a.id === selectedAvatar)?.emoji : '🎮'}
                  </div>
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: 0.5, type: 'spring' }}
                    className="absolute -top-2 -right-2 w-10 h-10 bg-green-500 rounded-full flex items-center justify-center"
                  >
                    <CheckCircle2 className="w-6 h-6 text-white" />
                  </motion.div>
                </div>
                <div className="text-center space-y-2">
                  <div className="font-black text-2xl">{user?.username}</div>
                  <div className="text-zinc-500 text-sm">
                    {selectedInterests.length} interest{selectedInterests.length !== 1 ? 's' : ''} selected
                  </div>
                </div>
                <div className="w-full grid grid-cols-3 gap-2 text-center">
                  {[{ label: 'Level', value: '1' }, { label: 'Coins', value: '100' }, { label: 'Rank', value: 'NEW' }].map(item => (
                    <div key={item.label} className="bg-white/5 rounded-xl p-3">
                      <div className="text-lg font-black">{item.value}</div>
                      <div className="text-[10px] text-zinc-500 font-bold uppercase">{item.label}</div>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}
          </div>
        </motion.div>
      </AnimatePresence>

      {/* Background decorations */}
      <div className="fixed inset-0 -z-10 overflow-hidden pointer-events-none">
        <motion.div
          animate={{ opacity: [0.1, 0.2, 0.1] }}
          transition={{ duration: 4, repeat: Infinity }}
          className="absolute top-1/4 right-1/4 w-96 h-96 bg-indigo-600/20 blur-[120px] rounded-full"
        />
        <motion.div
          animate={{ opacity: [0.05, 0.15, 0.05] }}
          transition={{ duration: 6, repeat: Infinity, delay: 2 }}
          className="absolute bottom-1/4 left-1/4 w-96 h-96 bg-purple-600/20 blur-[120px] rounded-full"
        />
      </div>
    </div>
  );
}
