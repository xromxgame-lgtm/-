import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { createServer as createViteServer } from 'vite';
import { GoogleGenAI, Type } from '@google/genai';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

app.use(express.json());

// Initialize Gemini client safely
function getGeminiClient(): GoogleGenAI {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('Ключ GEMINI_API_KEY не установлен. Пожалуйста, добавьте его в настройках.');
  }
  return new GoogleGenAI({
    apiKey,
    httpOptions: {
      headers: {
        'User-Agent': 'aistudio-build',
      },
    },
  });
}

// 1. Simple Topic Explainer API
app.post('/api/ai/explain', async (req, res) => {
  try {
    const { topic, grade = 5, subject = 'Математика', difficulty = 'Базовый' } = req.body;

    if (!topic || typeof topic !== 'string') {
      res.status(400).json({ error: 'Пожалуйста, укажите тему для объяснения.' });
      return;
    }

    const ai = getGeminiClient();

    const systemPrompt = `Ты — РобоШкола AI, дружелюбный и гениальный робот-учитель для школьников с 1 по 11 класс.
Твоя главная задача — объяснить сложную тему простым, захватывающим языком, адаптированным под школьника ${grade} класса.
Стиль подачи:
- Для 1-4 классов: Используй простые примеры, супергероев, роботов, конфеты, мультики, добрый сказочный тон.
- Для 5-8 классов: Используй примеры из компьютерных игр, популярной культуры, лайфхаки, наглядные сравнения.
- Для 9-11 классов: Пиши с уважением к взрослому интеллекту, четко, с понятным выводом формул, лайфхаками для ОГЭ/ЕГЭ и жизненными аналогиями.

Сложность: ${difficulty}. Предмет: ${subject}.
Верни ответ строго в формате JSON, соответствующем заданной схеме.`;

    const userPrompt = `Объясни тему "${topic}" для ученика ${grade} класса по предмету "${subject}".
Включи:
1. Понятное и интересное объяснение простыми словами
2. Увлекательную аналогию из жизни или мира роботов
3. 2-4 главных правила или формулы
4. Пошаговую инструкцию или пример решения
5. Любопытный робо-факт по этой теме
6. 3 проверочных вопроса с 4 вариантами ответа для закрепления (с указанием правильного ответа и объяснением)`;

    const response = await ai.models.generateContent({
      model: 'gemini-3.6-flash',
      contents: userPrompt,
      config: {
        systemInstruction: systemPrompt,
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            simpleExplanation: { type: Type.STRING, description: 'Простое объяснение темы' },
            analogy: { type: Type.STRING, description: 'Наглядная аналогия из жизни или игр' },
            keyRules: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: 'Ключевые правила или формулы',
            },
            stepByStep: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: 'Пошаговый пример решения или алгоритм',
            },
            funFact: { type: Type.STRING, description: 'Интересный факт от РобоШколы' },
            quiz: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  id: { type: Type.INTEGER },
                  question: { type: Type.STRING },
                  options: {
                    type: Type.ARRAY,
                    items: { type: Type.STRING },
                  },
                  correctIndex: { type: Type.INTEGER },
                  explanation: { type: Type.STRING },
                },
                required: ['id', 'question', 'options', 'correctIndex', 'explanation'],
              },
            },
          },
          required: ['simpleExplanation', 'analogy', 'keyRules', 'stepByStep', 'funFact', 'quiz'],
        },
      },
    });

    const jsonText = response.text || '{}';
    const parsedData = JSON.parse(jsonText);

    res.json(parsedData);
  } catch (error: any) {
    console.error('Error in /api/ai/explain:', error);
    res.status(500).json({
      error: error.message || 'Не удалось сгенерировать объяснение. Проверьте API ключ Gemini.',
    });
  }
});

// 2. Homework Check & Helper API
app.post('/api/ai/check-homework', async (req, res) => {
  try {
    const { problemText, userAnswer, grade = 5, subject = 'Математика' } = req.body;

    if (!problemText) {
      res.status(400).json({ error: 'Укажите текст задания или условия задачи.' });
      return;
    }

    const ai = getGeminiClient();

    const systemPrompt = `Ты — РобоШкола AI, добрый помощник по домашнему заданию для ученика ${grade} класса.
Предмет: ${subject}.
Твоя цель:
- Не просто дать ответ, а объяснить как прийти к правильному решению!
- Если ученик прислал своё решение (userAnswer), проверь его. Если оно правильное — похвали и дай +100 XP.
- Если в решении есть ошибка — вежливо подсвети где ошибка, дай пошаговую подсказку, но не спойлери окончательный результат сразу, а направь мысли ученика.
- Если ученик не знает, как решать — разбей задачу на легкие шаги (Шаг 1, Шаг 2, Шаг 3).`;

    const userPrompt = `Условие домашней задачи: "${problemText}"
Ответ/Черновик ученика: "${userAnswer || 'Ученик просит объяснить решение с нуля'}"`;

    const response = await ai.models.generateContent({
      model: 'gemini-3.6-flash',
      contents: userPrompt,
      config: {
        systemInstruction: systemPrompt,
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            isCorrect: { type: Type.BOOLEAN, description: 'Верно ли ответил ученик' },
            feedback: { type: Type.STRING, description: 'Разбор ответа или анализ задачи' },
            encouragement: { type: Type.STRING, description: 'Поддерживающие слова от робота' },
            hints: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: 'Подсказки и наводящие мысли',
            },
            correctSolutionStepByStep: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: 'Пошаговый разбор решения',
            },
            xpReward: { type: Type.INTEGER, description: 'Количество XP за попытку' },
          },
          required: ['isCorrect', 'feedback', 'encouragement', 'hints', 'correctSolutionStepByStep', 'xpReward'],
        },
      },
    });

    const parsed = JSON.parse(response.text || '{}');
    res.json(parsed);
  } catch (error: any) {
    console.error('Error in /api/ai/check-homework:', error);
    res.status(500).json({ error: error.message || 'Ошибка проверки домашнего задания.' });
  }
});

