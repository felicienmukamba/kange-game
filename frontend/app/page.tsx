'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Gamepad2, Tv, Users, Zap } from 'lucide-react';

export default function Home() {
  return (
    <div className="relative isolate overflow-hidden bg-black flex-1">
      {/* Background Gradients */}
      <div className="absolute inset-x-0 -top-40 -z-10 transform-gpu overflow-hidden blur-3xl sm:-top-80" aria-hidden="true">
        <div className="relative left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 rotate-[30deg] bg-gradient-to-tr from-[#ff80b5] to-[#9089fc] opacity-20 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]"></div>
      </div>

      <nav className="flex items-center justify-between p-6 lg:px-8" aria-label="Global">
        <div className="flex lg:flex-1">
          <Link href="/" className="-m-1.5 p-1.5 text-2xl font-bold tracking-tighter text-white">
            REWIFY
          </Link>
        </div>
        <div className="flex gap-x-12">
          <Link href="/games" className="text-sm font-semibold leading-6 text-zinc-300 hover:text-white transition-colors">Games</Link>
          <Link href="/streams" className="text-sm font-semibold leading-6 text-zinc-300 hover:text-white transition-colors">Streams</Link>
          <Link href="/community" className="text-sm font-semibold leading-6 text-zinc-300 hover:text-white transition-colors">Community</Link>
        </div>
        <div className="flex lg:flex-1 lg:justify-end gap-x-4">
          <Link href="/auth">
            <Button variant="ghost" className="text-sm font-semibold leading-6 text-white">Log in</Button>
          </Link>
          <Link href="/auth?signup=true">
            <Button className="bg-white text-black hover:bg-zinc-200">Sign up</Button>
          </Link>
        </div>
      </nav>

      <div className="mx-auto max-w-7xl px-6 pb-24 pt-10 sm:pb-32 lg:flex lg:px-8 lg:py-40">
        <div className="mx-auto max-w-2xl flex-shrink-0 lg:mx-0 lg:max-w-xl lg:pt-8">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <div className="mt-24 sm:mt-32 lg:mt-16">
              <span className="rounded-full bg-indigo-500/10 px-3 py-1 text-sm font-semibold leading-6 text-indigo-400 ring-1 ring-inset ring-indigo-500/20">
                What's new: Live Quiz Tournaments
              </span>
            </div>
            <h1 className="mt-10 text-4xl font-bold tracking-tight text-white sm:text-6xl font-heading">
              Social + Gaming + Live
            </h1>
            <p className="mt-6 text-lg leading-8 text-zinc-400">
              REWIFY is where TikTok meets Twitch and Kahoot. Join thousands of players in real-time challenges, watch your favorite streamers, and earn rewards.
            </p>
            <div className="mt-10 flex items-center gap-x-6">
              <Link href="/auth?signup=true">
                <Button size="lg" className="h-12 px-8 text-lg bg-indigo-600 hover:bg-indigo-500 text-white border-none shadow-lg shadow-indigo-500/25">
                  Get Started
                </Button>
              </Link>
              <Link href="/explore" className="text-sm font-semibold leading-6 text-white flex items-center gap-2">
                Explore Games <Zap className="w-4 h-4 text-yellow-400" />
              </Link>
            </div>
          </motion.div>
        </div>

        <div className="mx-auto mt-16 flex max-w-2xl sm:mt-24 lg:ml-10 lg:mr-0 lg:mt-0 lg:max-w-none lg:flex-none xl:ml-32">
          <div className="max-w-3xl flex-none sm:max-w-5xl lg:max-w-none">
             <motion.div 
               initial={{ opacity: 0, scale: 0.9 }}
               animate={{ opacity: 1, scale: 1 }}
               transition={{ duration: 0.7, delay: 0.2 }}
               className="rounded-xl bg-zinc-900/50 p-2 ring-1 ring-inset ring-white/10 lg:-m-4 lg:rounded-2xl lg:p-4 backdrop-blur-sm"
             >
               <div className="grid grid-cols-2 gap-4">
                  <div className="aspect-video rounded-lg bg-indigo-500/20 flex items-center justify-center border border-indigo-500/30">
                    <Tv className="w-12 h-12 text-indigo-400" />
                  </div>
                  <div className="aspect-video rounded-lg bg-purple-500/20 flex items-center justify-center border border-purple-500/30">
                    <Gamepad2 className="w-12 h-12 text-purple-400" />
                  </div>
                  <div className="aspect-video rounded-lg bg-pink-500/20 flex items-center justify-center border border-pink-500/30">
                    <Users className="w-12 h-12 text-pink-400" />
                  </div>
                  <div className="aspect-video rounded-lg bg-blue-500/20 flex items-center justify-center border border-blue-500/30">
                    <Zap className="w-12 h-12 text-blue-400" />
                  </div>
               </div>
             </motion.div>
          </div>
        </div>
      </div>
    </div>
  );
}
