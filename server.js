require('dotenv').config();

const express = require('express');
const cors = require('cors');
const axios = require("axios");
const cheerio = require("cheerio");

const app = express();
const port = process.env.PORT || 3000;

// Configure middleware
app.use(cors());
app.use(express.json());

const hasSerpApi = !!process.env.SERPAPI_KEY;

// Requested OpenRouter free models (in priority order)
const models = [
  "openai/gpt-oss-120b:free",
 // "google/gemma-3-4b-it:free",
  "meta-llama/llama-3.3-70b-instruct:free",
];

// Small helper to safely use fetch (Node 18+)
async function httpGetJson(url, { timeoutMs = 12000 } = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  const res = await fetch(url, { signal: controller.signal });
  clearTimeout(timeout);
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} for ${url}`);
  }
  return res.json();
}

// ----------------------
// Extract page content
// ----------------------
async function extractPageContent(url) {
  try {
    const { data } = await axios.get(url, { timeout: 10000 });
    const $ = cheerio.load(data);
    let text = "";

    $("p").each((i, el) => {
      text += $(el).text() + "\n";
    });

    return text;
  } catch (err) {
    console.log("Failed to read page:", url);
    return "";
  }
}

function normalizeText(s, maxChars = 4000) {
  if (!s) return '';
  const t = String(s).replace(/\s+/g, ' ').trim();
  if (t.length <= maxChars) return t;
  return t.slice(0, maxChars) + '…';
}

// ----------------------
// Summarize page using a small model
// ----------------------
async function summarizePage(pageText) {
  if (!pageText) return "";

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      signal: controller.signal,
      headers: {
        "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "qwen/qwen3-4b:free",
        messages: [
          { role: "system", content: "You are an assistant that summarizes web pages in 3–5 concise paragraphs." },
          { role: "user", content: pageText }
        ]
      })
    });
    clearTimeout(timeout);

    const data = await response.json();
    return data?.choices?.[0]?.message?.content || "";
  } catch (err) {
    console.log("Failed to summarize page:", err.message);
    return "";
  }
}

// ----------------------
// Build web context from SERP results
// ----------------------
async function buildWebContext(query) {
  if (!hasSerpApi) {
    return { results: [], note: 'Web search is disabled because SERPAPI_KEY is not configured on the server.' };
  }

  try {
    const url = `https://serpapi.com/search.json?engine=google&q=${encodeURIComponent(query)}&api_key=${process.env.SERPAPI_KEY}`;
    const data = await httpGetJson(url, { timeoutMs: 12000 });
    const organic = data.organic_results || [];
    const top = organic.slice(0, 5); // snippets only (fast)
    const results = top
      .map((r) => ({
        title: r?.title || 'Result',
        snippet: r?.snippet || '',
        link: r?.link || '',
        source: r?.source || '',
      }))
      .filter((r) => r.link || r.snippet);

    return { results, note: '' };
  } catch (e) {
    console.warn('Web search failed:', e.message);
    return { results: [], note: 'Web search failed.' };
  }
}

async function buildBrowserContext(webResults, budgetMs) {
  const startedAt = Date.now();
  const links = (webResults || [])
    .map((r) => r?.link)
    .filter(Boolean)
    .slice(0, 2); // keep it reliable on Render

  if (!links.length) return [];

  const tasks = links.map(async (link) => {
    const remainingMs = Math.max(2000, budgetMs - (Date.now() - startedAt));
    const timeoutMs = Math.min(8000, remainingMs);
    try {
      const pageText = await Promise.race([
        extractPageContent(link),
        new Promise((resolve) => setTimeout(() => resolve(''), timeoutMs)),
      ]);
      return { link, content: normalizeText(pageText, 3500) };
    } catch (_) {
      return { link, content: '' };
    }
  });

  const pages = await Promise.all(tasks);
  return pages.filter((p) => p.content);
}

function formatWebResultsReply(results, note) {
  if (!results?.length) {
    return note
      ? `I couldn’t fetch web results right now. (${note})`
      : 'I couldn’t fetch web results right now. Please try again.';
  }

  const lines = results.slice(0, 5).map((r, i) => {
    const title = r.title?.trim() || 'Result';
    const snippet = r.snippet?.trim() || '';
    const link = r.link?.trim() || '';
    const parts = [`${i + 1}) ${title}`];
    if (snippet) parts.push(`- ${snippet}`);
    if (link) parts.push(`- Link: ${link}`);
    return parts.join('\n');
  });

  return [
    'Here are the most relevant web results I found:',
    '',
    lines.join('\n\n'),
    '',
    'If you want, tell me your category (e.g. SC/ST/OBC/EWS/General), gender, state, and family income range, and I’ll narrow these down.',
  ].join('\n');
}

