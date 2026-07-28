import React, { useState } from 'react';
import { Quest } from '../types';
import { SUBJECTS } from '../data/gradeData';
import { Swords, Sparkles, Award, Coins, RefreshCw, CheckCircle2, AlertTriangle, Play } from 'lucide-react';
import confetti from 'canvas-confetti';

interface QuestArenaProps {
  grade: number;
  onEarnRewards: (xp: number, coins: number) => void;
}

export const QuestArena: React.FC<QuestArenaProps> = ({ grade, onEarnRewards }) => {
  const [selectedSubject, setSelectedSubject] = useState<string>('Математика');
  const [difficulty, setDifficulty] = useState<'Базовый' | 'Продвинутый' | 'Олимпиадный'>('Базовый');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [quest, setQuest] = useState<Quest | null>(null);

  // Quest execution state
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const [questSubmitted, setQuestSubmitted] = useState<boolean>(false);

  const availableSubjects = SUBJECTS.filter((s) => grade >= s.minGrade && grade <= s.maxGrade);

  const handleGenerateQuest = async () => {
    setLoading(true);
    setError(null);
    setQuest(null);
    setSelectedOption(null);
    setQuestSubmitted(false);

    try {
      const response = await fetch('/api/ai/generate-quest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          grade,
          subject: selectedSubject,
          difficulty,
        }),
      });

      if (!response.ok) {
        const errData = await response.json();
        throw new Error(errData.error || 'Не удалось сгенерировать квест.');
      }

      const questData: Quest = await response.json();
      setQuest(questData);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Ошибка подключения к ИИ-Арене.');
    } finally {
      setLoading(false);
    }
  };

  const handleAnswerQuest = (optIdx: number) => {
    if (questSubmitted || !quest) return;
    setSelectedOption(optIdx);
    setQuestSubmitted(true);

    const isCorrect = optIdx === quest.task.correctIndex;
    if (isCorrect) {
      confetti({
        particleCount: 120,
        spread: 90,
        origin: { y: 0.6 },
      });
      onEarnRewards(quest.xpReward || 50, quest.coinsReward || 20);
    }
  };

  return (
    <div className="space-y-6">
      {/* Banner */}
      <div className="bg-gradient-to-r from-purple-900/40 via-indigo-900/40 to-slate-900 p-6 rounded-2xl border border-purple-800/50 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/20 text-purple-300 text-xs font-semibold mb-2">
            <Swords className="w-3.5 h-3.5" /> Игровая Арена Квестов ({grade} Класс)
          </div>
          <h2 className="text-2xl font-bold text-white">Интерактивные ИИ-Испытания</h2>
          <p className="text-slate-300 text-sm mt-1">
            Зарабатывай Монеты, Кристаллы и XP за прохождение персональных игровых задач!
          </p>
        </div>
      </div>

      {/* Controls */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-5">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-2">ПРЕДМЕТ КВЕСТА:</label>
            <select
              value={selectedSubject}
              onChange={(e) => setSelectedSubject(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-slate-100 font-semibold focus:outline-none focus:border-purple-500"
            >
              {availableSubjects.map((s) => (
                <option key={s.id} value={s.name}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-2">СЛОЖНОСТЬ:</label>
            <div className="flex gap-2">
              {(['Базовый', 'Продвинутый', 'Олимпиадный'] as const).map((lvl) => (
                <button
                  key={lvl}
                  onClick={() => setDifficulty(lvl)}
                  className={`flex-1 py-2 px-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                    difficulty === lvl
                      ? 'bg-purple-500 text-white shadow-md shadow-purple-500/30'
                      : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                  }`}
                >
                  {lvl}
                </button>
              ))}
            </div>
          </div>
        </div>

        {error && (
          <div className="flex items-center gap-2 p-3.5 bg-rose-500/10 border border-rose-500/30 text-rose-300 text-sm rounded-xl">
            <AlertTriangle className="w-5 h-5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <button
          onClick={handleGenerateQuest}
          disabled={loading}
          className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-purple-600 via-indigo-600 to-cyan-500 hover:from-purple-500 hover:to-cyan-400 text-white font-extrabold py-3.5 px-6 rounded-xl shadow-lg transition-all active:scale-98 disabled:opacity-50 cursor-pointer"
        >
          {loading ? (
            <>
              <RefreshCw className="w-5 h-5 animate-spin" />
              <span>Генерация случайного Квеста...</span>
            </>
          ) : (
            <>
              <Play className="w-5 h-5 fill-current" />
              <span>Сгенерировать Новый Квест</span>
            </>
          )}
        </button>
      </div>

      {/* Quest Card */}
      {quest && (
        <div className="bg-slate-900 border border-purple-500/40 rounded-2xl p-6 space-y-6 shadow-2xl animate-fade-in">
          {/* Header */}
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-800 pb-4">
            <div>
              <span className="text-xs font-bold text-purple-400 uppercase tracking-wider">{quest.subject} • {grade} Класс</span>
              <h3 className="text-xl font-extrabold text-white mt-1">{quest.title}</h3>
            </div>
            <div className="flex items-center gap-2">
              <span className="flex items-center gap-1 text-xs font-bold bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 px-3 py-1 rounded-full">
                <Award className="w-3.5 h-3.5 text-indigo-400" /> +{quest.xpReward} XP
              </span>
              <span className="flex items-center gap-1 text-xs font-bold bg-yellow-500/20 text-yellow-300 border border-yellow-500/30 px-3 py-1 rounded-full">
                <Coins className="w-3.5 h-3.5 text-yellow-400" /> +{quest.coinsReward} Монет
              </span>
            </div>
          </div>

          {/* Description Storyline */}
          <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-slate-200 text-sm leading-relaxed">
            <p className="font-medium">{quest.description}</p>
          </div>

          {/* Task Question & Options */}
          <div className="space-y-4">
            <h4 className="text-base font-bold text-white flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-purple-400" />
              <span>{quest.task.question}</span>
            </h4>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {quest.task.options.map((opt, idx) => {
                let btnStyle = 'bg-slate-950 border-slate-800 text-slate-200 hover:border-purple-500/50';

                if (selectedOption === idx) {
                  btnStyle = 'bg-purple-500/20 border-purple-500 text-purple-200 font-bold';
                }

                if (questSubmitted) {
                  if (idx === quest.task.correctIndex) {
                    btnStyle = 'bg-emerald-500/20 border-emerald-500 text-emerald-200 font-bold';
                  } else if (selectedOption === idx && idx !== quest.task.correctIndex) {
                    btnStyle = 'bg-rose-500/20 border-rose-500 text-rose-200';
                  }
                }

                return (
                  <button
                    key={idx}
                    disabled={questSubmitted}
                    onClick={() => handleAnswerQuest(idx)}
                    className={`p-4 rounded-xl border text-sm text-left transition-all cursor-pointer ${btnStyle}`}
                  >
                    {opt}
                  </button>
                );
              })}
            </div>

            {/* Explanation Result */}
            {questSubmitted && (
              <div
                className={`p-4 rounded-xl text-sm border space-y-1 ${
                  selectedOption === quest.task.correctIndex
                    ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-200'
                    : 'bg-rose-500/10 border-rose-500/30 text-rose-200'
                }`}
              >
                <div className="flex items-center gap-2 font-bold">
                  {selectedOption === quest.task.correctIndex ? (
                    <>
                      <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                      <span>Квест Покорён! Награда начислена! 🎉</span>
                    </>
                  ) : (
                    <>
                      <AlertTriangle className="w-5 h-5 text-rose-400" />
                      <span>Несовсем верно, но это тоже опыт!</span>
                    </>
                  )}
                </div>
                <p className="text-xs text-slate-300 pt-1 leading-relaxed">{quest.task.explanation}</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
