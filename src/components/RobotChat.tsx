import React, { useState, useRef, useEffect } from 'react';
import { ChatMessage } from '../types';
import { ROBOT_PERSONAS } from '../data/gradeData';
import { RobotAvatar } from './RobotAvatar';
import { MessageSquare, Send, Volume2, VolumeX, Sparkles, RefreshCw, User, Bot, CornerDownRight } from 'lucide-react';

interface RobotChatProps {
  grade: number;
  persona: string;
  onChangePersona: (persona: string) => void;
  onEarnRewards: (xp: number, coins: number) => void;
}

export const RobotChat: React.FC<RobotChatProps> = ({
  grade,
  persona,
  onChangePersona,
  onEarnRewards,
}) => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: 'welcome',
      sender: 'robot',
      text: `Привет! Я твой личный ИИ-Тьютор РобоШколы. Задай мне любой вопрос по домашнему заданию, сложной теме или просто спроси совет по учёбе!`,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      suggestedFollowups: [
        'Как легко выучить таблицу умножения?',
        'Объясни, зачем нужны дроби?',
        'Как подготовиться к контрольной за 15 минут?',
      ],
    },
  ]);
  const [inputText, setInputText] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [isSpeaking, setIsSpeaking] = useState<boolean>(false);
  const [voiceEnabled, setVoiceEnabled] = useState<boolean>(true);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  const currentPersonaObj = ROBOT_PERSONAS.find((p) => p.id === persona) || ROBOT_PERSONAS[0];

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  const speakText = (text: string) => {
    if (!voiceEnabled || !('speechSynthesis' in window)) return;
    window.speechSynthesis.cancel();

    const cleanText = text.replace(/[*#]/g, '');
    const utterance = new SpeechSynthesisUtterance(cleanText);
    utterance.lang = 'ru-RU';
    utterance.rate = 1.0;
    utterance.pitch = persona === 'spark' ? 1.2 : 1.0;

    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => setIsSpeaking(false);

    window.speechSynthesis.speak(utterance);
  };

  const handleSendMessage = async (customMessage?: string) => {
    const messageToSend = customMessage || inputText;
    if (!messageToSend.trim()) return;

    const userMsg: ChatMessage = {
      id: Date.now().toString(),
      sender: 'user',
      text: messageToSend,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputText('');
    setLoading(true);

    try {
      const response = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: messageToSend,
          history: messages,
          grade,
          persona,
        }),
      });

      if (!response.ok) {
        throw new Error('Не удалось получить ответ робота.');
      }

      const data = await response.json();

      const robotMsg: ChatMessage = {
        id: (Date.now() + 1).toString(),
        sender: 'robot',
        text: data.reply || 'Прости, я немного запутался. Попробуй переформулировать вопрос!',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        suggestedFollowups: data.suggestedFollowups || [],
      };

      setMessages((prev) => [...prev, robotMsg]);

      // Speak if voice enabled
      speakText(robotMsg.text);

      // Reward XP for active learning discussion
      onEarnRewards(15, 5);
    } catch (err) {
      console.error(err);
      const errorMsg: ChatMessage = {
        id: (Date.now() + 1).toString(),
        sender: 'robot',
        text: 'Упс! Произошел сбой связи с Робо-Сервером. Проверь интернет или попробуй ещё раз.',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => [...prev, errorMsg]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Banner & Persona Selection */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <RobotAvatar
              config={{
                bodyColor: '#06b6d4',
                eyeType: currentPersonaObj.avatar,
                headItem: 'antenna',
                bodyDecal: 'atom',
                auraColor: 'purple',
              }}
              size="sm"
              isTalking={isSpeaking}
            />
            <div>
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <span>Чат с Робо-Тьютором</span>
                <span className={`text-xs px-2.5 py-0.5 rounded-full font-semibold text-white bg-gradient-to-r ${currentPersonaObj.color}`}>
                  {currentPersonaObj.name}
                </span>
              </h2>
              <p className="text-xs text-slate-400 mt-0.5">{currentPersonaObj.description}</p>
            </div>
          </div>

          {/* Voice Toggle */}
          <button
            onClick={() => {
              setVoiceEnabled(!voiceEnabled);
              if (isSpeaking) window.speechSynthesis.cancel();
            }}
            className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              voiceEnabled ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30' : 'bg-slate-800 text-slate-400'
            }`}
          >
            {voiceEnabled ? <Volume2 className="w-4 h-4 text-cyan-400" /> : <VolumeX className="w-4 h-4" />}
            <span>Озвучка: {voiceEnabled ? 'ВКЛ' : 'ВЫКЛ'}</span>
          </button>
        </div>

        {/* Persona Selectors */}
        <div>
          <label className="block text-xs font-semibold text-slate-400 mb-2">ВЫБЕРИ ХАРАКТЕР РОБОТА:</label>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            {ROBOT_PERSONAS.map((p) => (
              <button
                key={p.id}
                onClick={() => onChangePersona(p.id)}
                className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                  persona === p.id
                    ? 'bg-slate-800 border-cyan-500 text-white shadow-md'
                    : 'bg-slate-950 border-slate-800 text-slate-400 hover:text-slate-200'
                }`}
              >
                <p className="text-xs font-bold text-slate-200">{p.name}</p>
                <p className="text-[10px] text-slate-400 line-clamp-1">{p.title}</p>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Chat Messages Log */}
      <div className="bg-slate-950 border border-slate-800 rounded-2xl p-4 sm:p-6 h-[480px] flex flex-col justify-between">
        <div className="overflow-y-auto space-y-4 pr-2 custom-scrollbar">
          {messages.map((msg) => (
            <div
              key={msg.id}
              className={`flex items-start gap-3 ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              {msg.sender === 'robot' && (
                <div className="w-8 h-8 rounded-full bg-cyan-500/20 border border-cyan-500/40 flex items-center justify-center shrink-0 mt-1">
                  <Bot className="w-4 h-4 text-cyan-400" />
                </div>
              )}

              <div className="max-w-[85%] sm:max-w-[75%] space-y-2">
                <div
                  className={`p-4 rounded-2xl text-sm leading-relaxed ${
                    msg.sender === 'user'
                      ? 'bg-gradient-to-r from-cyan-600 to-blue-600 text-white rounded-tr-none'
                      : 'bg-slate-900 border border-slate-800 text-slate-100 rounded-tl-none'
                  }`}
                >
                  <p className="whitespace-pre-wrap">{msg.text}</p>
                  <span className="block text-[10px] text-slate-400 mt-2 text-right">{msg.timestamp}</span>
                </div>

                {/* Robot Suggested Followups */}
                {msg.sender === 'robot' && msg.suggestedFollowups && msg.suggestedFollowups.length > 0 && (
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {msg.suggestedFollowups.map((fu, idx) => (
                      <button
                        key={idx}
                        onClick={() => handleSendMessage(fu)}
                        className="text-xs bg-slate-900 hover:bg-slate-800 text-cyan-300 border border-slate-800 hover:border-cyan-500/40 px-3 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1.5"
                      >
                        <CornerDownRight className="w-3 h-3 text-cyan-400" />
                        <span>{fu}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {msg.sender === 'user' && (
                <div className="w-8 h-8 rounded-full bg-indigo-500/20 border border-indigo-500/40 flex items-center justify-center shrink-0 mt-1">
                  <User className="w-4 h-4 text-indigo-400" />
                </div>
              )}
            </div>
          ))}

          {loading && (
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-cyan-500/20 border border-cyan-500/40 flex items-center justify-center shrink-0">
                <Bot className="w-4 h-4 text-cyan-400 animate-pulse" />
              </div>
              <div className="bg-slate-900 border border-slate-800 px-4 py-3 rounded-2xl rounded-tl-none flex items-center gap-2 text-xs text-slate-400">
                <RefreshCw className="w-3.5 h-3.5 animate-spin text-cyan-400" />
                <span>Робо-Тьютор думает...</span>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Input Bar */}
        <div className="mt-4 pt-3 border-t border-slate-800 flex items-center gap-2">
          <input
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
            placeholder="Задай вопрос Робо-Тьютору..."
            className="flex-1 bg-slate-900 border border-slate-800 rounded-xl px-4 py-3 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-cyan-500"
          />
          <button
            onClick={() => handleSendMessage()}
            disabled={loading || !inputText.trim()}
            className="p-3 bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-400 hover:to-blue-500 text-white rounded-xl transition-all disabled:opacity-50 cursor-pointer"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
};
