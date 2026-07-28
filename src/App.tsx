import React, { useState, useEffect } from 'react';
import { StudentProfile, AvatarConfig, ShopItem } from './types';
import { Header } from './components/Header';
import { HomeworkHelper } from './components/HomeworkHelper';
import { TopicExplainer } from './components/TopicExplainer';
import { QuestArena } from './components/QuestArena';
import { RobotChat } from './components/RobotChat';
import { AvatarWorkshop } from './components/AvatarWorkshop';
import { BookOpen, Lightbulb, Swords, MessageSquare, Sparkles, Trophy } from 'lucide-react';
import confetti from 'canvas-confetti';

const STORAGE_KEY = 'roboschool_student_profile_v1';

const INITIAL_PROFILE: StudentProfile = {
  name: 'Ученик',
  grade: 5,
  xp: 120,
  level: 1,
  streak: 3,
  lastActiveDate: new Date().toISOString().slice(0, 10),
  coins: 200,
  crystals: 10,
  energy: 10,
  maxEnergy: 10,
  selectedPersona: 'pixel',
  avatar: {
    bodyColor: '#06b6d4',
    eyeType: 'cute',
    headItem: 'antenna',
    bodyDecal: 'atom',
    auraColor: 'blue',
  },
  unlockedItems: ['antenna_neon', 'color_cyan', 'eye_cute', 'decal_atom'],
  unlockedBadges: ['first_question'],
  history: [],
};

export default function App() {
  const [profile, setProfile] = useState<StudentProfile>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        return { ...INITIAL_PROFILE, ...JSON.parse(saved) };
      }
    } catch (e) {
      console.error('Failed to load profile from localStorage', e);
    }
    return INITIAL_PROFILE;
  });

  const [activeTab, setActiveTab] = useState<'homework' | 'explain' | 'quests' | 'chat' | 'workshop'>('homework');
  const [levelUpMessage, setLevelUpMessage] = useState<string | null>(null);

  // Save profile to localStorage whenever it changes
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(profile));
    } catch (e) {
      console.error('Failed to save profile to localStorage', e);
    }
  }, [profile]);

  // Handle grade change
  const handleUpdateGrade = (newGrade: number) => {
    let persona = profile.selectedPersona;
    if (newGrade <= 4) persona = 'spark';
    else if (newGrade <= 8) persona = 'pixel';
    else persona = 'einstein';

    setProfile((prev) => ({
      ...prev,
      grade: newGrade,
      selectedPersona: persona,
    }));
  };

  // Reward handler for completing activities
  const handleEarnRewards = (earnedXp: number, earnedCoins: number) => {
    setProfile((prev) => {
      const newXp = prev.xp + earnedXp;
      const newCoins = prev.coins + earnedCoins;

      const currentLevel = prev.level;
      const nextLevelXp = currentLevel * 200;

      let newLevel = currentLevel;
      if (newXp >= nextLevelXp) {
        newLevel = currentLevel + 1;
        setLevelUpMessage(`🎉 ПОЗДРАВЛЯЕМ! ТЫ ДОСТИГ ${newLevel} УРОВНЯ! (+5 Кристаллов)`);
        confetti({
          particleCount: 150,
          spread: 100,
          origin: { y: 0.5 },
        });

        setTimeout(() => setLevelUpMessage(null), 5000);
      }

      return {
        ...prev,
        xp: newXp,
        level: newLevel,
        coins: newCoins,
        crystals: newLevel > currentLevel ? prev.crystals + 5 : prev.crystals,
      };
    });
  };

  // Buy Shop Item
  const handleBuyItem = (item: ShopItem): boolean => {
    if (item.currency === 'coins' && profile.coins < item.cost) return false;
    if (item.currency === 'crystals' && profile.crystals < item.cost) return false;

    setProfile((prev) => ({
      ...prev,
      coins: item.currency === 'coins' ? prev.coins - item.cost : prev.coins,
      crystals: item.currency === 'crystals' ? prev.crystals - item.cost : prev.crystals,
      unlockedItems: [...prev.unlockedItems, item.id],
    }));

    return true;
  };

  // Update Avatar config
  const handleUpdateAvatar = (newAvatar: AvatarConfig) => {
    setProfile((prev) => ({ ...prev, avatar: newAvatar }));
  };

  const navTabs = [
    { id: 'homework', label: 'Помощник с ДЗ', icon: BookOpen },
    { id: 'explain', label: 'Объяснялка 3.0', icon: Lightbulb },
    { id: 'quests', label: 'Арена Квестов', icon: Swords },
    { id: 'chat', label: 'Чат с Роботом', icon: MessageSquare },
    { id: 'workshop', label: 'Мастерская', icon: Sparkles },
  ] as const;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans selection:bg-cyan-500 selection:text-slate-950">
      {/* Top Navigation Header */}
      <Header
        profile={profile}
        onUpdateGrade={handleUpdateGrade}
        onOpenWorkshop={() => setActiveTab('workshop')}
      />

      {/* Level Up Banner Notification */}
      {levelUpMessage && (
        <div className="bg-gradient-to-r from-yellow-500 via-amber-500 to-indigo-600 text-slate-950 px-4 py-3 text-center text-sm font-extrabold flex items-center justify-center gap-2 shadow-xl animate-bounce">
          <Trophy className="w-5 h-5 fill-slate-950" />
          <span>{levelUpMessage}</span>
        </div>
      )}

      {/* Main Container */}
      <main className="max-w-7xl mx-auto px-4 py-6 space-y-6">
        {/* Navigation Tabs Bar */}
        <nav className="flex items-center gap-2 overflow-x-auto pb-2 custom-scrollbar border-b border-slate-800">
          {navTabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;

            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2 px-5 py-3 rounded-xl text-xs sm:text-sm font-bold whitespace-nowrap transition-all cursor-pointer ${
                  isActive
                    ? 'bg-gradient-to-r from-cyan-500 to-blue-600 text-white shadow-lg shadow-cyan-500/20 scale-102'
                    : 'bg-slate-900/80 text-slate-400 hover:text-slate-200 hover:bg-slate-800'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>

        {/* Tab Content Panes */}
        <div className="transition-all duration-300">
          {activeTab === 'homework' && (
            <HomeworkHelper
              grade={profile.grade}
              onEarnRewards={handleEarnRewards}
            />
          )}

          {activeTab === 'explain' && (
            <TopicExplainer
              grade={profile.grade}
              onEarnRewards={handleEarnRewards}
            />
          )}

          {activeTab === 'quests' && (
            <QuestArena
              grade={profile.grade}
              onEarnRewards={handleEarnRewards}
            />
          )}

          {activeTab === 'chat' && (
            <RobotChat
              grade={profile.grade}
              persona={profile.selectedPersona}
              onChangePersona={(p) => setProfile((prev) => ({ ...prev, selectedPersona: p }))}
              onEarnRewards={handleEarnRewards}
            />
          )}

          {activeTab === 'workshop' && (
            <AvatarWorkshop
              profile={profile}
              onUpdateAvatar={handleUpdateAvatar}
              onBuyItem={handleBuyItem}
            />
          )}
        </div>
      </main>

      {/* Footer */}
      <footer className="mt-12 py-6 border-t border-slate-900 text-center text-xs text-slate-500">
        <p>🤖 РобоШкола — Твой ИИ-помощник с 1 по 11 класс • Powered by Gemini 3.6 Flash</p>
      </footer>
    </div>
  );
}
