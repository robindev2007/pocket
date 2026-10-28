export type AiProvider = 'gemini' | 'openrouter';

export interface AiChatMessage {
  role: 'user' | 'assistant' | 'system' | 'tool';
  content?: string;
  name?: string;
  toolCallId?: string;
}

export interface AiToolCall {
  id?: string;
  name: string;
  arguments: Record<string, any>;
}

export interface AiChatRequest {
  message?: string;
  history?: AiChatMessage[];
  toolResult?: {
    name: string;
    result: any;
    toolCallId?: string;
  };
  provider?: AiProvider;
  userContext?: {
    name?: string;
    email?: string;
    currency?: string;
    isLoggedIn?: boolean;
    autoSyncEnabled?: boolean;
    lastSyncedAt?: string;
  };
}

export interface AiChatResponse {
  type: 'text' | 'tool_call';
  message?: string;
  toolCall?: AiToolCall;
  provider: AiProvider;
}

export type AiStreamChunk =
  | { type: 'delta'; text: string; provider: AiProvider }
  | { type: 'tool_call'; toolCall: AiToolCall; provider: AiProvider }
  | { type: 'done'; provider: AiProvider };

