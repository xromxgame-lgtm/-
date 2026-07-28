import React, { useState } from 'react';
import { HomeworkCheckResponse } from '../types';
import { SUBJECTS } from '../data/gradeData';
import { BookOpen, Sparkles, CheckCircle2, HelpCircle, ArrowRight, Lightbulb, RefreshCw, Send, AlertTriangle } from 'lucide-react';
import confetti from 'canvas-confetti';

interface HomeworkHelperProps {
  grade: number;
  onEarnRewards: (xp: number, coins: number) => void;
}

export const HomeworkHelper: React.FC<HomeworkHelperProps> = ({ grade, onEarnRewards }) => {
  const [subject, setSubject] = useState<string>('Математика');
  const [problemText, setProblemText] = useState<string>('');
  const [userDraftAnswer, setUserDraftAnswer] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<HomeworkCheckResponse | null>(null);

  // Self-check verification state
  const [selfCheckInput, setSelfCheckInput] = useState<string>('');
  const [selfCheckDone, setSelfCheckDone] = useState<boolean>(false);

  const availableSubjects = SUBJECTS.filter((s) => grade >= s.minGrade && grade <= s.maxGrade);

  const samplePrompts = [
    'Реши и объясни уравнение: 2x + 10 = 34',
    'Какое правило используется при написании жи-ши?',
    'Найди плотность тела массой 500г и объемом 250см³',
    'Разбери словосочетание по составу и частям речи',
  ];

  const handleSolveHomework = async () => {
    if (!problemText.trim()) {
      setError('Пожалуйста, введите текст задания или вопрос!');
      return;
    }

    setLoading(true);
    setError(null);
    setResult(null);
    setSelfCheckDone(false);
    setSelfCheckInput('');

    try {
      const response = await fetch('/api/ai/check-homework', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          problemText,
          userAnswer: userDraftAnswer,
          grade,
          subject,
        }),
      });

      if (!response.ok) {
        const errData = await response.json();
        throw new Error(errData.error || 'Ошибка загрузки разбора задания.');
      }

      const data: HomeworkCheckResponse = await response.json();
      setResult(data);

      // Award baseline XP for submitting homework
      onEarnRewards(30, 10);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Произошла ошибка при связи с сервером.');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifySelfCheck = () => {
    if (!selfCheckInput.trim()) return;
    setSelfCheckDone(true);
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 },
    });
    onEarnRewards(50, 20);
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-blue-900/40 via-indigo-900/40 to-slate-900 p-6 rounded-2xl border border-indigo-800/50 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-500/20 text-indigo-300 text-xs font-semibold mb-2">
            <BookOpen className="w-3.5 h-3.5" /> ИИ-Помощник по ДЗ ({grade} Класс)
          </div>
          <h2 className="text-2xl font-bold text-white">Разбор Домашнего Задания</h2>
          <p className="text-slate-300 text-sm mt-1">
            Введи условие задачи, пример или упражнение. РобоШкола разберёт решение по шагам и объяснит непонятные моменты!
          </p>
        </div>
      </div>

      {/* Input Section */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-5">
        {/* Subject selection */}
        <div>
          <label className="block text-xs font-semibold text-slate-400 mb-2">ВЫБЕРИ ПРЕДМЕТ:</label>
          <div className="flex flex-wrap gap-2">
            {availableSubjects.map((s) => (
              <button
                key={s.id}
                onClick={() => setSubject(s.name)}
                className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  subject === s.name
                    ? 'bg-cyan-500 text-slate-950 shadow-lg shadow-cyan-500/25 scale-105'
                    : 'bg-slate-800 text-slate-300 hover:bg-slate-700 hover:text-white'
                }`}
              >
                <span>{s.name}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Problem textarea */}
        <div>
          <label className="block text-xs font-semibold text-slate-400 mb-2">
            УСЛОВИЕ ЗАДАЧИ ИЛИ УПРАЖНЕНИЯ:
          </label>
          <textarea
            rows={3}
            value={problemText}
            onChange={(e) => setProblemText(e.target.value)}
            placeholder="Вставьте условие задачи, уравнение или текст из учебника..."
            className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3.5 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-cyan-500 transition-colors resize-y"
          />
        </div>

        {/* User draft answer optional input */}
        <div>
          <label className="block text-xs font-semibold text-slate-400 mb-2">
            ТВОЙ ТЕКУЩИЙ ОТВЕТ ИЛИ ЧЕРНОВИК (НЕОБЯЗАТЕЛЬНО):
          </label>
          <input
            type="text"
            value={userDraftAnswer}
            onChange={(e) => setUserDraftAnswer(e.target.value)}
            placeholder="Например: 'У меня получилось x = 12, не уверен верно ли'"
            className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-indigo-500 transition-colors"
          />
        </div>

        {/* Sample Prompt Chips */}
        <div>
          <span className="text-xs text-slate-500 mr-2">Примеры для быстрого ввода:</span>
          <div className="flex flex-wrap gap-2 mt-2">
            {samplePrompts.map((prompt, idx) => (
              <button
                key={idx}
                onClick={() => setProblemText(prompt)}
                className="text-xs bg-slate-800/80 hover:bg-slate-700 text-slate-300 px-3 py-1.5 rounded-lg border border-slate-700 transition-colors cursor-pointer"
              >
                "{prompt}"
              </button>
            ))}
          </div>
        </div>

        {/* Error notification */}
        {error && (
          <div className="flex items-center gap-2 p-3.5 bg-rose-500/10 border border-rose-500/30 text-rose-300 text-sm rounded-xl">
            <AlertTriangle className="w-5 h-5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Submit button */}
        <button
          onClick={handleSolveHomework}
          disabled={loading}
          className="w-full sm:w-auto flex items-center justify-center gap-2 bg-gradient-to-r from-cyan-500 via-blue-600 to-indigo-600 hover:from-cyan-400 hover:to-indigo-500 text-white font-bold px-8 py-3.5 rounded-xl shadow-lg shadow-cyan-500/20 transition-all active:scale-98 disabled:opacity-50 cursor-pointer"
        >
          {loading ? (
            <>
              <RefreshCw className="w-5 h-5 animate-spin" />
              <span>РобоШкола разбирает задание...</span>
            </>
          ) : (
            <>
              <Sparkles className="w-5 h-5" />
              <span>Разобрать и Объяснить (+30 XP)</span>
            </>
          )}
        </button>
      </div>

      {/* AI Solution Response Card */}
      {result && (
        <div className="bg-slate-900 border border-cyan-500/40 rounded-2xl p-6 space-y-6 shadow-2xl animate-fade-in">
          {/* Header Feedback */}
          <div className="flex items-start gap-4 p-4 rounded-xl bg-slate-800/80 border border-slate-700">
            <div className="p-2.5 bg-cyan-500/20 text-cyan-400 rounded-xl">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <span>Разбор от РобоШколы</span>
                {result.isCorrect === true && (
                  <span className="text-xs bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 px-2.5 py-0.5 rounded-full font-semibold">
                    Всё верно! 🎉
                  </span>
                )}
              </h3>
              <p className="text-slate-300 text-sm mt-1">{result.feedback}</p>
              <p className="text-cyan-400 text-xs font-semibold mt-2">💡 {result.encouragement}</p>
            </div>
          </div>

          {/* Hints Section */}
          {result.hints && result.hints.length > 0 && (
            <div className="space-y-2">
              <h4 className="text-xs font-bold text-slate-400 tracking-wider flex items-center gap-1.5">
                <Lightbulb className="w-4 h-4 text-amber-400" />
                НАВОДЯЩИЕ ПОДСКАЗКИ И КЛЮЧЕВЫЕ МЫСЛИ:
              </h4>
              <ul className="space-y-1.5 pl-2">
                {result.hints.map((hint, idx) => (
                  <li key={idx} className="text-sm text-slate-300 flex items-start gap-2 bg-slate-950/60 p-2.5 rounded-lg border border-slate-800/80">
                    <span className="text-cyan-400 font-bold">•</span>
                    <span>{hint}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Step-by-Step Solution */}
          {result.correctSolutionStepByStep && result.correctSolutionStepByStep.length > 0 && (
            <div className="space-y-3">
              <h4 className="text-xs font-bold text-slate-400 tracking-wider flex items-center gap-1.5">
                <ArrowRight className="w-4 h-4 text-cyan-400" />
                ПОШАГОВОЕ РЕШЕНИЕ:
              </h4>
              <div className="space-y-2.5">
                {result.correctSolutionStepByStep.map((step, idx) => (
                  <div key={idx} className="flex items-start gap-3 bg-slate-950 p-3.5 rounded-xl border border-slate-800">
                    <div className="w-6 h-6 rounded-full bg-cyan-500/20 text-cyan-300 text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">
                      {idx + 1}
                    </div>
                    <p className="text-sm text-slate-200 leading-relaxed">{step}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Interactive Self-Check Verification */}
          <div className="p-4 rounded-xl bg-indigo-950/40 border border-indigo-800/60 space-y-3">
            <h4 className="text-sm font-bold text-indigo-200 flex items-center gap-2">
              <HelpCircle className="w-4 h-4 text-indigo-400" />
              Проверь себя! Запиши финальный ответ сам:
            </h4>
            <div className="flex flex-col sm:flex-row gap-2">
              <input
                type="text"
                value={selfCheckInput}
                onChange={(e) => setSelfCheckInput(e.target.value)}
                placeholder="Введи свой итоговый ответ..."
                disabled={selfCheckDone}
                className="flex-1 bg-slate-950 border border-slate-700 rounded-xl px-3.5 py-2 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-indigo-400"
              />
              <button
                onClick={handleVerifySelfCheck}
                disabled={selfCheckDone || !selfCheckInput.trim()}
                className="flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white font-bold px-5 py-2 rounded-xl text-sm transition-all disabled:opacity-50 cursor-pointer"
              >
                {selfCheckDone ? (
                  <>
                    <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                    <span>Принято! (+50 XP)</span>
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    <span>Подтвердить</span>
                  </>
                )}
              </button>
            </div>
            {selfCheckDone && (
              <p className="text-xs text-emerald-400 font-semibold animate-bounce">
                🌟 Молодец! Ты успешно усвоил решение и получил +50 XP и +20 Монет!
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
