import { Subject, ShopItem, Badge } from '../types';

export const SUBJECTS: Subject[] = [
  { id: 'math', name: 'Математика', icon: 'Calculator', color: 'from-blue-500 to-cyan-500', minGrade: 1, maxGrade: 11 },
  { id: 'russian', name: 'Русский язык', icon: 'BookOpen', color: 'from-amber-500 to-orange-500', minGrade: 1, maxGrade: 11 },
  { id: 'literature', name: 'Литература', icon: 'BookMarked', color: 'from-purple-500 to-indigo-500', minGrade: 1, maxGrade: 11 },
  { id: 'world', name: 'Окружающий мир', icon: 'Globe', color: 'from-emerald-500 to-teal-500', minGrade: 1, maxGrade: 4 },
  { id: 'physics', name: 'Физика', icon: 'Zap', color: 'from-rose-500 to-red-500', minGrade: 7, maxGrade: 11 },
  { id: 'chemistry', name: 'Химия', icon: 'FlaskConical', color: 'from-fuchsia-500 to-pink-500', minGrade: 8, maxGrade: 11 },
  { id: 'biology', name: 'Биология', icon: 'Dna', color: 'from-green-500 to-emerald-600', minGrade: 5, maxGrade: 11 },
  { id: 'history', name: 'История', icon: 'Landmark', color: 'from-yellow-600 to-amber-700', minGrade: 5, maxGrade: 11 },
  { id: 'english', name: 'Английский язык', icon: 'Languages', color: 'from-sky-500 to-blue-600', minGrade: 2, maxGrade: 11 },
  { id: 'informatics', name: 'Информатика', icon: 'Code', color: 'from-violet-500 to-purple-600', minGrade: 5, maxGrade: 11 },
  { id: 'geography', name: 'География', icon: 'Compass', color: 'from-teal-500 to-cyan-600', minGrade: 5, maxGrade: 11 },
];

export const POPULAR_TOPICS_BY_GRADE: Record<number, { subject: string; topic: string }[]> = {
  1: [
    { subject: 'Математика', topic: 'Сложение и вычитание в пределах 20' },
    { subject: 'Русский язык', topic: 'Гласные и согласные звуки' },
    { subject: 'Окружающий мир', topic: 'Живая и неживая природа' },
  ],
  2: [
    { subject: 'Математика', topic: 'Таблица умножения на 2 и 3' },
    { subject: 'Русский язык', topic: 'Имя существительное и глагол' },
    { subject: 'Окружающий мир', topic: 'Смена времен года' },
  ],
  3: [
    { subject: 'Математика', topic: 'Периметр и площадь прямоугольника' },
    { subject: 'Русский язык', topic: 'Части речи и безударные гласные' },
    { subject: 'Окружающий мир', topic: 'Круговорот воды в природе' },
  ],
  4: [
    { subject: 'Математика', topic: 'Деление в столбик и дроби' },
    { subject: 'Русский язык', topic: 'Падежи имен существительных' },
    { subject: 'Окружающий мир', topic: 'Природные зоны России' },
  ],
  5: [
    { subject: 'Математика', topic: 'Десятичные дроби и проценты' },
    { subject: 'Русский язык', topic: 'Синтаксический разбор предложения' },
    { subject: 'История', topic: 'Древний Египет и пирамиды' },
    { subject: 'Биология', topic: 'Строение растительной клетки' },
  ],
  6: [
    { subject: 'Математика', topic: 'Положительные и отрицательные числа' },
    { subject: 'Русский язык', topic: 'Морфологический разбор причастий' },
    { subject: 'География', topic: 'Масштаб и географические карты' },
    { subject: 'Биология', topic: 'Фотосинтез у растений' },
  ],
  7: [
    { subject: 'Математика', topic: 'Линейные уравнения и графики функций' },
    { subject: 'Физика', topic: 'Закон Гука и сила трения' },
    { subject: 'Информатика', topic: 'Основы алгоритмов и циклы' },
    { subject: 'Русский язык', topic: 'Деепричастный оборот и запятые' },
  ],
  8: [
    { subject: 'Математика', topic: 'Квадратные уравнения и теорема Пифагора' },
    { subject: 'Физика', topic: 'Закон Ома для участка цепи' },
    { subject: 'Химия', topic: 'Периодический закон Менделеева' },
    { subject: 'Биология', topic: 'Кровеносная система человека' },
  ],
  9: [
    { subject: 'Математика', topic: 'Квадратичная функция и ОГЭ задачи' },
    { subject: 'Физика', topic: 'Законы Ньютона и импульс тела' },
    { subject: 'Химия', topic: 'Окислительно-восстановительные реакции' },
    { subject: 'Информатика', topic: 'Двоичная система счисления' },
  ],
  10: [
    { subject: 'Математика', topic: 'Тригонометрические функции и формулы' },
    { subject: 'Физика', topic: 'Молекулярно-кинетическая теория (МКТ)' },
    { subject: 'Химия', topic: 'Органическая химия и алканы' },
    { subject: 'Информатика', topic: 'Сложность алгоритмов и списки в Python' },
  ],
  11: [
    { subject: 'Математика', topic: 'Производная, первообразная и профильный ЕГЭ' },
    { subject: 'Физика', topic: 'Электромагнитная индукция и кванты' },
    { subject: 'Русский язык', topic: 'Подготовка к сочинению ЕГЭ' },
    { subject: 'Информатика', topic: 'Динамическое программирование' },
  ],
};

