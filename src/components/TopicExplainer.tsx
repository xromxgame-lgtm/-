import React, { useState } from 'react';
import { ExplanationResponse } from '../types';
import { POPULAR_TOPICS_BY_GRADE, SUBJECTS } from '../data/gradeData';
import { Lightbulb, Sparkles, CheckCircle2, XCircle, Award, ArrowRight, RefreshCw, AlertTriangle, BookOpen, Smile } from 'lucide-react';
import confetti from 'canvas-confetti';

interface TopicExplainerProps {
  grade: number;
  onEarnRewards: (xp: number, coins: number) => void;
}

export const TopicExplainer: React.FC<TopicExplainerProps> = ({ grade, onEarnRewards }) => {
  const [topic, setTopic] = useState<string>('');
  const [selectedSubject, setSelectedSubject] = useState<string>('Математика');
  const [difficulty, setDifficulty] = useState<'Базовый' | 'Продвинутый' | 'Олимпиадный'>('Базовый');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<ExplanationResponse | null>(null);

  // Quiz state
  const [quizAnswers, setQuizAnswers] = useState<Record<number, number>>({});
  const [quizSubmitted, setQuizSubmitted] = useState<boolean>(false);

  const popularTopics = POPULAR_TOPICS_BY_GRADE[grade] || POPULAR_TOPICS_BY_GRADE[5];
  const availableSubjects = SUBJECTS.filter((s) => grade >= s.minGrade && grade <= s.maxGrade);

  const handleExplainTopic = async (topicToExplain?: string) => {
    const targetTopic = topicToExplain || topic;
    if (!targetTopic.trim()) {
      setError('Укажите тему для объяснения!');
      return;
    }

    setLoading(true);
    setError(null);
    setData(null);
    setQuizAnswers({});
    setQuizSubmitted(false);

    try {
      const response = await fetch('/api/ai/explain', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          topic: targetTopic,
          grade,
          subject: selectedSubject,
          difficulty,
        }),
      });

      if (!response.ok) {
        const errData = await response.json();
        throw new Error(errData.error || 'Ошибка сгенерированного объяснения.');
      }

      const result: ExplanationResponse = await response.json();
      setData(result);
      onEarnRewards(20, 5); // baseline reward for reading topic
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Ошибка соединения с сервером.');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectQuizAnswer = (qId: number, optionIdx: number) => {
    if (quizSubmitted) return;
    setQuizAnswers((prev) => ({ ...prev, [qId]: optionIdx }));
  };

  const handleSubmitQuiz = () => {
    if (!data || !data.quiz) return;
    setQuizSubmitted(true);

    let correctCount = 0;
    data.quiz.forEach((q) => {
      if (quizAnswers[q.id] === q.correctIndex) {
        correctCount++;
      }
    });

    const xpWon = correctCount * 30 + 20;
    const coinsWon = correctCount * 15;

    if (correctCount > 0) {
      confetti({
        particleCount: 100,
        spread: 80,
        origin: { y: 0.6 },
      });
    }

    onEarnRewards(xpWon, coinsWon);
  };

  return (
    <div className="space-y-6">
      {/* Banner */}
      <div className="bg-gradient-to-r from-emerald-900/40 via-teal-900/40 to-slate-900 p-6 rounded-2xl border border-teal-800/50 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-teal-500/20 text-teal-300 text-xs font-semibold mb-2">
            <Lightbulb className="w-3.5 h-3.5" /> Объяснялка 3.0 ({grade} Класс)
          </div>
          <h2 className="text-2xl font-bold text-white">Объяснение Любой Сложной Темы</h2>
          <p className="text-slate-300 text-sm mt-1">
            Не понял тему в школе? Выбери предмет, введи термин или выбери из списка — РобоШкола объяснит на наглядных примерах с викториной!
          </p>
        </div>
      </div>

      {/* Input controls */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-5">
        {/* Subject & Difficulty Selectors */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-2">ПРЕДМЕТ:</label>
            <select
              value={selectedSubject}
              onChange={(e) => setSelectedSubject(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-slate-100 font-semibold focus:outline-none focus:border-teal-500"
            >
              {availableSubjects.map((s) => (
                <option key={s.id} value={s.name}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-2">УРОВЕНЬ СЛОЖНОСТИ:</label>
            <div className="flex gap-2">
              {(['Базовый', 'Продвинутый', 'Олимпиадный'] as const).map((lvl) => (
                <button
                  key={lvl}
                  onClick={() => setDifficulty(lvl)}
                  className={`flex-1 py-2 px-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                    difficulty === lvl
                      ? 'bg-teal-500 text-slate-950 shadow-md shadow-teal-500/20'
                      : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                  }`}
                >
                  {lvl}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Topic Input */}
        <div>
          <label className="block text-xs font-semibold text-slate-400 mb-2">ТЕМА ИЛИ ТЕРМИН:</label>
          <div className="flex flex-col sm:flex-row gap-2">
            <input
              type="text"
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
              placeholder="Например: Фотосинтез, Теорема Пифагора, Дроби, Падежи..."
              className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-teal-500"
            />
            <button
              onClick={() => handleExplainTopic()}
              disabled={loading || !topic.trim()}
              className="flex items-center justify-center gap-2 bg-gradient-to-r from-teal-500 to-emerald-600 hover:from-teal-400 hover:to-emerald-500 text-slate-950 font-extrabold px-6 py-3 rounded-xl shadow-lg transition-all active:scale-95 disabled:opacity-50 cursor-pointer"
            >
              {loading ? (
                <RefreshCw className="w-5 h-5 animate-spin" />
              ) : (
                <>
                  <Sparkles className="w-5 h-5" />
                  <span>Объяснить!</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Popular Topics by Grade */}
        <div>
          <span className="text-xs text-slate-400 font-semibold block mb-2">
            Популярные темы для {grade} класса:
          </span>
          <div className="flex flex-wrap gap-2">
            {popularTopics.map((pt, idx) => (
              <button
                key={idx}
                onClick={() => {
                  setTopic(pt.topic);
                  setSelectedSubject(pt.subject);
                  handleExplainTopic(pt.topic);
                }}
                className="text-xs bg-slate-800/90 hover:bg-slate-700 text-slate-200 border border-slate-700 px-3 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1.5"
              >
                <span className="text-teal-400 font-bold">•</span>
                <span>{pt.subject}:</span>
                <span className="font-semibold">{pt.topic}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Error */}
        {error && (
          <div className="flex items-center gap-2 p-3.5 bg-rose-500/10 border border-rose-500/30 text-rose-300 text-sm rounded-xl">
            <AlertTriangle className="w-5 h-5 shrink-0" />
            <span>{error}</span>
          </div>
        )}
      </div>

      {/* Result Display */}
      {data && (
        <div className="bg-slate-900 border border-teal-500/40 rounded-2xl p-6 space-y-6 shadow-2xl animate-fade-in">
          {/* Main Explanation */}
          <div className="space-y-3">
            <div className="flex items-center gap-2 text-teal-400 font-bold text-sm">
              <BookOpen className="w-5 h-5" />
              <span>ПРОСТЫМИ СЛОВАМИ:</span>
            </div>
            <p className="text-base text-slate-100 leading-relaxed bg-slate-950 p-4 rounded-xl border border-slate-800">
              {data.simpleExplanation}
            </p>
          </div>

          {/* Life / Robot Analogy */}
          {data.analogy && (
            <div className="p-4 rounded-xl bg-amber-500/10 border border-amber-500/30 space-y-2">
              <div className="flex items-center gap-2 text-amber-300 font-bold text-sm">
                <Smile className="w-5 h-5 text-amber-400" />
                <span>НАГЛЯДНАЯ АНАЛОГИЯ:</span>
              </div>
              <p className="text-sm text-amber-100 leading-relaxed">{data.analogy}</p>
            </div>
          )}

          {/* Key Rules / Formulas */}
          {data.keyRules && data.keyRules.length > 0 && (
            <div className="space-y-3">
              <h4 className="text-xs font-bold text-slate-400 tracking-wider">ГЛАВНЫЕ ПРАВИЛА И ФОРМУЛЫ:</h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {data.keyRules.map((rule, idx) => (
                  <div key={idx} className="p-3.5 bg-slate-950 border border-slate-800 rounded-xl flex items-start gap-2.5">
                    <span className="w-2 h-2 rounded-full bg-teal-400 mt-2 shrink-0" />
                    <span className="text-sm text-slate-200 font-medium leading-snug">{rule}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Step-by-Step Example */}
          {data.stepByStep && data.stepByStep.length > 0 && (
            <div className="space-y-3">
              <h4 className="text-xs font-bold text-slate-400 tracking-wider">ПРИМЕР И АЛГОРИТМ:</h4>
              <div className="space-y-2">
                {data.stepByStep.map((s, idx) => (
                  <div key={idx} className="flex items-start gap-3 bg-slate-950 p-3 rounded-xl border border-slate-800">
                    <span className="w-6 h-6 rounded-lg bg-teal-500/20 text-teal-300 text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">
                      {idx + 1}
                    </span>
                    <span className="text-sm text-slate-200">{s}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Fun Fact */}
          {data.funFact && (
            <div className="p-3.5 bg-indigo-950/40 border border-indigo-800/60 rounded-xl text-xs text-indigo-200 flex items-center gap-3">
              <Sparkles className="w-5 h-5 text-indigo-400 shrink-0" />
              <span><strong>Робо-Факт:</strong> {data.funFact}</span>
            </div>
          )}

          {/* Interactive Quiz Section */}
          {data.quiz && data.quiz.length > 0 && (
            <div className="p-6 rounded-2xl bg-slate-950 border border-slate-800 space-y-5">
              <div className="flex items-center justify-between border-b border-slate-800 pb-3">
                <div className="flex items-center gap-2">
                  <Award className="w-5 h-5 text-yellow-400" />
                  <h3 className="text-base font-bold text-white">Мини-Тест на Закрепление</h3>
                </div>
                <span className="text-xs text-teal-400 font-semibold bg-teal-500/10 border border-teal-500/20 px-2.5 py-1 rounded-full">
                  До +110 XP
                </span>
              </div>

              <div className="space-y-6">
                {data.quiz.map((q) => {
                  const selectedOpt = quizAnswers[q.id];
                  const isCorrect = selectedOpt === q.correctIndex;

                  return (
                    <div key={q.id} className="space-y-3 bg-slate-900 p-4 rounded-xl border border-slate-800">
                      <p className="text-sm font-bold text-slate-100">{q.id}. {q.question}</p>
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                        {q.options.map((opt, optIdx) => {
                          let optStyle = 'bg-slate-950 border-slate-800 text-slate-300 hover:border-slate-700';

                          if (selectedOpt === optIdx) {
                            optStyle = 'bg-cyan-500/20 border-cyan-500 text-cyan-200 font-semibold';
                          }

                          if (quizSubmitted) {
                            if (optIdx === q.correctIndex) {
                              optStyle = 'bg-emerald-500/20 border-emerald-500 text-emerald-200 font-bold';
                            } else if (selectedOpt === optIdx && !isCorrect) {
                              optStyle = 'bg-rose-500/20 border-rose-500 text-rose-200';
                            }
                          }

                          return (
                            <button
                              key={optIdx}
                              onClick={() => handleSelectQuizAnswer(q.id, optIdx)}
                              className={`p-3 rounded-xl border text-xs text-left transition-all cursor-pointer ${optStyle}`}
                            >
                              {opt}
                            </button>
                          );
                        })}
                      </div>

                      {/* Explanation after submit */}
                      {quizSubmitted && (
                        <div className={`p-3 rounded-lg text-xs mt-2 ${isCorrect ? 'bg-emerald-500/10 text-emerald-300' : 'bg-rose-500/10 text-rose-300'}`}>
                          <strong>{isCorrect ? 'Верно! ' : 'Ошибка! '}</strong> {q.explanation}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>

              {!quizSubmitted ? (
                <button
                  onClick={handleSubmitQuiz}
                  disabled={Object.keys(quizAnswers).length < data.quiz.length}
                  className="w-full py-3 bg-gradient-to-r from-teal-500 to-emerald-600 hover:from-teal-400 hover:to-emerald-500 text-slate-950 font-bold rounded-xl transition-all disabled:opacity-50 cursor-pointer"
                >
                  Проверить Ответы и Получить Награду!
                </button>
              ) : (
                <div className="p-4 bg-teal-500/10 border border-teal-500/30 rounded-xl text-center space-y-1">
                  <p className="text-sm font-bold text-teal-300">🎉 Викторина пройдена!</p>
                  <p className="text-xs text-slate-300">
                    Награда начислена в ваш профиль. Попробуйте изучить еще одну тему!
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
