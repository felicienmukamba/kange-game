'use client';

import { useEffect, useState, useRef } from 'react';
import { useAuthStore } from '@/app/lib/store';
import { useParams, useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Send, Trophy, MessageSquare, Gamepad2, Heart, Share2 } from 'lucide-react';
import { toast } from 'sonner';
import axios from 'axios';
import { Client } from '@stomp/stompjs';
import { createStompClient } from '@/app/lib/socket';

import { LiveKitRoom, VideoConference } from '@livekit/components-react';
import '@livekit/components-styles';

export default function LivePage() {
  const { id } = useParams();
  const router = useRouter();
  const { user, token: authToken } = useAuthStore();
  const [streamToken, setStreamToken] = useState<string | null>(null);
  const stompClientRef = useRef<Client | null>(null);
  
  const [messages, setMessages] = useState<{sender: string, text: string}[]>([
    { sender: 'System', text: 'Welcome to the live session!' }
  ]);

  const [currentQuestion, setCurrentQuestion] = useState<{
    id: string;
    question: string;
    options: string[];
    timeLimit: number;
  } | null>(null);

  const [timeLeft, setTimeLeft] = useState(0);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const [isGameOver, setIsGameOver] = useState(false);
  const [finalScores, setFinalScores] = useState<Record<string, number>>({});

  // 1. Fetch LiveKit Token
  useEffect(() => {
    if (!authToken || !id) return;

    const fetchToken = async () => {
      try {
        const res = await axios.get(`http://localhost:8080/api/v1/stream/token?room=${id}`, {
          headers: { Authorization: `Bearer ${authToken}` }
        });
        setStreamToken(res.data.token);
      } catch (error) {
        console.error('Failed to fetch stream token', error);
        toast.error('Failed to connect to stream');
      }
    };
    fetchToken();
  }, [id, authToken]);

  // 2. Initialize WebSocket Connection
  useEffect(() => {
    if (!authToken || !id) return;

    const client = createStompClient(
      (connectedClient) => {
        console.log('Connected to WebSocket');
        
        // Subscribe to Chat
        connectedClient.subscribe(`/topic/chat/${id}`, (message) => {
          const payload = JSON.parse(message.body);
          setMessages((prev) => [...prev, payload]);
        });

        // Subscribe to Game Updates
        connectedClient.subscribe(`/topic/game/${id}`, (message) => {
          const payload = JSON.parse(message.body);
          
          if (payload.type === 'QUESTION') {
            setCurrentQuestion(payload.data);
            setTimeLeft(payload.data.timeLimit);
            setSelectedOption(null);
            toast.success('New Question!');
          } else if (payload.type === 'FINISHED') {
            setCurrentQuestion(null);
            setIsGameOver(true);
            setFinalScores(payload.scores);
          }
        });

        // Subscribe to Private Notifications
        connectedClient.subscribe(`/user/queue/game`, (message) => {
          const payload = JSON.parse(message.body);
          if (payload.type === 'CORRECT') {
            toast.success('Correct Answer! +10 XP', {
              icon: '🔥',
            });
          }
        });

        // Signal Joining
        connectedClient.publish({
          destination: `/app/game/${id}/join`,
          body: JSON.stringify({}),
        });
      },
      () => {
        console.log('Disconnected from WebSocket');
      }
    );

    client.activate();
    stompClientRef.current = client;

    return () => {
      client.deactivate();
    };
  }, [id, authToken]);

  // 3. Question Timer
  useEffect(() => {
    if (timeLeft <= 0) return;
    const timer = setInterval(() => {
      setTimeLeft((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(timer);
  }, [timeLeft]);

  const handleSendMessage = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const input = (e.currentTarget as HTMLFormElement).elements.namedItem('message') as HTMLInputElement;
    if (!input.value.trim() || !stompClientRef.current) return;

    stompClientRef.current.publish({
      destination: `/app/chat/${id}`,
      body: JSON.stringify({
        sender: user?.username || 'Guest',
        text: input.value
      })
    });
    
    input.value = '';
  };

  const handleSelectOption = (idx: number) => {
    if (selectedOption !== null || !stompClientRef.current) return;
    setSelectedOption(idx);
    
    stompClientRef.current.publish({
      destination: `/app/game/${id}/answer`,
      body: JSON.stringify({ answerIndex: idx })
    });
  };

  if (!user) {
    if (typeof window !== 'undefined') router.push('/auth');
    return null;
  }

  return (
    <div className="flex h-screen bg-black overflow-hidden flex-col md:flex-row">
      
      {/* Left Column: Stream & Quiz */}
      <div className="flex-1 flex flex-col relative">
        
        {/* Stream Area */}
        <div className="flex-1 bg-zinc-900 relative flex items-center justify-center group">
          {streamToken ? (
            <LiveKitRoom
              video={true}
              audio={true}
              token={streamToken}
              serverUrl={process.env.NEXT_PUBLIC_LIVEKIT_URL}
              data-lk-theme="default"
              className="w-full h-full"
            >
              <VideoConference />
            </LiveKitRoom>
          ) : (
            <div className="text-center space-y-4">
              <div className="w-20 h-20 bg-indigo-500/20 rounded-full flex items-center justify-center mx-auto border border-indigo-500/40">
                <Gamepad2 className="w-10 h-10 text-indigo-400" />
              </div>
              <div className="text-zinc-500 text-sm font-medium tracking-wide">CONNECTING TO STREAM...</div>
            </div>
          )}

          {/* Action Bar */}
          <div className="absolute bottom-4 left-4 right-4 flex items-center justify-between z-20 opacity-0 group-hover:opacity-100 transition-opacity">
             <div className="flex items-center gap-2">
               <Button size="icon" variant="ghost" className="bg-black/40 backdrop-blur-md rounded-full text-white hover:bg-white/20">
                 <Heart className="w-5 h-5" />
               </Button>
               <Button size="icon" variant="ghost" className="bg-black/40 backdrop-blur-md rounded-full text-white hover:bg-white/20">
                 <Share2 className="w-5 h-5" />
               </Button>
             </div>
             <Badge className="bg-black/40 backdrop-blur-md border-white/10 px-4 py-2">
               Category: General Knowledge
             </Badge>
          </div>
        </div>

        {/* Quiz Interface Overlay/Section */}
        <AnimatePresence>
          {currentQuestion && (
            <motion.div 
              initial={{ y: 100, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: 100, opacity: 0 }}
              className="absolute bottom-24 left-1/2 -translate-x-1/2 w-full max-w-2xl px-4 z-30"
            >
              <Card className="bg-zinc-900/90 backdrop-blur-xl border-zinc-800 p-6 shadow-2xl overflow-hidden relative">
                <div className="absolute top-0 left-0 h-1 bg-indigo-500 transition-all duration-1000" style={{ width: `${(timeLeft/currentQuestion.timeLimit)*100}%` }} />
                
                <div className="flex justify-between items-start mb-6">
                   <h3 className="text-xl font-bold font-heading">{currentQuestion.question}</h3>
                   <div className="bg-indigo-500 text-white font-bold w-10 h-10 rounded-full flex items-center justify-center shrink-0">
                     {timeLeft}
                   </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {currentQuestion.options.map((option, idx) => (
                    <Button
                      key={idx}
                      variant={selectedOption === idx ? 'default' : 'outline'}
                      className={`h-14 text-lg justify-start px-6 rounded-xl border-zinc-700 transition-all duration-200 ${
                        selectedOption === idx ? 'bg-indigo-600 border-indigo-500 scale-[1.02] shadow-lg shadow-indigo-500/20' : 'hover:bg-zinc-800'
                      }`}
                      onClick={() => handleSelectOption(idx)}
                      disabled={selectedOption !== null}
                    >
                      <span className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center mr-3 text-xs font-bold">
                        {String.fromCharCode(65 + idx)}
                      </span>
                      {option}
                    </Button>
                  ))}
                </div>
              </Card>
            </motion.div>
          )}

          {isGameOver && (
             <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="absolute inset-0 flex items-center justify-center bg-black/80 backdrop-blur-md z-40 p-4"
            >
              <Card className="w-full max-w-md bg-zinc-900 border-zinc-800 p-8 text-center">
                <Trophy className="w-16 h-16 text-yellow-500 mx-auto mb-4" />
                <h2 className="text-3xl font-bold mb-2">Game Over!</h2>
                <p className="text-zinc-400 mb-6">Final Leaderboard</p>
                <div className="space-y-3 mb-8">
                  {Object.entries(finalScores)
                    .sort(([, a], [, b]) => b - a)
                    .map(([username, score], i) => (
                    <div key={username} className="flex justify-between items-center bg-zinc-800/50 p-3 rounded-lg">
                      <span className="flex items-center gap-3">
                        <span className="text-zinc-500 font-bold w-6">{i + 1}.</span>
                        {username}
                      </span>
                      <span className="font-bold text-indigo-400">{score} pts</span>
                    </div>
                  ))}
                </div>
                <Button className="w-full bg-indigo-600 hover:bg-indigo-500" onClick={() => setIsGameOver(false)}>
                  CONTINUE
                </Button>
              </Card>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Right Column: Chat & Leaderboard */}
      <div className="w-full md:w-80 lg:w-96 bg-zinc-950 border-l border-zinc-800 flex flex-col">
        
        {/* Tabs for Chat/Leaderboard */}
        <div className="flex border-b border-zinc-800">
          <button className="flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 border-b-2 border-indigo-500 text-white">
            <MessageSquare className="w-4 h-4" /> CHAT
          </button>
          <button className="flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 text-zinc-500 hover:text-white transition-colors">
            <Trophy className="w-4 h-4" /> RANK
          </button>
        </div>

        {/* Chat Messages */}
        <div className="flex-1 overflow-hidden flex flex-col">
           <ScrollArea className="flex-1 p-4">
             <div className="space-y-4">
               {messages.map((msg, i) => (
                 <div key={i} className="flex flex-col gap-1">
                   <div className="flex items-center gap-2">
                     <span className={`text-xs font-bold ${msg.sender === 'System' ? 'text-indigo-400' : 'text-zinc-500'}`}>
                       {msg.sender}
                     </span>
                   </div>
                   <p className="text-sm text-zinc-300 bg-zinc-900/50 p-3 rounded-2xl rounded-tl-none border border-zinc-800/50">
                     {msg.text}
                   </p>
                 </div>
               ))}
             </div>
           </ScrollArea>

           {/* Input Area */}
           <div className="p-4 border-t border-zinc-800 bg-zinc-900/20">
             <form onSubmit={handleSendMessage} className="flex gap-2">
               <Input 
                 name="message"
                 placeholder="Say something..." 
                 className="bg-zinc-950 border-zinc-800 focus:ring-indigo-500"
               />
               <Button type="submit" size="icon" className="bg-indigo-600 hover:bg-indigo-500 shrink-0">
                 <Send className="w-4 h-4 text-white" />
               </Button>
             </form>
           </div>
        </div>
      </div>
    </div>
  );
}
