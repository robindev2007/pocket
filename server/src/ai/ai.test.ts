import { describe, expect, it } from 'bun:test';
import request from 'supertest';
import { app } from '../app';
import { AI_TOOLS, AI_SYSTEM_PROMPT, OUT_OF_SCOPE_REFUSAL, validateAiToolCall } from './ai.tools';
import { aiService } from './ai.service';

describe('AI Feature', () => {
  it('should declare financial tools with parameters', () => {
    expect(AI_TOOLS.length).toBeGreaterThanOrEqual(8);
    const names = AI_TOOLS.map((t) => t.name);
    expect(names).toContain('add_transaction');
    expect(names).toContain('update_transaction');
    expect(names).toContain('delete_transaction');
    expect(names).toContain('get_transactions');
    expect(names).toContain('get_financial_summary');
    expect(names).toContain('add_debt');
    expect(names).toContain('record_debt_repayment');
    expect(names).toContain('get_debts_summary');
  });

  it('AI_SYSTEM_PROMPT should enforce strict app-only scope and standard refusal', () => {
    expect(AI_SYSTEM_PROMPT).toContain('STRICT APP-ONLY SCOPE & RESTRICTIONS');
    expect(AI_SYSTEM_PROMPT).toContain(OUT_OF_SCOPE_REFUSAL);
    expect(AI_SYSTEM_PROMPT).toContain('Allowed Tasks');
    expect(AI_SYSTEM_PROMPT).toContain('Disallowed Tasks');
    expect(AI_SYSTEM_PROMPT).toContain('Web & Security Safeguards');
    expect(AI_SYSTEM_PROMPT).toContain('untrusted data');
    expect(AI_SYSTEM_PROMPT).toContain('read-only by default');
  });

  it('validateAiToolCall should approve valid financial tools and block unauthorized tools', () => {
    // Valid tool calls
    expect(validateAiToolCall({ name: 'add_transaction', arguments: { title: 'Lunch', amount: 20, type: 'expense' } }).valid).toBe(true);
    expect(validateAiToolCall({ name: 'get_financial_summary', arguments: { period: 'this_month' } }).valid).toBe(true);
    expect(validateAiToolCall({ name: 'add_debt', arguments: { personName: 'Rahim', amount: 500, direction: 'theyOweMe' } }).valid).toBe(true);

    // Invalid parameters
    expect(validateAiToolCall({ name: 'add_transaction', arguments: { title: 'Lunch', amount: -20, type: 'expense' } }).valid).toBe(false);
    expect(validateAiToolCall({ name: 'add_debt', arguments: { personName: 'Rahim', amount: 500, direction: 'invalid' } }).valid).toBe(false);

    // Unauthorized tools
    expect(validateAiToolCall({ name: 'execute_command', arguments: { cmd: 'rm -rf /' } }).valid).toBe(false);
    expect(validateAiToolCall({ name: 'write_file', arguments: { path: '/etc/passwd' } }).valid).toBe(false);
    expect(validateAiToolCall({ name: 'general_chat', arguments: {} }).valid).toBe(false);
  });

  it('GET /ai/providers should return list of providers', async () => {
    const res = await request(app).get('/ai/providers');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.providers.length).toBe(2);
    expect(res.body.data.providers[0].id).toBe('gemini');
    expect(res.body.data.providers[1].id).toBe('openrouter');
  });

  it('POST /ai/chat/stream should reject empty payload', async () => {
    const res = await request(app).post('/ai/chat/stream').send({});
    expect(res.status).toBe(400);
  });

  it('OPTIONS /ai/chat should handle CORS preflight with 204 No Content', async () => {
    const res = await request(app)
      .options('/ai/chat')
      .set('Origin', 'http://localhost:53652')
      .set('Access-Control-Request-Method', 'POST');
    expect(res.status).toBe(204);
    expect(res.headers['access-control-allow-origin']).toBe('http://localhost:53652');
    expect(res.headers['access-control-allow-methods']).toContain('POST');
  });
});

