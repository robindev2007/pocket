import express from 'express';
import request from 'supertest';
import { app } from './app';
import { AppError } from './common/errors';
import { errorMiddleware } from './common/middleware';

describe('App Core', () => {
  it('should be defined with standard express methods', () => {
    expect(app).toBeDefined();
    expect(typeof app.use).toBe('function');
    expect(typeof app.get).toBe('function');
  });

  it('GET /health should return 200 with ok status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('uptime');
    expect(response.body).toHaveProperty('timestamp');
  });

  it('GET /unknown-route should return 404 with structured error', async () => {
    const response = await request(app).get('/unknown-route');
    expect(response.status).toBe(404);
    expect(response.body).toEqual({
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: 'Cannot GET /unknown-route',
        method: 'GET',
        path: '/unknown-route',
        timestamp: expect.any(String),
      },
    });
  });

  it('should route thrown errors to errorMiddleware', async () => {
    const testApp = express();
    testApp.get('/test-error', () => {
      throw AppError.badRequest('Test failure');
    });
    testApp.use(errorMiddleware);

    const response = await request(testApp).get('/test-error');
    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      success: false,
      error: {
        code: 'BAD_REQUEST',
        message: 'Test failure',
        timestamp: expect.any(String),
      },
    });
  });
});
