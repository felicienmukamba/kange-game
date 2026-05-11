'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useAuthStore } from '@/app/lib/store';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import axios from 'axios';

export default function AuthPage() {
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const setAuth = useAuthStore((state) => state.setAuth);

  const handleLogin = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData);

    try {
      // In a real app, this would be an API call
      // const response = await axios.post('http://localhost:8080/api/v1/auth/authenticate', data);
      // Mocking for now
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
        toast.success('Welcome back!');
        router.push('/dashboard');
      }, 1000);
    } catch (error) {
      toast.error('Invalid credentials');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    // Similar logic for registration
    setTimeout(() => {
      toast.success('Account created! Please log in.');
      setIsLoading(false);
    }, 1000);
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-black px-4 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-indigo-600/20 rounded-full blur-[120px]" />
      <div className="absolute bottom-1/4 right-1/4 w-64 h-64 bg-purple-600/20 rounded-full blur-[120px]" />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md z-10"
      >
        <Card className="border-zinc-800 bg-zinc-900/50 backdrop-blur-xl shadow-2xl">
          <CardHeader className="space-y-1">
            <CardTitle className="text-2xl font-bold tracking-tight text-white text-center">REWIFY</CardTitle>
            <CardDescription className="text-zinc-400 text-center">
              Enter your credentials to access the arena
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Tabs defaultValue="login" className="w-full">
              <TabsList className="grid w-full grid-cols-2 mb-8 bg-zinc-800/50">
                <TabsTrigger value="login">Login</TabsTrigger>
                <TabsTrigger value="register">Register</TabsTrigger>
              </TabsList>
              
              <TabsContent value="login">
                <form onSubmit={handleLogin} className="space-y-4">
                  <div className="space-y-2">
                    <Input
                      name="username"
                      placeholder="Username"
                      className="bg-zinc-950/50 border-zinc-800 text-white placeholder:text-zinc-600"
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Input
                      name="password"
                      type="password"
                      placeholder="Password"
                      className="bg-zinc-950/50 border-zinc-800 text-white placeholder:text-zinc-600"
                      required
                    />
                  </div>
                  <Button type="submit" className="w-full bg-indigo-600 hover:bg-indigo-500 text-white" disabled={isLoading}>
                    {isLoading ? 'Processing...' : 'Login'}
                  </Button>
                </form>
              </TabsContent>

              <TabsContent value="register">
                <form onSubmit={handleRegister} className="space-y-4">
                  <div className="space-y-2">
                    <Input
                      name="username"
                      placeholder="Username"
                      className="bg-zinc-950/50 border-zinc-800 text-white placeholder:text-zinc-600"
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Input
                      name="email"
                      type="email"
                      placeholder="Email address"
                      className="bg-zinc-950/50 border-zinc-800 text-white placeholder:text-zinc-600"
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Input
                      name="password"
                      type="password"
                      placeholder="Password"
                      className="bg-zinc-950/50 border-zinc-800 text-white placeholder:text-zinc-600"
                      required
                    />
                  </div>
                  <Button type="submit" className="w-full bg-indigo-600 hover:bg-indigo-500 text-white" disabled={isLoading}>
                    {isLoading ? 'Creating account...' : 'Create Account'}
                  </Button>
                </form>
              </TabsContent>
            </Tabs>
          </CardContent>
          <CardFooter className="flex flex-col">
            <div className="mt-2 text-center text-xs text-zinc-500">
              By continuing, you agree to our Terms of Service and Privacy Policy.
            </div>
          </CardFooter>
        </Card>
      </motion.div>
    </div>
  );
}
