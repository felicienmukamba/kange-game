'use client';

import { useEffect, useRef, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { motion, AnimatePresence } from 'framer-motion';
import { Client, type IMessage } from '@stomp/stompjs';
import { Send, Trophy, MessageSquare, Gamepad2, ArrowLeft, Play, Users, Crown, Wifi, WifiOff } from 'lucide-react';
import { toast } from 'sonner';
import { LiveKitRoom, VideoConference } from '@livekit/components-react';
import '@livekit/components-styles';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { useAuthStore, useHydrated, type User } from '@/app/lib/store';
import { api } from '@/app/lib/api';
import { createStompClient } from '@/app/lib/socket';

interface PublicQuestion {
  id: string;
  question: string;
  options: string[];
  timeLimit: number;
  index: number;
  total: number;
}

interface Lobby {
  title: string;
  host: string;
  status: 'WAITING' | 'ACTIVE' | 'FINISHED';
  players: string[];
  totalQuestions: number;
}

interface ChatMessage {
  sender: string;
  text: string;
  timestamp?: string;
}

type GameEvent =
  | ({ type: 'LOBBY'; scores: Record<string, number> } & Lobby)
  | { type: 'QUESTION'; data: PublicQuestion; endsAt: number }
  | { type: 'REVEAL'; questionId: string; correctAnswerIndex: number; scores: Record<string, number> }
  | { type: 'FINISHED'; scores: Record<string, number> }
  | { type: 'CORRECT' | 'WRONG'; points: number };

export default function LiveRoomPage() {
  const { id } = useParams<{ id: string }>();
  const roomId = decodeURIComponent(id);
  const router = useRouter();
  const { user, token, setUser } = useAuthStore();
  const hydrated = useHydrated();
  const stompRef = useRef<Client | null>(null);
  const chatEndRef = useRef<HTMLDivElement | null>(null);

  const [connected, setConnected] = useState(false);
  const [stream, setStream] = useState<{ token: string; url: string } | null>(null);
  const [tab, setTab] = useState<'chat' | 'rank'>('chat');
  const [messages, setMessages] = useState<ChatMessage[]>([{ sender: 'System', text: 'Welcome to the room! Say hi 👋' }]);
  const [draft, setDraft] = useState('');

  const [lobby, setLobby] = useState<Lobby | null>(null);
  const [scores, setScores] = useState<Record<string, number>>({});
  const [question, setQuestion] = useState<PublicQuestion | null>(null);
  const [endsAt, setEndsAt] = useState(0);
  const [now, setNow] = useState(() => Date.now());
  const [selected, setSelected] = useState<number | null>(null);
  const [revealed, setRevealed] = useState<number | null>(null);
  const [finalScores, setFinalScores] = useState<Record<string, number> | null>(null);

  useEffect(() => {
    if (hydrated && !token) router.replace('/auth');
  }, [hydrated, token, router]);

  // Live video is optional: only join LiveKit when the server has it configured
  useEffect(() => {
    if (!token) return;
    api.get<{ enabled: boolean }>('/stream/config')
      .then(async (cfg) => {
        if (!cfg.data.enabled) return;
        const res = await api.get<{ token: string; url: string }>('/stream/token', { params: { room: roomId } });
        setStream(res.data);
      })
      .catch(() => {});
  }, [roomId, token]);

  // STOMP connection: chat + game events
  useEffect(() => {
    if (!token) return;

    const handleGame = (message: IMessage) => {
      const event = JSON.parse(message.body) as GameEvent;
      switch (event.type) {
        case 'LOBBY':
          setLobby({ title: event.title, host: event.host, status: event.status, players: event.players, totalQuestions: event.totalQuestions });
          setScores(event.scores);
          break;
        case 'QUESTION':
          setQuestion(event.data);
          setEndsAt(event.endsAt);
          setSelected(null);
          setRevealed(null);
          setFinalScores(null);
          setLobby((l) => (l ? { ...l, status: 'ACTIVE' } : l));
          break;
        case 'REVEAL':
          setRevealed(event.correctAnswerIndex);
          setScores(event.scores);
          break;
        case 'FINISHED':
          setQuestion(null);
          setFinalScores(event.scores);
          setScores(event.scores);
          setLobby((l) => (l ? { ...l, status: 'FINISHED' } : l));
          // Rewards were just granted server-side
          api.get<User>('/profile/me').then((r) => setUser(r.data)).catch(() => {});
          break;
        case 'CORRECT':
          toast.success(`Correct! +${event.points} points`, { icon: '🔥' });
          break;
        case 'WRONG':
          toast.error('Wrong answer');
          break;
      }
    };

    const client = createStompClient(
      token,
      (c) => {
        setConnected(true);
        c.subscribe(`/topic/chat/${roomId}`, (m) => setMessages((prev) => [...prev.slice(-199), JSON.parse(m.body)]));
        c.subscribe(`/topic/game/${roomId}`, handleGame);
        c.subscribe('/user/queue/game', handleGame);
        c.publish({ destination: `/app/game/${roomId}/join`, body: '{}' });
      },
      () => setConnected(false)
    );
    client.activate();
    stompRef.current = client;

    return () => {
      if (client.connected) client.publish({ destination: `/app/game/${roomId}/leave`, body: '{}' });
      client.deactivate();
      stompRef.current = null;
    };
  }, [roomId, token, setUser]);

  // Question countdown, derived from the server's deadline
  useEffect(() => {
    if (!question) return;
    const t = setInterval(() => setNow(Date.now()), 250);
    return () => clearInterval(t);
  }, [question]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const publish = (destination: string, body: object = {}) => {
    if (!stompRef.current?.connected) {
      toast.error('Not connected to the room yet');
      return;
    }
    stompRef.current.publish({ destination, body: JSON.stringify(body) });
  };

  const sendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!draft.trim()) return;
    publish(`/app/chat/${roomId}`, { text: draft.trim() });
    setDraft('');
  };

  const answer = (idx: number) => {
    if (selected !== null || revealed !== null) return;
    setSelected(idx);
    publish(`/app/game/${roomId}/answer`, { answerIndex: idx });
  };

  const startGame = () => publish(`/app/game/${roomId}/start`);
  const playAgain = () => {
    setFinalScores(null);
    publish(`/app/game/${roomId}/join`);
  };

  if (!hydrated || !user) return null;

  const timeLeft = question ? Math.max(0, Math.ceil((endsAt - now) / 1000)) : 0;
  const ranking = Object.entries(scores).sort(([, a], [, b]) => b - a);
  const waiting = !question && !finalScores;

  return (
    <div className="flex h-screen bg-black text-white overflow-hidden flex-col md:flex-row">
      {/* Left: stage */}
      <div className="flex-1 flex flex-col relative min-h-[50vh]">
        <div className="absolute top-4 left-4 right-4 z-20 flex items-center justify-between gap-3">
          <Link href="/live" className="flex items-center gap-2 bg-black/50 backdrop-blur-md border border-white/10 rounded-full px-3 py-1.5 text-sm font-bold hover:bg-white/10 transition-colors">
            <ArrowLeft className="w-4 h-4" /> Rooms
          </Link>
          <div className="flex items-center gap-2 bg-black/50 backdrop-blur-md border border-white/10 rounded-full px-3 py-1.5 text-xs font-bold min-w-0">
            <span className="truncate">{lobby?.title ?? roomId}</span>
            <span className="text-zinc-500">·</span>
            <Users className="w-3.5 h-3.5 flex-shrink-0" /> {lobby?.players.length ?? 0}
            {connected ? <Wifi className="w-3.5 h-3.5 text-green-400 flex-shrink-0" /> : <WifiOff className="w-3.5 h-3.5 text-red-400 flex-shrink-0" />}
          </div>
        </div>

        <div className="flex-1 bg-zinc-950 relative flex items-center justify-center">
          {stream ? (
            <LiveKitRoom video={false} audio={false} token={stream.token} serverUrl={stream.url} data-lk-theme="default" className="w-full h-full">
              <VideoConference />
            </LiveKitRoom>
          ) : (
            <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_rgba(79,70,229,0.15),_transparent_60%)]" />
          )}

          {/* Lobby */}
          {waiting && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="relative z-10 text-center space-y-6 px-6 max-w-md">
              <div className="w-20 h-20 bg-indigo-500/20 rounded-full flex items-center justify-center mx-auto border border-indigo-500/40">
                <Gamepad2 className="w-10 h-10 text-indigo-400" />
              </div>
              <div>
                <h1 className="text-3xl font-black tracking-tighter">{lobby?.title ?? 'Connecting…'}</h1>
                <p className="text-zinc-500 text-sm mt-2">
                  {lobby ? `${lobby.totalQuestions} questions · ${lobby.players.length} player${lobby.players.length === 1 ? '' : 's'} in the lobby` : 'Joining the room…'}
                </p>
              </div>
              {lobby && (
                <div className="flex flex-wrap justify-center gap-2">
                  {lobby.players.map((p) => (
                    <span key={p} className="text-xs font-bold bg-white/5 border border-white/10 rounded-full px-3 py-1 flex items-center gap-1">
                      {p === lobby.host && <Crown className="w-3 h-3 text-yellow-400" />} {p}
                    </span>
                  ))}
                </div>
              )}
              <Button onClick={startGame} disabled={!connected || !lobby} className="h-12 px-8 bg-white text-black hover:bg-zinc-200 font-black rounded-full">
                <Play className="w-4 h-4 fill-black" /> START GAME
              </Button>
              <p className="text-[11px] text-zinc-600">Anyone in the lobby can start. Late joiners can jump in mid-game.</p>
            </motion.div>
          )}
        </div>

        {/* Question */}
        <AnimatePresence>
          {question && (
            <motion.div
              key={question.id}
              initial={{ y: 60, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: 60, opacity: 0 }}
              className="absolute bottom-6 left-1/2 -translate-x-1/2 w-full max-w-2xl px-4 z-30"
            >
              <Card className="bg-zinc-900/95 backdrop-blur-xl border-zinc-800 p-6 shadow-2xl overflow-hidden relative text-white">
                <div className="absolute top-0 left-0 h-1 bg-indigo-500 transition-all duration-300" style={{ width: `${revealed !== null ? 0 : (timeLeft / question.timeLimit) * 100}%` }} />
                <div className="text-[11px] font-black tracking-widest text-zinc-500 mb-2">QUESTION {question.index + 1} / {question.total}</div>
                <div className="flex justify-between items-start gap-4 mb-6">
                  <h3 className="text-xl font-bold font-heading">{question.question}</h3>
                  <div className={`font-bold w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${timeLeft <= 3 && revealed === null ? 'bg-red-500' : 'bg-indigo-500'}`}>
                    {revealed !== null ? '✓' : timeLeft}
                  </div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {question.options.map((option, idx) => {
                    const isCorrect = revealed === idx;
                    const isWrongPick = revealed !== null && selected === idx && revealed !== idx;
                    return (
                      <button
                        key={idx}
                        onClick={() => answer(idx)}
                        disabled={selected !== null || revealed !== null || timeLeft === 0}
                        className={`h-14 text-base text-left px-4 rounded-xl border flex items-center transition-all duration-200 disabled:cursor-default ${
                          isCorrect ? 'bg-green-600 border-green-500'
                          : isWrongPick ? 'bg-red-600/80 border-red-500'
                          : selected === idx ? 'bg-indigo-600 border-indigo-500 scale-[1.02]'
                          : 'border-zinc-700 hover:bg-zinc-800 disabled:hover:bg-transparent disabled:opacity-70'
                        }`}
                      >
                        <span className="w-8 h-8 rounded-full bg-black/30 flex items-center justify-center mr-3 text-xs font-bold shrink-0">
                          {String.fromCharCode(65 + idx)}
                        </span>
                        {option}
                      </button>
                    );
                  })}
                </div>
              </Card>
            </motion.div>
          )}

          {finalScores && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 flex items-center justify-center bg-black/80 backdrop-blur-md z-40 p-4">
              <Card className="w-full max-w-md bg-zinc-900 border-zinc-800 p-8 text-center text-white">
                <Trophy className="w-16 h-16 text-yellow-500 mx-auto mb-4" />
                <h2 className="text-3xl font-bold mb-2">Game Over!</h2>
                <p className="text-zinc-400 mb-6">
                  You scored <span className="text-white font-bold">{finalScores[user.username] ?? 0}</span> points
                  {finalScores[user.username] ? ` · +${(finalScores[user.username] ?? 0) * 10} XP` : ''}
                </p>
                <div className="space-y-2 mb-8 max-h-64 overflow-y-auto">
                  {Object.entries(finalScores).sort(([, a], [, b]) => b - a).map(([username, score], i) => (
                    <div key={username} className={`flex justify-between items-center p-3 rounded-lg ${username === user.username ? 'bg-indigo-600/20 border border-indigo-500/30' : 'bg-zinc-800/50'}`}>
                      <span className="flex items-center gap-3">
                        <span className="text-zinc-500 font-bold w-6">{i === 0 && score > 0 ? '👑' : `${i + 1}.`}</span>
                        {username}
                      </span>
                      <span className="font-bold text-indigo-400">{score} pts</span>
                    </div>
                  ))}
                </div>
                <div className="flex gap-3">
                  <Button variant="outline" className="flex-1 border-zinc-700" onClick={() => router.push('/live')}>Leave</Button>
                  <Button className="flex-1 bg-indigo-600 hover:bg-indigo-500" onClick={playAgain}>Play again</Button>
                </div>
              </Card>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Right: chat & ranking */}
      <div className="w-full md:w-80 lg:w-96 bg-zinc-950 border-l border-zinc-800 flex flex-col h-[50vh] md:h-auto">
        <div className="flex border-b border-zinc-800">
          {([['chat', MessageSquare, 'CHAT'], ['rank', Trophy, 'RANK']] as const).map(([key, Icon, label]) => (
            <button
              key={key}
              onClick={() => setTab(key)}
              className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 border-b-2 transition-colors ${tab === key ? 'border-indigo-500 text-white' : 'border-transparent text-zinc-500 hover:text-white'}`}
            >
              <Icon className="w-4 h-4" /> {label}
            </button>
          ))}
        </div>

        {tab === 'chat' ? (
          <div className="flex-1 overflow-hidden flex flex-col">
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              {messages.map((msg, i) => (
                <div key={i} className="flex flex-col gap-1">
                  <span className={`text-xs font-bold ${msg.sender === 'System' ? 'text-indigo-400' : msg.sender === user.username ? 'text-green-400' : 'text-zinc-500'}`}>
                    {msg.sender}
                  </span>
                  <p className="text-sm text-zinc-300 bg-zinc-900/50 p-3 rounded-2xl rounded-tl-none border border-zinc-800/50 break-words">{msg.text}</p>
                </div>
              ))}
              <div ref={chatEndRef} />
            </div>
            <div className="p-4 border-t border-zinc-800 bg-zinc-900/20">
              <form onSubmit={sendMessage} className="flex gap-2">
                <Input
                  value={draft}
                  onChange={(e) => setDraft(e.target.value.slice(0, 500))}
                  placeholder={connected ? 'Say something...' : 'Connecting...'}
                  disabled={!connected}
                  className="bg-zinc-950 border-zinc-800 focus:ring-indigo-500 text-white"
                />
                <Button type="submit" size="icon" disabled={!connected || !draft.trim()} className="bg-indigo-600 hover:bg-indigo-500 shrink-0" aria-label="Send">
                  <Send className="w-4 h-4 text-white" />
                </Button>
              </form>
            </div>
          </div>
        ) : (
          <div className="flex-1 overflow-y-auto p-4 space-y-2">
            {ranking.length === 0 && <p className="text-sm text-zinc-500 text-center py-8">No scores yet.</p>}
            {ranking.map(([username, score], i) => (
              <div key={username} className={`flex items-center justify-between p-3 rounded-xl ${username === user.username ? 'bg-indigo-600/15 border border-indigo-500/30' : 'bg-zinc-900/50'}`}>
                <span className="flex items-center gap-3 text-sm">
                  <span className={`font-black w-6 ${i < 3 ? 'text-yellow-400' : 'text-zinc-500'}`}>#{i + 1}</span>
                  {username}
                </span>
                <span className="font-bold text-indigo-400 text-sm">{score}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
