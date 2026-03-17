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

// openrouter/free auto-selects from available free models; specific models as fallbacks
const models = [
  "openrouter/free",
  "meta-llama/llama-3.3-70b-instruct",
  "openai/gpt-oss-120b",
  "stepfun/step-3.5-flash",
  "google/gemma-3-4b-it:free",
];

// Small helper to safely use fetch (Node 18+)
async function httpGetJson(url) {
  const res = await fetch(url);
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

// ----------------------
// Summarize page using a small model
// ----------------------
async function summarizePage(pageText) {
  if (!pageText) return "";

  try {
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
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
    return '\n\n[Web search is disabled because SERPAPI_KEY is not configured on the server.]';
  }

  try {
    const url = `https://serpapi.com/search.json?engine=google&q=${encodeURIComponent(query)}&api_key=${process.env.SERPAPI_KEY}`;
    const data = await httpGetJson(url);
    const organic = data.organic_results || [];
    const top = organic.slice(0, 5); // top 5 results

    if (!top.length) return '';

    let lines = '';

    for (let i = 0; i < top.length; i++) {
      const r = top[i];
      const title = r.title || 'Result';
      const snippet = r.snippet || '';
      const link = r.link || '';

      // Extract page content
      let pageText = await extractPageContent(link);

      // Summarize page
      let summary = "";
      if (pageText) {
        pageText = pageText.replace(/\n{2,}/g, '\n').trim();
        summary = await summarizePage(pageText);
        summary = summary.replace(/\n{2,}/g, '\n').trim();
      }

      // Append only the summary
      lines += `${i + 1}. ${title}\nSnippet: ${snippet}\nLink: ${link}\nSummary:\n${summary}\n\n`;
    }

    return `\n\nWeb search results (summaries from top links):\n${lines}\n\nUse these only if they look trustworthy and helpful.`;
  } catch (e) {
    console.warn('Web search failed:', e.message);
    return '';
  }
}

// ----------------------
// Build FinShe database context
// ----------------------
function buildDbContext(context = {}) {
  const { scholarships = [], loans = [], preferences = {} } = context;

  const prefsText = [
    preferences.country ? `country: ${preferences.country}` : null,
    preferences.degree ? `degree: ${preferences.degree}` : null,
    preferences.fieldOfStudy ? `field: ${preferences.fieldOfStudy}` : null,
  ].filter(Boolean).join(', ');

  const scholarshipsText = scholarships
    .slice(0, 15)
    .map(
      (s) =>
        `${s.name || 'Unnamed'} (${s.provider || 'Unknown provider'}, ${s.country || 'country any'})` +
        (s.amount ? `, amount: ${s.amount}` : '') +
        (s.deadline ? `, deadline: ${s.deadline}` : '')
    )
    .join('\n');

  const loansText = loans
    .slice(0, 10)
    .map(
      (l) =>
        `${l.name || 'Unnamed loan'} (${l.provider || 'Unknown provider'})` +
        (l.interestRate ? `, interest: ${l.interestRate}` : '') +
        (l.maxAmount ? `, max amount: ${l.maxAmount}` : '') +
        (l.country ? `, country: ${l.country}` : '')
    )
    .join('\n');

  let buf = '';
  if (prefsText) buf += `User preferences: ${prefsText}.\n\n`;
  if (scholarshipsText) buf += `Scholarships from FinShe database:\n${scholarshipsText}\n\n`;
  if (loansText) buf += `Loans from FinShe database:\n${loansText}\n\n`;

  return buf.trim();
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
// Chat endpoint
// ----------------------
app.post('/api/chat', async (req, res) => {
  try {
    const { message, context, history = [] } = req.body || {};

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'Missing or invalid "message" in request body.' });
    }

    if (!process.env.OPENROUTER_API_KEY) {
      return res.status(500).json({ error: 'OpenRouter API key is not configured on the server.' });
    }

    const webContext = await buildWebContext(message);

    const userContent = [
      `User question: ${message}`,
      webContext,
      '\n\nInstructions for you, the assistant:\n' +
      '- Answer the question using your knowledge and web search results.\n' +
      '- If conversation history is provided, use it to understand follow-up questions (e.g. "yes give", "tell me more", "send links").\n' +
      '- Do NOT rely on any internal FinShe database.\n' +
      '- If web results exist, use them as primary evidence.\n' +
      '- If no web results exist, answer using your general knowledge.\n' +
      '- Combine reasoning as if consulting multiple AI experts to produce the most accurate answer.\n' +
      '- Prefer official scholarship websites or government sources when available.\n' +
      '- Mention the source name when giving important details.\n' +
      '- If you are unsure about a fact, say "information may vary by year".\n'
    ].join('');

    // Build messages: system + conversation history (last 10 turns) + current user content
    const maxHistoryTurns = 10;
    const historyMessages = Array.isArray(history)
      ? history
          .filter((h) => h && (h.role === 'user' || h.role === 'assistant') && typeof h.content === 'string')
          .slice(-maxHistoryTurns)
          .map((h) => ({ role: h.role, content: h.content }))
      : [];

    const openRouterMessages = [
      {
        role: 'system',
        content: 'You are FinShe AI, an expert assistant that helps students find accurate scholarship information. Always prefer official government or university sources and avoid guessing. When the user says things like "yes give", "send links", "tell me more", refer back to your previous response and provide what they asked for.'
      },
      ...historyMessages,
      { role: 'user', content: userContent }
    ];

    let completion = null;
    const maxRetries = 2;

    for (const model of models) {
      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          console.log(`Trying model: ${model} (attempt ${attempt}/${maxRetries})`);

          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), 90000);

          const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
            method: "POST",
            signal: controller.signal,
            headers: {
              "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
              "Content-Type": "application/json",
              "HTTP-Referer": "http://localhost:3000",
              "X-Title": "FinShe"
            },
            body: JSON.stringify({
              model: model,
              messages: openRouterMessages
            })
          });

          clearTimeout(timeout);
          completion = await response.json();

          const aiMsg = extractAIMessage(completion);
          if (aiMsg) {
            return res.json({ reply: aiMsg, raw: completion });
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
    return res.status(502).json({
      error: "AI service is temporarily busy. Please try again in a moment.",
      suggestion: "Short queries like 'Hello' often work; complex ones may need a retry."
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

app.listen(port, '0.0.0.0', () => {
  console.log(`FinShe backend listening on http://0.0.0.0:${port}`);
});