// 3. Generate Personal Learning Quest API
app.post('/api/ai/generate-quest', async (req, res) => {
  try {
    const { grade = 5, subject = 'Математика', difficulty = 'Базовый' } = req.body;

    const ai = getGeminiClient();

    const systemPrompt = `Ты — создатель игровых квестов для школы РобоШкола.
Сгенерируй 1 увлекательное учебное испытание (квест-задачу) по предмету "${subject}" для ученика ${grade} класса (Уровень: ${difficulty}).
Квест должен иметь интересную сюжетную завязку (например: помочь роботу починить реактор, расследовать детектив, отправить ракету).`;

    const response = await ai.models.generateContent({
      model: 'gemini-3.6-flash',
      contents: `Сгенерируй квест по предмету ${subject} для ${grade} класса.`,
      config: {
        systemInstruction: systemPrompt,
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            id: { type: Type.STRING },
            title: { type: Type.STRING, description: 'Заголовок квеста' },
            description: { type: Type.STRING, description: 'Сюжетная предыстория' },
            xpReward: { type: Type.INTEGER },
            coinsReward: { type: Type.INTEGER },
            task: {
              type: Type.OBJECT,
              properties: {
                question: { type: Type.STRING },
                options: {
                  type: Type.ARRAY,
                  items: { type: Type.STRING },
                },
                correctIndex: { type: Type.INTEGER },
                explanation: { type: Type.STRING },
              },
              required: ['question', 'options', 'correctIndex', 'explanation'],
            },
          },
          required: ['id', 'title', 'description', 'xpReward', 'coinsReward', 'task'],
        },
      },
    });

    const questData = JSON.parse(response.text || '{}');
    questData.subject = subject;
    questData.grade = grade;
    questData.difficulty = difficulty;

    res.json(questData);
  } catch (error: any) {
    console.error('Error in /api/ai/generate-quest:', error);
    res.status(500).json({ error: error.message || 'Ошибка создания квеста.' });
  }
});

// 4. Interactive Chat API
app.post('/api/ai/chat', async (req, res) => {
  try {
    const { message, history = [], grade = 5, persona = 'spark' } = req.body;

    if (!message) {
      res.status(400).json({ error: 'Сообщение не должно быть пустым.' });
      return;
    }

    const ai = getGeminiClient();

    let personaStyle = 'Дружелюбный робот-ассистент РобоШколы';
    if (persona === 'spark') {
      personaStyle = 'Робо-Искра: задорный, добрый робот для начальной школы (1-4 класс). Говорит просто, с эмодзи и добрыми шутками.';
    } else if (persona === 'pixel') {
      personaStyle = 'Робо-Пиксель: логичный и четкий кибер-тьютор для средних классов (5-8). Любит схемы, алгоритмы и лайфхаки.';
    } else if (persona === 'einstein') {
      personaStyle = 'Робо-Эйнштейн: мудрый, профессорский робот для старшеклассников (9-11 классы). Говорит глубоко, помогает с экзаменами и формулами.';
    } else if (persona === 'gramotei') {
      personaStyle = 'Робо-Грамотей: эрудированный робот-филолог. Учит писать красиво, без ошибок и знать все языковые правила.';
    }

    const systemPrompt = `Ты — ${personaStyle}.
Ученик учится в ${grade} классе.
Отвечай грамотно, вежливо, стимулируй интерес к учебе. Давай понятные примеры, разбивай ответы на абзацы и списки.
В конце ответа предложи 2-3 коротких варианта следующего вопроса (followup-вопросов).`;

    const formattedHistory = history.map((item: any) => ({
      role: item.sender === 'user' ? 'user' : 'model',
      parts: [{ text: item.text }],
    }));

    const response = await ai.models.generateContent({
      model: 'gemini-3.6-flash',
      contents: [
        ...formattedHistory,
        { role: 'user', parts: [{ text: message }] },
      ],
      config: {
        systemInstruction: systemPrompt,
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            reply: { type: Type.STRING, description: 'Основной ответ Робота' },
            suggestedFollowups: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: '3 предлагаемых следующего вопроса',
            },
          },
          required: ['reply', 'suggestedFollowups'],
        },
      },
    });

    const result = JSON.parse(response.text || '{}');
    res.json(result);
  } catch (error: any) {
    console.error('Error in /api/ai/chat:', error);
    res.status(500).json({ error: error.message || 'Ошибка общения с Робо-Тьютором.' });
  }
});

// Vite middleware and static production server
async function startServer() {
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🤖 РобоШкола Сервер запущен на http://localhost:${PORT}`);
  });
}

startServer();