// ----------------------
// Extract AI message from OpenRouter response (handles various formats)
// ----------------------
function extractAIMessage(completion) {
  if (!completion?.choices?.[0]) return null;
  const choice = completion.choices[0];
  const content = choice?.message?.content;
  if (typeof content === 'string' && content.trim()) return content.trim();
  if (Array.isArray(content)) {
    const textPart = content.find(c => c?.type === 'text' && c?.text);
    if (textPart?.text?.trim()) return textPart.text.trim();
    const firstText = content.map(c => c?.text).filter(Boolean).join(' ').trim();
    if (firstText) return firstText;
  }
  if (choice?.text?.trim()) return choice.text.trim();
  return null;
}

// ----------------------
// Health check
// ----------------------
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'FinShe backend is running.' });
});

// ----------------------
// Version check (helps verify redeploys)
// ----------------------
const BACKEND_VERSION = 'finshe-backend-cloud-fallback-2026-03-17c';
app.get('/version', (req, res) => {
  res.json({ version: BACKEND_VERSION });
});

// ----------------------
// Minimal in-memory session store for continuity when clients don't resend history.
// (Best-effort; resets when Render restarts.)
// ----------------------
const sessionStore = new Map(); // sessionId -> { messages: [{role, content}], updatedAt }
const SESSION_TTL_MS = 30 * 60 * 1000;

function getSessionMessages(sessionId) {
  if (!sessionId) return [];
  const entry = sessionStore.get(sessionId);
  if (!entry) return [];
  if (Date.now() - entry.updatedAt > SESSION_TTL_MS) {
    sessionStore.delete(sessionId);
    return [];
  }
  return Array.isArray(entry.messages) ? entry.messages : [];
}

function saveSessionMessages(sessionId, messages) {
  if (!sessionId) return;
  sessionStore.set(sessionId, { messages, updatedAt: Date.now() });
}

