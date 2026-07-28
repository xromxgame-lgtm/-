import React, { useState } from 'react';
import { StudentProfile, ShopItem, AvatarConfig } from '../types';
import { SHOP_ITEMS, DEFAULT_BADGES } from '../data/gradeData';
import { RobotAvatar } from './RobotAvatar';
import { Sparkles, Coins, Gem, Award, Shield, Check, Lock, Palette, Trophy, Zap } from 'lucide-react';
import confetti from 'canvas-confetti';

interface AvatarWorkshopProps {
  profile: StudentProfile;
  onUpdateAvatar: (newAvatar: AvatarConfig) => void;
  onBuyItem: (item: ShopItem) => boolean;
}

export const AvatarWorkshop: React.FC<AvatarWorkshopProps> = ({
  profile,
  onUpdateAvatar,
  onBuyItem,
}) => {
  const [activeCategory, setActiveCategory] = useState<ShopItem['category']>('headItem');
  const [buyMessage, setBuyMessage] = useState<string | null>(null);

  const filteredItems = SHOP_ITEMS.filter((item) => item.category === activeCategory);

  const isUnlocked = (itemId: string) => profile.unlockedItems.includes(itemId);

  const handleEquipOrBuy = (item: ShopItem) => {
    if (isUnlocked(item.id)) {
      // Equip item
      const updatedAvatar: AvatarConfig = { ...profile.avatar };
      if (item.category === 'headItem') updatedAvatar.headItem = item.value;
      if (item.category === 'bodyColor') updatedAvatar.bodyColor = item.value;
      if (item.category === 'eyeType') updatedAvatar.eyeType = item.value;
      if (item.category === 'bodyDecal') updatedAvatar.bodyDecal = item.value;
      if (item.category === 'auraColor') updatedAvatar.auraColor = item.value;

      onUpdateAvatar(updatedAvatar);
      setBuyMessage(`Надет предмет: ${item.name}!`);
      setTimeout(() => setBuyMessage(null), 2500);
    } else {
      // Try buy
      const success = onBuyItem(item);
      if (success) {
        confetti({ particleCount: 70, spread: 60, origin: { y: 0.6 } });
        setBuyMessage(`Поздравляем! Вы купили "${item.name}"!`);
        setTimeout(() => setBuyMessage(null), 3000);

        // Equip immediately after buy
        const updatedAvatar: AvatarConfig = { ...profile.avatar };
        if (item.category === 'headItem') updatedAvatar.headItem = item.value;
        if (item.category === 'bodyColor') updatedAvatar.bodyColor = item.value;
        if (item.category === 'eyeType') updatedAvatar.eyeType = item.value;
        if (item.category === 'bodyDecal') updatedAvatar.bodyDecal = item.value;
        if (item.category === 'auraColor') updatedAvatar.auraColor = item.value;

        onUpdateAvatar(updatedAvatar);
      } else {
        setBuyMessage('Недостаточно монет или кристаллов для покупки!');
        setTimeout(() => setBuyMessage(null), 3000);
      }
    }
  };

  const categories: { id: ShopItem['category']; name: string }[] = [
    { id: 'headItem', name: 'Головной Убор' },
    { id: 'bodyColor', name: 'Цвет Корпуса' },
    { id: 'eyeType', name: 'Глаза / Выражение' },
    { id: 'bodyDecal', name: 'Символ / Эмблема' },
    { id: 'auraColor', name: 'Аура / Свечение' },
  ];

  return (
    <div className="space-y-8">
      {/* Banner */}
      <div className="bg-gradient-to-r from-cyan-900/40 via-blue-900/40 to-slate-900 p-6 rounded-2xl border border-cyan-800/50 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-500/20 text-cyan-300 text-xs font-semibold mb-2">
            <Palette className="w-3.5 h-3.5" /> Мастерская Робота & Награды
          </div>
          <h2 className="text-2xl font-bold text-white">Кастомизация Робота и Достижения</h2>
          <p className="text-slate-300 text-sm mt-1">
            Украшай своего робота за накопленные монеты и кристаллы! Повышай уровень для разблокировки редких аксессуаров.
          </p>
        </div>
      </div>

      {buyMessage && (
        <div className="p-4 bg-cyan-500/20 border border-cyan-500/40 rounded-xl text-center text-sm font-bold text-cyan-200 animate-bounce">
          {buyMessage}
        </div>
      )}

      {/* Main Workshop Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left: Live Avatar Stage */}
        <div className="lg:col-span-1 bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col items-center justify-center space-y-6">
          <h3 className="text-sm font-bold text-slate-400 tracking-wider">ТВОЙ ТЕКУЩИЙ РОБОТ:</h3>

          <div className="p-6 rounded-3xl bg-slate-950 border border-cyan-500/30 relative">
            <RobotAvatar config={profile.avatar} size="xl" />
          </div>

          {/* Quick Wallet Summary */}
          <div className="flex items-center justify-center gap-4 w-full pt-2 border-t border-slate-800">
            <div className="flex items-center gap-1.5 text-yellow-400 font-bold text-sm bg-yellow-500/10 border border-yellow-500/20 px-3 py-1.5 rounded-xl">
              <Coins className="w-4 h-4" />
              <span>{profile.coins} Монет</span>
            </div>
            <div className="flex items-center gap-1.5 text-purple-400 font-bold text-sm bg-purple-500/10 border border-purple-500/20 px-3 py-1.5 rounded-xl">
              <Gem className="w-4 h-4" />
              <span>{profile.crystals} Кристаллов</span>
            </div>
          </div>
        </div>

        {/* Right: Shop Catalogue */}
        <div className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
          <h3 className="text-base font-bold text-white flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-cyan-400" />
            <span>Магазин Мастерской</span>
          </h3>

          {/* Category Tabs */}
          <div className="flex flex-wrap gap-2">
            {categories.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setActiveCategory(cat.id)}
                className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  activeCategory === cat.id
                    ? 'bg-cyan-500 text-slate-950 shadow-md shadow-cyan-500/20'
                    : 'bg-slate-950 text-slate-400 hover:text-slate-200 border border-slate-800'
                }`}
              >
                {cat.name}
              </button>
            ))}
          </div>

          {/* Items Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {filteredItems.map((item) => {
              const unlocked = isUnlocked(item.id);
              const isEquipped =
                (item.category === 'headItem' && profile.avatar.headItem === item.value) ||
                (item.category === 'bodyColor' && profile.avatar.bodyColor === item.value) ||
                (item.category === 'eyeType' && profile.avatar.eyeType === item.value) ||
                (item.category === 'bodyDecal' && profile.avatar.bodyDecal === item.value) ||
                (item.category === 'auraColor' && profile.avatar.auraColor === item.value);

              const levelRequirementMet = profile.level >= item.requiredLevel;

              return (
                <div
                  key={item.id}
                  className={`p-4 rounded-xl border transition-all flex flex-col justify-between space-y-3 ${
                    isEquipped
                      ? 'bg-cyan-950/40 border-cyan-500/80'
                      : unlocked
                      ? 'bg-slate-950 border-slate-800'
                      : 'bg-slate-950/60 border-slate-800/80 opacity-85'
                  }`}
                >
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-bold text-white">{item.name}</span>
                      {isEquipped ? (
                        <span className="text-[10px] bg-cyan-500 text-slate-950 px-2 py-0.5 rounded-full font-bold">
                          Надето
                        </span>
                      ) : unlocked ? (
                        <span className="text-[10px] bg-emerald-500/20 text-emerald-400 px-2 py-0.5 rounded-full font-bold">
                          Куплено
                        </span>
                      ) : (
                        <span className="text-[10px] text-slate-400 font-semibold">
                          Треб. {item.requiredLevel} Ур.
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-slate-400 mt-1">{item.description}</p>
                  </div>

                  <div className="flex items-center justify-between pt-2 border-t border-slate-800/80">
                    {!unlocked && (
                      <div className="flex items-center gap-1 text-xs font-bold">
                        {item.currency === 'coins' ? (
                          <span className="text-yellow-400 flex items-center gap-1">
                            <Coins className="w-3.5 h-3.5" /> {item.cost}
                          </span>
                        ) : (
                          <span className="text-purple-400 flex items-center gap-1">
                            <Gem className="w-3.5 h-3.5" /> {item.cost}
                          </span>
                        )}
                      </div>
                    )}

                    <button
                      onClick={() => handleEquipOrBuy(item)}
                      disabled={!unlocked && !levelRequirementMet}
                      className={`w-full py-2 px-3 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                        isEquipped
                          ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30'
                          : unlocked
                          ? 'bg-slate-800 hover:bg-slate-700 text-white'
                          : levelRequirementMet
                          ? 'bg-gradient-to-r from-yellow-500 to-amber-600 hover:from-yellow-400 hover:to-amber-500 text-slate-950'
                          : 'bg-slate-800/50 text-slate-500 cursor-not-allowed'
                      }`}
                    >
                      {isEquipped ? (
                        <>
                          <Check className="w-3.5 h-3.5 text-cyan-400" />
                          <span>Надето</span>
                        </>
                      ) : unlocked ? (
                        <span>Надеть</span>
                      ) : levelRequirementMet ? (
                        <span>Купить</span>
                      ) : (
                        <>
                          <Lock className="w-3.5 h-3.5" />
                          <span>Закрыто (Ур. {item.requiredLevel})</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Achievements / Badges Section */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
        <h3 className="text-base font-bold text-white flex items-center gap-2">
          <Trophy className="w-5 h-5 text-yellow-400" />
          <span>Галерея Достижений и Медалей</span>
        </h3>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          {DEFAULT_BADGES.map((b) => (
            <div
              key={b.id}
              className={`p-4 rounded-xl border flex items-start gap-3 transition-all ${
                b.unlocked
                  ? 'bg-slate-950 border-yellow-500/40 shadow-lg shadow-yellow-500/5'
                  : 'bg-slate-950/50 border-slate-800/80 opacity-70'
              }`}
            >
              <div
                className={`p-2.5 rounded-xl shrink-0 ${
                  b.unlocked ? 'bg-yellow-500/20 text-yellow-400' : 'bg-slate-800 text-slate-500'
                }`}
              >
                <Award className="w-6 h-6" />
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-1.5">
                  <h4 className="text-sm font-bold text-white">{b.title}</h4>
                  {b.unlocked && <span className="text-xs text-yellow-400">✓</span>}
                </div>
                <p className="text-xs text-slate-400">{b.description}</p>
                {b.maxProgress && (
                  <div className="w-full bg-slate-800 h-1.5 rounded-full overflow-hidden mt-2">
                    <div
                      className="bg-yellow-400 h-full transition-all"
                      style={{ width: `${Math.min(100, Math.round(((b.progress || 0) / b.maxProgress) * 100))}%` }}
                    />
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
