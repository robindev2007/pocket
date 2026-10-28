import { AI_SYSTEM_PROMPT, AI_TOOLS } from '../ai.tools';
import { logger } from '../../common/logger';
import type { AiChatMessage, AiChatRequest, AiChatResponse } from '../ai.types';

function buildSystemPrompt(userContext?: import('../ai.types').AiChatRequest['userContext']): string {
  if (!userContext) return AI_SYSTEM_PROMPT;
  const ctxLines: string[] = [];
  if (userContext.name) ctxLines.push(`- User's Name: ${userContext.name}`);
  if (userContext.email) ctxLines.push(`- User's Email: ${userContext.email}`);
  if (userContext.currency) ctxLines.push(`- Preferred Currency: ${userContext.currency}`);
  ctxLines.push(`- Account Status: ${userContext.isLoggedIn ? 'Logged in with account' : 'Guest / Local mode'}`);
  ctxLines.push(`- Auto Cloud Sync: ${userContext.autoSyncEnabled ? 'Enabled' : 'Disabled'}`);
  if (userContext.lastSyncedAt) ctxLines.push(`- Last Synced At: ${userContext.lastSyncedAt}`);

  return `${AI_SYSTEM_PROMPT}\n\nCurrent User Profile & Sync Environment:\n${ctxLines.join('\n')}\nAddress the user warmly by name when greeting or appropriate, and tailor context to their active account and currency.`;
}

export class GeminiProvider {
  private readonly apiKey: string;
  private readonly model: string;

  constructor(apiKey?: string, model = 'gemini-flash-lite-latest') {
    this.apiKey = apiKey || process.env.GEMINI_API_KEY || '';
    this.model = process.env.GEMINI_MODEL || model;
  }

  isAvailable(): boolean {
    return this.apiKey.trim().length > 0;
  }

  async chat(req: AiChatRequest): Promise<AiChatResponse> {
    if (!this.isAvailable()) {
      throw new Error('GEMINI_API_KEY is not configured on the server');
    }

    const contents: any[] = [];

    // Append historical conversation
    if (req.history && req.history.length > 0) {
      for (const msg of req.history) {
        contents.push({
          role: msg.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: msg.content || '' }],
        });
      }
    }

    // Append new user message or tool execution result
    if (req.toolResult) {
      contents.push({
        role: 'user',
        parts: [
          {
            text: `[Tool Execution Result for "${req.toolResult.name}"]: ${JSON.stringify(req.toolResult.result)}\nPlease provide a clear, concise final answer to the user's question based on these metrics.`,
          },
        ],
      });
    } else if (req.message) {
      contents.push({
        role: 'user',
        parts: [{ text: req.message }],
      });
    }

    // Convert tools schema to Gemini function declarations
    const geminiTools = [
      {
        functionDeclarations: AI_TOOLS.map((t) => ({
          name: t.name,
          description: t.description,
          parameters: t.parameters,
        })),
      },
    ];

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent?key=${this.apiKey}`;

    const payload: any = {
      systemInstruction: {
        parts: [{ text: buildSystemPrompt(req.userContext) }],
      },
      contents,
      generationConfig: {
        temperature: 0.2,
      },
    };

    if (!req.toolResult) {
      payload.tools = geminiTools;
    }

    logger.info(`[Gemini] Calling ${this.model}...`, {
      hasMessage: !!req.message,
      toolResult: req.toolResult?.name,
    });

    let response: Response | null = null;
    for (let attempt = 1; attempt <= 3; attempt++) {
      response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (response.status === 503 && attempt < 3) {
        logger.warn(`[Gemini] 503 high demand spike. Retrying attempt ${attempt}/3 in ${1000 * attempt}ms...`);
        await new Promise((r) => setTimeout(r, 1000 * attempt));
        continue;
      }
      break;
    }

    if (!response || !response.ok) {
      const errText = response ? await response.text() : 'No response';
      logger.error(`[Gemini Error] HTTP ${response?.status || 500}`, errText);
      throw new Error(`Gemini API error (${response?.status || 500}): ${errText}`);
    }

    const data = (await response.json()) as any;
    const candidate = data.candidates?.[0];
    const parts = candidate?.content?.parts || [];

    for (const part of parts) {
      if (part.functionCall) {
        logger.info(`[Gemini Tool Call] Model invoked tool: ${part.functionCall.name}`, part.functionCall.args);
        return {
          type: 'tool_call',
          toolCall: {
            name: part.functionCall.name,
            arguments: part.functionCall.args || {},
          },
          provider: 'gemini',
        };
      }
    }

    const textPart = parts.map((p: any) => p.text || '').join('');
    return {
      type: 'text',
      message: textPart || 'Processed successfully.',
      provider: 'gemini',
    };
  }

  async *chatStream(req: AiChatRequest): AsyncGenerator<import('../ai.types').AiStreamChunk> {
    if (!this.isAvailable()) {
      throw new Error('GEMINI_API_KEY is not configured on the server');
    }

    const contents: any[] = [];
    if (req.history && req.history.length > 0) {
      for (const msg of req.history) {
        contents.push({
          role: msg.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: msg.content || '' }],
        });
      }
    }

    if (req.toolResult) {
      contents.push({
        role: 'user',
        parts: [
          {
            text: `[Tool Execution Result for "${req.toolResult.name}"]: ${JSON.stringify(req.toolResult.result)}\nPlease provide a clear, concise final answer to the user's question based on these metrics.`,
          },
        ],
      });
    } else if (req.message) {
      contents.push({
        role: 'user',
        parts: [{ text: req.message }],
      });
    }

    const geminiTools = [
      {
        functionDeclarations: AI_TOOLS.map((t) => ({
          name: t.name,
          description: t.description,
          parameters: t.parameters,
        })),
      },
    ];

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:streamGenerateContent?key=${this.apiKey}&alt=sse`;

    const payload: any = {
      systemInstruction: {
        parts: [{ text: buildSystemPrompt(req.userContext) }],
      },
      contents,
      generationConfig: {
        temperature: 0.2,
      },
    };

    if (!req.toolResult) {
      payload.tools = geminiTools;
    }

    logger.info(`[Gemini Stream] Starting SSE stream with ${this.model}...`);

    let response: Response | null = null;
    for (let attempt = 1; attempt <= 3; attempt++) {
      response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (response.status === 503 && attempt < 3) {
        logger.warn(`[Gemini Stream] 503 high demand spike. Retrying attempt ${attempt}/3 in ${1000 * attempt}ms...`);
        await new Promise((r) => setTimeout(r, 1000 * attempt));
        continue;
      }
      break;
    }

    if (!response || !response.ok || !response.body) {
      const errText = response ? await response.text() : 'No response';
      logger.error(`[Gemini Stream Error] HTTP ${response?.status || 500}`, errText);
      throw new Error(`Gemini Stream API error (${response?.status || 500}): ${errText}`);
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        const jsonStr = trimmed.slice(6);
        try {
          const data = JSON.parse(jsonStr);
          const candidate = data.candidates?.[0];
          const parts = candidate?.content?.parts || [];

          for (const part of parts) {
            if (part.functionCall) {
              yield {
                type: 'tool_call',
                toolCall: {
                  name: part.functionCall.name,
                  arguments: part.functionCall.args || {},
                },
                provider: 'gemini',
              };
            } else if (part.text) {
              yield {
                type: 'delta',
                text: part.text,
                provider: 'gemini',
              };
            }
          }
        } catch (_) {}
      }
    }

    yield { type: 'done', provider: 'gemini' };
  }
}

