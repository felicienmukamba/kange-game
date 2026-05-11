'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Sparkles, Plus, Trash2, Save, Play, Wand2, Loader2 } from 'lucide-react';
import { toast } from 'sonner';

interface Question {
  id: string;
  text: string;
  options: string[];
  correctAnswerIndex: number;
}

export default function CreatorPage() {
  const [topic, setTopic] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const [questions, setQuestions] = useState<Question[]>([]);

  const generateWithAI = async () => {
    if (!topic.trim()) {
      toast.error('Please enter a topic first');
      return;
    }
    
    setIsGenerating(true);
    try {
      // Mocking the AI generation call
      await new Promise(resolve => setTimeout(resolve, 2000));
      const mockNewQuestions: Question[] = [
        {
          id: Math.random().toString(),
          text: `Who discovered the principle of buoyancy in ${topic}?`,
          options: ['Archimedes', 'Newton', 'Galileo', 'Einstein'],
          correctAnswerIndex: 0
        },
        {
          id: Math.random().toString(),
          text: `What is the most common element in ${topic}?`,
          options: ['Hydrogen', 'Oxygen', 'Carbon', 'Nitrogen'],
          correctAnswerIndex: 0
        }
      ];
      setQuestions([...questions, ...mockNewQuestions]);
      toast.success('AI generated new questions!');
    } catch (error) {
      toast.error('Failed to generate questions');
    } finally {
      setIsGenerating(false);
    }
  };

  const removeQuestion = (id: string) => {
    setQuestions(questions.filter(q => q.id !== id));
  };

  return (
    <div className="min-h-screen bg-black text-white p-6 lg:p-10">
      <div className="max-w-5xl mx-auto space-y-8">
        
        <header className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold font-heading flex items-center gap-3">
              Creator Studio <Sparkles className="w-8 h-8 text-indigo-400" />
            </h1>
            <p className="text-zinc-500 mt-1">Design your next viral challenge</p>
          </div>
          <div className="flex gap-3">
            <Button variant="outline" className="border-zinc-800">Save Draft</Button>
            <Button className="bg-indigo-600 hover:bg-indigo-500">Publish Game</Button>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* AI Panel */}
          <Card className="lg:col-span-1 bg-zinc-900 border-zinc-800 h-fit sticky top-10">
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <Wand2 className="w-5 h-5 text-purple-400" /> AI Generator
              </CardTitle>
              <CardDescription>Generate questions instantly using AI</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm text-zinc-400">Challenge Topic</label>
                <Input 
                  placeholder="e.g. Space Exploration" 
                  value={topic}
                  onChange={(e) => setTopic(e.target.value)}
                  className="bg-zinc-950 border-zinc-800"
                />
              </div>
              <Button 
                onClick={generateWithAI} 
                className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 border-none"
                disabled={isGenerating}
              >
                {isGenerating ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Generate with AI'}
              </Button>
            </CardContent>
          </Card>

          {/* Question List */}
          <div className="lg:col-span-2 space-y-6">
            <div className="flex items-center justify-between">
               <h2 className="text-xl font-bold">Questions ({questions.length})</h2>
               <Button variant="ghost" size="sm" onClick={() => setQuestions([...questions, {
                 id: Math.random().toString(),
                 text: 'New Question',
                 options: ['', '', '', ''],
                 correctAnswerIndex: 0
               }])}>
                 <Plus className="w-4 h-4 mr-2" /> Add Manual
               </Button>
            </div>

            <div className="space-y-4">
              <AnimatePresence initial={false}>
                {questions.map((q, index) => (
                  <motion.div
                    key={q.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 20 }}
                    className="group"
                  >
                    <Card className="bg-zinc-900/50 border-zinc-800 hover:border-zinc-700 transition-colors">
                      <CardContent className="p-6">
                         <div className="flex justify-between gap-4">
                           <div className="flex-1 space-y-4">
                             <Input 
                               defaultValue={q.text}
                               className="bg-transparent border-none text-lg font-bold p-0 focus-visible:ring-0"
                               placeholder="Enter your question here..."
                             />
                             <div className="grid grid-cols-2 gap-3">
                               {q.options.map((opt, i) => (
                                 <div key={i} className="flex items-center gap-2 bg-zinc-950 rounded-lg p-2 border border-zinc-800">
                                   <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold ${q.correctAnswerIndex === i ? 'bg-green-500/20 text-green-400' : 'bg-zinc-800'}`}>
                                     {String.fromCharCode(65 + i)}
                                   </div>
                                   <input 
                                     defaultValue={opt}
                                     className="bg-transparent border-none text-sm outline-none w-full"
                                     placeholder={`Option ${i+1}`}
                                   />
                                 </div>
                               ))}
                             </div>
                           </div>
                           <Button 
                             variant="ghost" 
                             size="icon" 
                             onClick={() => removeQuestion(q.id)}
                             className="text-zinc-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
                           >
                             <Trash2 className="w-4 h-4" />
                           </Button>
                         </div>
                      </CardContent>
                    </Card>
                  </motion.div>
                ))}
              </AnimatePresence>

              {questions.length === 0 && (
                <div className="text-center py-20 border-2 border-dashed border-zinc-800 rounded-2xl">
                  <div className="bg-zinc-900 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Plus className="w-8 h-8 text-zinc-600" />
                  </div>
                  <h3 className="text-zinc-400 font-medium">No questions yet</h3>
                  <p className="text-zinc-600 text-sm">Use the AI generator or add questions manually</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
