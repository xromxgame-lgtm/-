import React from 'react';
import { StudentProfile } from '../types';
import { RobotAvatar } from './RobotAvatar';
import { Flame, Zap, Coins, Gem, GraduationCap, Trophy, Sparkles } from 'lucide-react';

interface HeaderProps {
  profile: StudentProfile;
  onUpdateGrade: (grade: number) => void;
  onOpenWorkshop: () => void;
}

export const Header: React.FC<HeaderProps> = ({ profile, onUpdateGrade, onOpenWorkshop }) => {
  const nextLevelXp = profile.level * 200;
  const currentXpInLevel = profile.xp % nextLevelXp;
  const xpPercent = Math.min(100, Math.round((currentXpInLevel / nextLevelXp) * 100));

  return (
    <header className="bg-slate-900/90 backdrop-blur-md border-b border-slate-800 sticky top-0 z-40 px-4 py-3 text-white">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
        {/* Logo & Robot Quick Preview */}
        <div className="flex items-center gap-3 w-full md:w-auto justify-between md:justify-start">
          <div className="flex items-center gap-3 cursor-pointer group" onClick={onOpenWorkshop}>
            <div className="p-1 rounded-xl bg-slate-800 border border-slate-700 group-hover:border-cyan-500 transition-colors">
              <RobotAvatar config={profile.avatar} size="sm" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold tracking-wide bg-gradient-to-r from-cyan-400 via-sky-300 to-indigo-400 bg-clip-text text-transparent">
                  РобоШкола
                </h1>
                <span className="text-xs bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 px-2 py-0.5 rounded-full font-medium">
                  AI 3.6
                </span>
              </div>
              <p className="text-xs text-slate-400">Твой ИИ-Помощник & Тьютор</p>
            </div>
          </div>

          {/* Grade Selector Dropdown */}
          <div className="flex items-center gap-2 bg-slate-800/80 border border-slate-700 rounded-xl px-3 py-1.5">
            <GraduationCap className="w-4 h-4 text-cyan-400" />
            <select
              value={profile.grade}
              onChange={(e) => onUpdateGrade(Number(e.target.value))}
              className="bg-transparent text-sm font-semibold text-slate-200 outline-none cursor-pointer"
            >
              {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map((g) => (
                <option key={g} value={g} className="bg-slate-900 text-slate-100">
                  {g} Класс {g <= 4 ? '(Начальный)' : g <= 8 ? '(Средний)' : '(Старший)'}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Gamification Stats Bar */}
        <div className="flex items-center flex-wrap justify-center md:justify-end gap-3 w-full md:w-auto">
          {/* Level & XP Bar */}
          <div
            onClick={onOpenWorkshop}
            className="flex items-center gap-2 bg-slate-800/90 border border-slate-700/80 rounded-xl px-3 py-1.5 cursor-pointer hover:border-indigo-500 transition-all"
            title="Нажми чтобы открыть Мастерскую и Награды"
          >
            <div className="p-1 rounded-lg bg-indigo-500/20 text-indigo-400">
              <Trophy className="w-4 h-4" />
            </div>
            <div>
              <div className="flex items-center justify-between gap-2 text-xs">
                <span className="font-bold text-slate-200">Уровень {profile.level}</span>
                <span className="text-slate-400 font-mono">{currentXpInLevel}/{nextLevelXp} XP</span>
              </div>
              <div className="w-24 h-1.5 bg-slate-700 rounded-full overflow-hidden mt-1">
                <div
                  className="h-full bg-gradient-to-r from-cyan-400 to-indigo-500 rounded-full transition-all duration-500"
                  style={{ width: `${xpPercent}%` }}
                />
              </div>
            </div>
          </div>

          {/* Energy */}
          <div className="flex items-center gap-1.5 bg-amber-500/10 border border-amber-500/30 text-amber-300 rounded-xl px-3 py-1.5 text-xs font-bold">
            <Zap className="w-4 h-4 fill-amber-400 text-amber-400 animate-pulse" />
            <span>{profile.energy}/{profile.maxEnergy} Энергии</span>
          </div>

          {/* Coins */}
          <div className="flex items-center gap-1.5 bg-yellow-500/10 border border-yellow-500/30 text-yellow-300 rounded-xl px-3 py-1.5 text-xs font-bold">
            <Coins className="w-4 h-4 text-yellow-400" />
            <span>{profile.coins}</span>
          </div>

          {/* Crystals */}
          <div className="flex items-center gap-1.5 bg-purple-500/10 border border-purple-500/30 text-purple-300 rounded-xl px-3 py-1.5 text-xs font-bold">
            <Gem className="w-4 h-4 text-purple-400" />
            <span>{profile.crystals}</span>
          </div>

          {/* Streak */}
          <div className="flex items-center gap-1.5 bg-rose-500/10 border border-rose-500/30 text-rose-300 rounded-xl px-3 py-1.5 text-xs font-bold">
            <Flame className="w-4 h-4 text-rose-500 fill-rose-500 animate-bounce" />
            <span>{profile.streak} дн.</span>
          </div>

          {/* Customizer Button */}
          <button
            onClick={onOpenWorkshop}
            className="flex items-center gap-1.5 bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-400 hover:to-blue-500 text-white text-xs font-bold px-3 py-2 rounded-xl shadow-md transition-all active:scale-95 cursor-pointer"
          >
            <Sparkles className="w-4 h-4" />
            <span>Мастерская</span>
          </button>
        </div>
      </div>
    </header>
  );
};
