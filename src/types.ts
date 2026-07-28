export type GradeGroup = 'elementary' | 'middle' | 'high';

export interface StudentProfile {
  name: string;
  grade: number; // 1 to 11
  xp: number;
  level: number;
  streak: number;
  lastActiveDate: string;
  coins: number;
  crystals: number;
  energy: number;
  maxEnergy: number;
  selectedPersona: string; // 'spark' | 'einstein' | 'gramotei' | 'pixel'
  avatar: AvatarConfig;
  unlockedItems: string[];
  unlockedBadges: string[];
  history: ActivityItem[];
}

export interface AvatarConfig {
  bodyColor: string;
  eyeType: string; // 'cute' | 'cyber' | 'stars' | 'wink' | 'visor'
  headItem: string; // 'none' | 'antenna' | 'grad_cap' | 'crown' | 'headphones' | 'wizard_hat'
  bodyDecal: string; // 'none' | 'heart' | 'lightning' | 'atom' | 'code' | 'star'
  auraColor: string; // 'blue' | 'purple' | 'gold' | 'emerald' | 'fire'
}

export interface ShopItem {
  id: string;
  name: string;
  category: 'headItem' | 'bodyColor' | 'eyeType' | 'bodyDecal' | 'auraColor';
  value: string;
  cost: number;
  currency: 'coins' | 'crystals';
  requiredLevel: number;
  iconName: string;
  description: string;
}

export interface Badge {
  id: string;
  title: string;
  description: string;
  icon: string;
  unlocked: boolean;
  progress?: number;
  maxProgress?: number;
}

export interface ActivityItem {
  id: string;
  type: 'explanation' | 'homework' | 'quest' | 'chat';
  title: string;
  subject: string;
  date: string;
  xpEarned: number;
}

export interface Subject {
  id: string;
  name: string;
  icon: string;
  color: string;
  minGrade: number;
  maxGrade: number;
}

export interface ExplanationRequest {
  topic: string;
  grade: number;
  subject: string;
  difficulty: 'Базовый' | 'Продвинутый' | 'Олимпиадный';
}

export interface ExplanationResponse {
  simpleExplanation: string;
  analogy: string; // Friendly life/robot story analogy
  keyRules: string[];
  stepByStep: string[];
  funFact: string;
  quiz: QuizQuestion[];
}

export interface QuizQuestion {
  id: number;
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
}

export interface HomeworkCheckRequest {
  problemText: string;
  userAnswer: string;
  grade: number;
  subject: string;
}

export interface HomeworkCheckResponse {
  isCorrect: boolean | 'partial';
  feedback: string;
  encouragement: string;
  hints: string[];
  correctSolutionStepByStep?: string[];
  xpReward: number;
}

export interface Quest {
  id: string;
  title: string;
  description: string;
  subject: string;
  grade: number;
  difficulty: 'Базовый' | 'Продвинутый' | 'Олимпиадный';
  xpReward: number;
  coinsReward: number;
  task: {
    question: string;
    options: string[];
    correctIndex: number;
    explanation: string;
  };
  completed?: boolean;
}

export interface ChatMessage {
  id: string;
  sender: 'user' | 'robot';
  text: string;
  timestamp: string;
  suggestedFollowups?: string[];
}
