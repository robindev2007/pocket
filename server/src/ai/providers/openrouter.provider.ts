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

export class OpenRouterProvider {
  private readonly apiKey: string;
  private readonly model: string;

  constructor(apiKey?: string, model = 'nvidia/nemotron-3.5-lightning:free') {
    this.apiKey = apiKey || process.env.OPENROUTER_API_KEY || '';
    this.model = process.env.OPENROUTER_MODEL || model;
  }

  isAvailable(): boolean {
    return this.apiKey.trim().length > 0;
  }

  async chat(req: AiChatRequest): Promise<AiChatResponse> {
    if (!this.isAvailable()) {
      throw new Error('OPENROUTER_API_KEY is not configured on the server');
    }

    const messages: any[] = [
      { role: 'system', content: buildSystemPrompt(req.userContext) },
    ];

    if (req.history && req.history.length > 0) {
      for (const msg of req.history) {
        messages.push({
          role: msg.role === 'tool' ? 'tool' : msg.role,
          content: msg.content || '',
          name: msg.name,
          tool_call_id: msg.toolCallId,
        });
      }
    }

    if (req.toolResult) {
      messages.push({
        role: 'user',
        content: `[Tool Execution Result for "${req.toolResult.name}"]: ${JSON.stringify(req.toolResult.result)}\nPlease provide a clear, concise final answer to the user's question based on these metrics.`,
      });
    } else if (req.message) {
      messages.push({
        role: 'user',
        content: req.message,
      });
    }

    const tools = AI_TOOLS.map((t) => ({
      type: 'function',
      function: {
        name: t.name,
        description: t.description,
        parameters: t.parameters,
      },
    }));

    const url = 'https://openrouter.ai/api/v1/chat/completions';

    const payload: any = {
      model: this.model,
      messages,
      temperature: 0.2,
    };

    if (!req.toolResult) {
      payload.tools = tools;
      payload.tool_choice = 'auto';
    }

    logger.info(`[OpenRouter] Requesting ${this.model}...`, {
      hasMessage: !!req.message,
      toolResult: req.toolResult?.name,
    });

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
        'HTTP-Referer': 'https://pocket-api.robinmia.com',
        'X-Title': 'Pocket Money Tracker',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errText = await response.text();
      logger.error(`[OpenRouter Error] HTTP ${response.status}`, errText);
      throw new Error(`OpenRouter API error (${response.status}): ${errText}`);
    }

    const data = (await response.json()) as any;
    const choice = data.choices?.[0];
    const message = choice?.message;

    if (message?.tool_calls && message.tool_calls.length > 0) {
      const tc = message.tool_calls[0];
      let parsedArgs = {};
      try {
        parsedArgs = JSON.parse(tc.function.arguments || '{}');
      } catch (_) {
        parsedArgs = {};
      }

      logger.info(`[OpenRouter Tool Call] Model invoked tool: ${tc.function.name}`, parsedArgs);
      return {
        type: 'tool_call',
        toolCall: {
          id: tc.id,
          name: tc.function.name,
          arguments: parsedArgs,
        },
        provider: 'openrouter',
      };
    }

    return {
      type: 'text',
      message: message?.content || 'Done.',
      provider: 'openrouter',
    };
  }

  async *chatStream(req: AiChatRequest): AsyncGenerator<import('../ai.types').AiStreamChunk> {
    if (!this.isAvailable()) {
      throw new Error('OPENROUTER_API_KEY is not configured on the server');
    }

    const messages: any[] = [{ role: 'system', content: buildSystemPrompt(req.userContext) }];

    if (req.history && req.history.length > 0) {
      for (const msg of req.history) {
        messages.push({
          role: msg.role === 'tool' ? 'tool' : msg.role,
          content: msg.content || '',
          name: msg.name,
          tool_call_id: msg.toolCallId,
        });
      }
    }

    if (req.toolResult) {
      messages.push({
        role: 'user',
        content: `[Tool Execution Result for "${req.toolResult.name}"]: ${JSON.stringify(req.toolResult.result)}\nPlease provide a clear, concise final answer to the user's question based on these metrics.`,
      });
    } else if (req.message) {
      messages.push({
        role: 'user',
        content: req.message,
      });
    }

    const tools = AI_TOOLS.map((t) => ({
      type: 'function',
      function: {
        name: t.name,
        description: t.description,
        parameters: t.parameters,
      },
    }));

    const url = 'https://openrouter.ai/api/v1/chat/completions';
    const payload: any = {
      model: this.model,
      messages,
      stream: true,
      temperature: 0.2,
    };

    if (!req.toolResult) {
      payload.tools = tools;
      payload.tool_choice = 'auto';
    }

    logger.info(`[OpenRouter Stream] Starting SSE stream with ${this.model}...`);

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
        'HTTP-Referer': 'https://pocket-api.robinmia.com',
        'X-Title': 'Pocket Money Tracker',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok || !response.body) {
      const errText = await response.text();
      logger.error(`[OpenRouter Stream Error] HTTP ${response.status}`, errText);
      throw new Error(`OpenRouter Stream API error (${response.status}): ${errText}`);
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    let accumulatedToolCall: { name: string; argsStr: string; id?: string } | null = null;

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        const raw = trimmed.slice(6);
        if (raw === '[DONE]') break;

        try {
          const json = JSON.parse(raw);
          const delta = json.choices?.[0]?.delta;

          if (delta?.tool_calls && delta.tool_calls.length > 0) {
            const tc = delta.tool_calls[0];
            if (tc.function?.name) {
              accumulatedToolCall = {
                name: tc.function.name,
                argsStr: tc.function.arguments || '',
                id: tc.id,
              };
            } else if (accumulatedToolCall && tc.function?.arguments) {
              accumulatedToolCall.argsStr += tc.function.arguments;
            }
          } else if (delta?.content) {
            yield {
              type: 'delta',
              text: delta.content,
              provider: 'openrouter',
            };
          }
        } catch (_) {}
      }
    }

    if (accumulatedToolCall) {
      let args = {};
      try {
        args = JSON.parse(accumulatedToolCall.argsStr || '{}');
      } catch (_) {}

      yield {
        type: 'tool_call',
        toolCall: {
          id: accumulatedToolCall.id,
          name: accumulatedToolCall.name,
          arguments: args,
        },
        provider: 'openrouter',
      };
    }

    yield { type: 'done', provider: 'openrouter' };
  }
}

