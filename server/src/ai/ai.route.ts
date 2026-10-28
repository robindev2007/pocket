import { Router, type Request, type Response } from 'express';
import { ApiResponse } from '../common/utils/api-response';
import { logger } from '../common/logger';
import { aiService } from './ai.service';
import type { AiChatRequest } from './ai.types';

export const aiRouter = Router();

// GET /ai/providers - List configured providers
aiRouter.get('/providers', (_req: Request, res: Response) => {
  const providers = aiService.getAvailableProviders();
  const defaultProvider = aiService.getDefaultProvider();

  return ApiResponse.success(res, {
    providers,
    defaultProvider,
  });
});

// POST /ai/chat - Process conversational financial queries and tool calling
aiRouter.post('/chat', async (req: Request, res: Response) => {
  const body = req.body as AiChatRequest;

  if (!body.message && !body.toolResult) {
    return ApiResponse.badRequest(res, 'Either message or toolResult must be provided');
  }

  logger.info('[AI Route] POST /ai/chat', {
    provider: body.provider || aiService.getDefaultProvider(),
    hasMessage: !!body.message,
    toolResult: body.toolResult?.name,
  });

  try {
    const result = await aiService.processChat(body);
    logger.info('[AI Route] /ai/chat success', {
      type: result.type,
      provider: result.provider,
      toolName: result.toolCall?.name,
    });
    return ApiResponse.success(res, result);
  } catch (error: any) {
    logger.error('[AI Route] /ai/chat error', error.message);
    return ApiResponse.error(res, error.message || 'AI request failed');
  }
});

// POST /ai/chat/stream - Real-time SSE streaming for chat responses and tool calls
aiRouter.post('/chat/stream', async (req: Request, res: Response) => {
  const body = req.body as AiChatRequest;

  if (!body.message && !body.toolResult) {
    return ApiResponse.badRequest(res, 'Either message or toolResult must be provided');
  }

  const provider = body.provider || aiService.getDefaultProvider();
  logger.info('[AI Route] POST /ai/chat/stream initiated', {
    provider,
    message: body.message?.substring(0, 60),
    toolResult: body.toolResult?.name,
  });

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  if (typeof (res as any).flushHeaders === 'function') {
    (res as any).flushHeaders();
  }

  let chunkCount = 0;
  try {
    for await (const chunk of aiService.processChatStream(body)) {
      chunkCount++;
      if (chunk.type === 'tool_call') {
        logger.info(`[AI Stream] Tool Call emitted: ${chunk.toolCall.name}`, chunk.toolCall.arguments);
      }
      res.write(`data: ${JSON.stringify(chunk)}\n\n`);
    }
    logger.info('[AI Stream] Stream completed successfully', { provider, chunks: chunkCount });
    res.end();
  } catch (error: any) {
    logger.error('[AI Stream Error]', error.message);
    res.write(`data: ${JSON.stringify({ type: 'error', message: error.message || 'Stream error' })}\n\n`);
    res.end();
  }
});
