'use client';

import { Suspense, useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useAuthStore } from '@/app/lib/store';
import { useRouter, useSearchParams } from 'next/navigation';
import { toast } from 'sonner';
import ThreeAuthBackground from '@/components/ThreeAuthBackground';
import { Lock, Mail, User, ArrowRight } from 'lucide-react';

function AuthPageInner() {
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const searchParams = useSearchParams();
  const setAuth = useAuthStore((state) => state.setAuth);
  const defaultTab = searchParams.get('signup') === 'true' ? 'register' : 'login';

  const handleLogin = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData);

    try {
      setTimeout(() => {
        setAuth({
          id: 1,
          username: data.username as string,
          email: 'user@example.com',
          role: 'PLAYER',
          level: 1,
          xp: 0,
          coins: 100
        }, 'mock-jwt-token');
        toast.success('Welcome back to the arena!');
        router.push('/onboarding'); // Redirect to onboarding for new flow
      }, 1500);
    } catch (error) {
      toast.error('Invalid credentials');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      toast.success('Account created! Let\'s get started.');
      setIsLoading(false);
      router.push('/auth'); // Or auto-login
    }, 1500);
  };

  return (
    <div className="relative min-h-screen flex items-center justify-center p-4 overflow-hidden font-sans">
      <ThreeAuthBackground />

      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.5, ease: "easeOut" }}
        className="w-full max-w-md z-10"
      >
        <Card className="border-white/10 bg-black/40 backdrop-blur-3xl shadow-[0_0_50px_-12px_rgba(79,70,229,0.5)] overflow-hidden">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500" />
          
          <CardHeader className="pt-10 pb-6 text-center">
            <motion.div 
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="w-16 h-16 bg-white rounded-2xl mx-auto mb-6 flex items-center justify-center shadow-2xl"
            >
              <div className="w-8 h-8 bg-black rounded-lg" />
            </motion.div>
            <CardTitle className="text-3xl font-black tracking-tighter text-white mb-2">REWIFY</CardTitle>
            <CardDescription className="text-zinc-400 font-medium">
              Join the future of social gaming
            </CardDescription>
          </CardHeader>

          <CardContent className="px-8">
            <Tabs defaultValue={defaultTab} className="w-full">
              <TabsList className="grid w-full grid-cols-2 mb-8 bg-white/5 border border-white/10 p-1 h-12">
                <TabsTrigger 
                  value="login" 
                  className="data-[state=active]:bg-white data-[state=active]:text-black transition-all font-bold"
                >
                  Login
                </TabsTrigger>
                <TabsTrigger 
                  value="register" 
                  className="data-[state=active]:bg-white data-[state=active]:text-black transition-all font-bold"
                >
                  Register
                </TabsTrigger>
              </TabsList>
              
              <TabsContent value="login">
                <form onSubmit={handleLogin} className="space-y-4">
                  <div className="group relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-500 group-focus-within:text-white transition-colors" />
                    <Input
                      name="username"
                      placeholder="Username"
                      className="pl-11 h-12 bg-white/5 border-white/10 text-white placeholder:text-zinc-600 focus:border-white/40 transition-all rounded-xl"
                      required
                    />
                  </div>
                  <div className="group relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-500 group-focus-within:text-white transition-colors" />
                    <Input
                      name="password"
                      type="password"
                      placeholder="Password"
                      className="pl-11 h-12 bg-white/5 border-white/10 text-white placeholder:text-zinc-600 focus:border-white/40 transition-all rounded-xl"
                      required
                    />
                  </div>
                  <Button 
                    type="submit" 
                    className="w-full h-12 bg-white text-black hover:bg-zinc-200 font-black rounded-xl transition-all active:scale-[0.98] group" 
                    disabled={isLoading}
                  >
                    {isLoading ? 'INITIATING...' : (
                      <span className="flex items-center gap-2">
                        ENTER ARENA <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                      </span>
                    )}
                  </Button>
                </form>
              </TabsContent>

              <TabsContent value="register">
                <form onSubmit={handleRegister} className="space-y-4">
                  <div className="group relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-500 group-focus-within:text-white transition-colors" />
                    <Input
                      name="username"
                      placeholder="Username"
                      className="pl-11 h-12 bg-white/5 border-white/10 text-white placeholder:text-zinc-600 focus:border-white/40 transition-all rounded-xl"
                      required
                    />
                  </div>
                  <div className="group relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-500 group-focus-within:text-white transition-colors" />
                    <Input
                      name="email"
                      type="email"
                      placeholder="Email address"
                      className="pl-11 h-12 bg-white/5 border-white/10 text-white placeholder:text-zinc-600 focus:border-white/40 transition-all rounded-xl"
                      required
                    />
                  </div>
                  <div className="group relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-500 group-focus-within:text-white transition-colors" />
                    <Input
                      name="password"
                      type="password"
                      placeholder="Password"
                      className="pl-11 h-12 bg-white/5 border-white/10 text-white placeholder:text-zinc-600 focus:border-white/40 transition-all rounded-xl"
                      required
                    />
                  </div>
                  <Button 
                    type="submit" 
                    className="w-full h-12 bg-white text-black hover:bg-zinc-200 font-black rounded-xl transition-all active:scale-[0.98] group" 
                    disabled={isLoading}
                  >
                    {isLoading ? 'CREATING...' : (
                      <span className="flex items-center gap-2">
                        CREATE ACCOUNT <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                      </span>
                    )}
                  </Button>
                </form>
              </TabsContent>
            </Tabs>
          </CardContent>
          <CardFooter className="pb-8 px-8 flex flex-col space-y-4">
            <div className="relative w-full">
              <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-white/5" /></div>
              <div className="relative flex justify-center text-xs uppercase"><span className="bg-transparent px-2 text-zinc-500 font-bold">Secure Access</span></div>
            </div>
            <p className="text-center text-[10px] text-zinc-500 leading-relaxed font-medium">
              By entering REWIFY, you accept our <span className="text-zinc-400 underline cursor-pointer">Terms of Combat</span> and <span className="text-zinc-400 underline cursor-pointer">Privacy Protocol</span>.
            </p>
          </CardFooter>
        </Card>
      </motion.div>

      {/* Decorative corners */}
      <div className="absolute top-0 left-0 w-24 h-24 border-t-2 border-l-2 border-white/5 m-8 pointer-events-none" />
      <div className="absolute top-0 right-0 w-24 h-24 border-t-2 border-r-2 border-white/5 m-8 pointer-events-none" />
      <div className="absolute bottom-0 left-0 w-24 h-24 border-b-2 border-l-2 border-white/5 m-8 pointer-events-none" />
      <div className="absolute bottom-0 right-0 w-24 h-24 border-b-2 border-r-2 border-white/5 m-8 pointer-events-none" />
    </div>
  );
}

export default function AuthPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-black" />}>
      <AuthPageInner />
    </Suspense>
  );
}