// ----------------------
// Chat endpoint
// ----------------------
app.post('/api/chat', async (req, res) => {
  try {
    const { message, context, history = [], sessionId } = req.body || {};

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'Missing or invalid "message" in request body.' });
    }

    const startedAt = Date.now();
    const BUDGET_MS = 25000; // always respond fast on free hosting

    const m = message.trim();
    const isGreeting = /\b(hi|hii|hello|hey|hola)\b/i.test(m);
    if (isGreeting) {
      return res.json({
        version: BACKEND_VERSION,
        reply:
          'Hi! I’m the FinShe assistant. Ask me anything about scholarships, education loans, budgeting, or your academic plans.',
      });
    }

    // Web context can be slow/unreliable on free hosting. Bound it tightly.
    const web = await Promise.race([
      buildWebContext(m),
      new Promise((resolve) => setTimeout(() => resolve({ results: [], note: 'Web search timed out.' }), 12000)),
    ]);

    // Fetch + extract content from a couple top links ("browser" context).
    const browserPages = await Promise.race([
      buildBrowserContext(web.results, BUDGET_MS - (Date.now() - startedAt)),
      new Promise((resolve) => setTimeout(() => resolve([]), 9000)),
    ]);

    // If OpenRouter is not configured (or is down/busy), we still return something useful.
    const openRouterKey = process.env.OPENROUTER_API_KEY;
    if (!openRouterKey) {
      return res.json({ version: BACKEND_VERSION, reply: formatWebResultsReply(web.results, web.note) });
    }

    const userContent = [
      `User question: ${m}`,
      web.results?.length ? `\n\nWeb search results:\n${web.results.map((r, i) => `${i + 1}. ${r.title}\nSnippet: ${r.snippet}\nLink: ${r.link}`).join('\n\n')}` : (web.note ? `\n\nWeb note: ${web.note}` : ''),
      browserPages?.length
        ? `\n\nExtracted page content (high-signal excerpts):\n${browserPages
            .map((p, i) => `${i + 1}. ${p.link}\nExcerpt: ${p.content}`)
            .join('\n\n')}`
        : '',
      '\n\nInstructions for you, the assistant:\n' +
      '- Answer the question using your knowledge and web search results.\n' +
      '- If conversation history is provided, use it to understand follow-up questions (e.g. "yes give", "tell me more", "send links").\n' +
      '- Do NOT rely on any internal FinShe database.\n' +
      '- If web results exist, use them as primary evidence.\n' +
      '- If no web results exist, answer using your general knowledge.\n' +
      '- Combine reasoning as if consulting multiple AI experts to produce the most accurate answer.\n' +
      '- Prefer official scholarship websites or government sources when available.\n' +
      '- Mention the source name when giving important details.\n' +
      '- If you are unsure about a fact, say "information may vary by year".\n' +
      '- Output a complete, well-formatted answer. Use bullet points and include application links when possible.\n'
    ].join('');

    // Build messages: system + conversation history (last 10 turns) + current user content
    const maxHistoryTurns = 10;
    const providedHistory = Array.isArray(history)
      ? history
          .filter((h) => h && (h.role === 'user' || h.role === 'assistant') && typeof h.content === 'string')
          .slice(-maxHistoryTurns)
          .map((h) => ({ role: h.role, content: h.content }))
      : [];
    const sessionHistory = providedHistory.length ? [] : getSessionMessages(sessionId).slice(-maxHistoryTurns);
    const historyMessages = providedHistory.length ? providedHistory : sessionHistory;

    const openRouterMessages = [
      {
        role: 'system',
        content:
          'You are FinShe AI, an expert assistant that helps students find accurate scholarship information. ' +
          'Always prefer official government or university sources and avoid guessing. ' +
          'When the user says things like "yes give", "send links", "tell me more", refer back to your previous response and provide what they asked for. ' +
          'Keep answers complete and include links.'
      },
      ...historyMessages,
      {
        role: 'user',
        content:
          userContent
      }
    ];

    let completion = null;
    const maxRetries = 1;

    for (const model of models) {
      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        if (Date.now() - startedAt > BUDGET_MS) {
          return res.json({
            version: BACKEND_VERSION,
            reply: formatWebResultsReply(web.results, 'AI provider is taking too long right now.'),
          });
        }
        try {
          console.log(`Trying model: ${model} (attempt ${attempt}/${maxRetries})`);

          const controller = new AbortController();
          const remainingMs = Math.max(3000, BUDGET_MS - (Date.now() - startedAt));
          const timeout = setTimeout(() => controller.abort(), Math.min(8000, remainingMs));

          console.log("⏳ Calling OpenRouter...");

          const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
            method: "POST",
            signal: controller.signal,
            headers: {
              "Authorization": `Bearer ${openRouterKey}`,
              "Content-Type": "application/json",
              "HTTP-Referer": "http://localhost:3000",
              "X-Title": "FinShe"
            },
            body: JSON.stringify({
              model: model,
              messages: openRouterMessages,
              max_tokens: 1200,
              temperature: 0.2
            })
          });

          console.log("✅ OpenRouter responded");

          clearTimeout(timeout);
          completion = await response.json();

          const aiMsg = extractAIMessage(completion);
          if (aiMsg) {
            // Best-effort session continuity.
            const newSessionMsgs = [...historyMessages, { role: 'user', content: m }, { role: 'assistant', content: aiMsg }].slice(-maxHistoryTurns);
            saveSessionMessages(sessionId, newSessionMsgs);
            return res.json({ version: BACKEND_VERSION, reply: aiMsg, raw: completion });
          }
          if (completion?.error?.message) {
            console.log("OpenRouter error:", completion.error.message);
          }
        } catch (err) {
          console.log(`Model ${model} failed:`, err.message);
          if (attempt < maxRetries) {
            await new Promise(r => setTimeout(r, 1500 * attempt));
          }
        }
      }
    }

    console.log("All models failed. Last response:", JSON.stringify(completion)?.slice(0, 500));
    // Fallback: even if OpenRouter is busy/down, return web results so the app still works.
    return res.json({
      version: BACKEND_VERSION,
      reply: formatWebResultsReply(web.results, web.note || completion?.error?.message || 'AI provider is temporarily unavailable.'),
    });

  } catch (error) {
    console.error('Error in /api/chat:', error);
    const status = error.status || error.statusCode || 500;
    const message = error.message || 'Unexpected error while contacting OpenRouter. Please try again later.';
    res.status(status).json({ error: message });
  }
});

// ----------------------
// Start server
// ----------------------

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`FinShe backend listening on http://0.0.0.0:${port}`);
});

server.on('error', (err) => {
  if (err && err.code === 'EADDRINUSE') {
    console.error(`\nPort ${port} is already in use.\n`);
    console.error('Fix (PowerShell):');
    console.error(`  Get-NetTCPConnection -LocalPort ${port} -State Listen | Select-Object -ExpandProperty OwningProcess`);
    console.error('  Stop-Process -Id <PID> -Force');
    console.error('\nOr start on a different port:');
    console.error('  $env:PORT=3001; node server.js');
    process.exit(1);
  }
  console.error('Server failed to start:', err);
  process.exit(1);
});