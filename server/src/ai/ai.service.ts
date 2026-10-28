import type { AiChatRequest, AiChatResponse, AiProvider, AiStreamChunk } from './ai.types';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenRouterProvider } from './providers/openrouter.provider';
import { validateAiToolCall, OUT_OF_SCOPE_REFUSAL } from './ai.tools';
import { logger } from '../common/logger';

export class AiService {
  private geminiProvider: GeminiProvider;
  private openRouterProvider: OpenRouterProvider;

  constructor() {
    this.geminiProvider = new GeminiProvider();
    this.openRouterProvider = new OpenRouterProvider();
  }

  getAvailableProviders(): { id: AiProvider; name: string; isAvailable: boolean }[] {
    return [
      {
        id: 'gemini',
        name: 'Google Gemini AI (2.0 Flash)',
        isAvailable: this.geminiProvider.isAvailable(),
      },
      {
        id: 'openrouter',
        name: 'OpenRouter (Auto Model)',
        isAvailable: this.openRouterProvider.isAvailable(),
      },
    ];
  }

  getDefaultProvider(): AiProvider {
    const envDefault = process.env.AI_DEFAULT_PROVIDER?.toLowerCase();
    if (envDefault === 'openrouter' && this.openRouterProvider.isAvailable()) {
      return 'openrouter';
    }
    if (this.geminiProvider.isAvailable()) {
      return 'gemini';
    }
    if (this.openRouterProvider.isAvailable()) {
      return 'openrouter';
    }
    return 'gemini';
  }

  private sanitizeResponse(res: AiChatResponse): AiChatResponse {
    if (res.type === 'tool_call' && res.toolCall) {
      const check = validateAiToolCall(res.toolCall);
      if (!check.valid) {
        logger.warn(`[AI Security Boundary] Blocked unauthorized or invalid tool call: "${res.toolCall.name}": ${check.error}`);
        return {
          type: 'text',
          message: OUT_OF_SCOPE_REFUSAL,
          provider: res.provider,
        };
      }
    }
    return res;
  }

  async processChat(req: AiChatRequest): Promise<AiChatResponse> {
    const requestedProvider = req.provider || this.getDefaultProvider();

    // Primary attempt
    try {
      let res: AiChatResponse;
      if (requestedProvider === 'openrouter') {
        res = await this.openRouterProvider.chat(req);
      } else {
        res = await this.geminiProvider.chat(req);
      }
      return this.sanitizeResponse(res);
    } catch (primaryError) {
      // Automatic fallback if alternative provider is configured
      if (requestedProvider === 'gemini' && this.openRouterProvider.isAvailable()) {
        try {
          const res = await this.openRouterProvider.chat(req);
          return this.sanitizeResponse(res);
        } catch (_) {
          throw primaryError;
        }
      } else if (requestedProvider === 'openrouter' && this.geminiProvider.isAvailable()) {
        try {
          const res = await this.geminiProvider.chat(req);
          return this.sanitizeResponse(res);
        } catch (_) {
          throw primaryError;
        }
      }
      throw primaryError;
    }
  }

  async *processChatStream(req: AiChatRequest): AsyncGenerator<AiStreamChunk> {
    const requestedProvider = req.provider || this.getDefaultProvider();

    const stream = requestedProvider === 'openrouter'
      ? this.openRouterProvider.chatStream(req)
      : this.geminiProvider.chatStream(req);

    for await (const chunk of stream) {
      if (chunk.type === 'tool_call') {
        const check = validateAiToolCall(chunk.toolCall);
        if (!check.valid) {
          logger.warn(`[AI Security Boundary Stream] Blocked tool call: "${chunk.toolCall.name}": ${check.error}`);
          yield {
            type: 'delta',
            text: OUT_OF_SCOPE_REFUSAL,
            provider: chunk.provider,
          };
          yield {
            type: 'done',
            provider: chunk.provider,
          };
          return;
        }
      }
      yield chunk;
    }
  }
}

export const aiService = new AiService();