export const DEFAULT_BADGES: Badge[] = [
  { id: 'first_question', title: 'Первый ИИ-запрос', description: 'Задайте первый вопрос Робо-Тьютору', icon: 'Sparkles', unlocked: true },
  { id: 'quiz_master', title: 'Мастер Викторин', description: 'Пройдите 5 проверочных мини-тестов', icon: 'Award', unlocked: false, progress: 1, maxProgress: 5 },
  { id: 'streak_3', title: 'Огонь Заний (3 дня)', description: 'Занимайтесь 3 дня подряд без перерыва', icon: 'Flame', unlocked: false, progress: 1, maxProgress: 3 },
  { id: 'homework_hero', title: 'Герой ДЗ', description: 'Разберите 3 сложных домашних задания', icon: 'CheckCircle2', unlocked: false, progress: 0, maxProgress: 3 },
  { id: 'cyber_stylist', title: 'Кибер-Стилист', description: 'Купите новый предмет для своего Робота', icon: 'Palette', unlocked: false, progress: 0, maxProgress: 1 },
  { id: 'level_5', title: 'Ученик 5 Уровня', description: 'Достигните 5 уровня в РобоШколе', icon: 'ShieldZap', unlocked: false, progress: 1, maxProgress: 5 },
];

export const SHOP_ITEMS: ShopItem[] = [
  // Head accessories
  { id: 'antenna_neon', name: 'Неоновая Антенна', category: 'headItem', value: 'antenna', cost: 100, currency: 'coins', requiredLevel: 1, iconName: 'Radio', description: 'Принимает знание прямо из космоса!' },
  { id: 'headphones_gamer', name: 'Геймерские Наушники', category: 'headItem', value: 'headphones', cost: 250, currency: 'coins', requiredLevel: 2, iconName: 'Headphones', description: 'Помогают сосредоточиться под музыку.' },
  { id: 'grad_cap', name: 'Шапка Профессора', category: 'headItem', value: 'grad_cap', cost: 400, currency: 'coins', requiredLevel: 3, iconName: 'GraduationCap', description: 'Символ абсолютной мудрости.' },
  { id: 'wizard_hat', name: 'Шляпа Мага Знаний', category: 'headItem', value: 'wizard_hat', cost: 15, currency: 'crystals', requiredLevel: 4, iconName: 'Wand2', description: 'Превращает тяжелую тему в простую магию.' },
  { id: 'crown_gold', name: 'Золотая Корона', category: 'headItem', value: 'crown', cost: 30, currency: 'crystals', requiredLevel: 5, iconName: 'Crown', description: 'Награда для настоящих чемпионов учебы.' },

  // Body colors
  { id: 'color_cyan', name: 'Кибер-Бирюза', category: 'bodyColor', value: '#06b6d4', cost: 50, currency: 'coins', requiredLevel: 1, iconName: 'Droplet', description: 'Яркий бирюзовый робо-корпус.' },
  { id: 'color_purple', name: 'Неоновый Фиолетовый', category: 'bodyColor', value: '#a855f7', cost: 150, currency: 'coins', requiredLevel: 2, iconName: 'Droplet', description: 'Космический стильный фиолетовый.' },
  { id: 'color_emerald', name: 'Изумрудный Драйв', category: 'bodyColor', value: '#10b981', cost: 200, currency: 'coins', requiredLevel: 3, iconName: 'Droplet', description: 'Экологичный энергосберегающий цвет.' },
  { id: 'color_gold', name: 'Чистое Золото', category: 'bodyColor', value: '#f59e0b', cost: 20, currency: 'crystals', requiredLevel: 4, iconName: 'Sparkles', description: 'Сияет от накопленных знаний.' },

  // Eye types
  { id: 'eye_stars', name: 'Звёздный Взгляд', category: 'eyeType', value: 'stars', cost: 120, currency: 'coins', requiredLevel: 1, iconName: 'Star', description: 'Глаза в виде сияющих звёздочек.' },
  { id: 'eye_cyber', name: 'Кибер-Прицел', category: 'eyeType', value: 'cyber', cost: 200, currency: 'coins', requiredLevel: 2, iconName: 'Eye', description: 'Сканирует любую задачу за секунду.' },
  { id: 'eye_visor', name: 'Неоновый Визор', category: 'eyeType', value: 'visor', cost: 10, currency: 'crystals', requiredLevel: 3, iconName: 'Glasses', description: 'Футуристичные робо-очки.' },

  // Aura colors
  { id: 'aura_purple', name: 'Аура Интеллекта', category: 'auraColor', value: 'purple', cost: 300, currency: 'coins', requiredLevel: 2, iconName: 'Sun', description: 'Фиолетовое квантовое свечение.' },
  { id: 'aura_gold', name: 'Аура Победителя', category: 'auraColor', value: 'gold', cost: 25, currency: 'crystals', requiredLevel: 4, iconName: 'Flame', description: 'Огненно-золотое свечение вокруг робота.' },
];

export const ROBOT_PERSONAS = [
  { id: 'spark', name: 'Робо-Искра', title: 'Дружелюбный гид (1-4 классы)', color: 'from-amber-400 to-orange-500', avatar: 'cute', description: 'Объясняет с любовью, добрыми сказками и весёлыми примерами.' },
  { id: 'pixel', name: 'Робо-Пиксель', title: 'Математик и Кодер (5-8 классы)', color: 'from-cyan-400 to-blue-600', avatar: 'cyber', description: 'Любит логику, схемы, игры и быструю проверку задач.' },
  { id: 'einstein', name: 'Робо-Эйнштейн', title: 'Профессор Наук (9-11 классы)', color: 'from-purple-500 to-indigo-600', avatar: 'visor', description: 'Готовит к ОГЭ/ЕГЭ, глубоким формулам и олимпиадам.' },
  { id: 'gramotei', name: 'Робо-Грамотей', title: 'Мастер Языков', color: 'from-emerald-400 to-teal-600', avatar: 'stars', description: 'Эксперт по родному и иностранным языкам, правилам и сочинениям.' },
];
