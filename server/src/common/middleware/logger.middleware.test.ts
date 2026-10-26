import type { NextFunction, Request, Response } from 'express';
import { EventEmitter } from 'events';
import { loggerMiddleware } from './logger.middleware';

describe('loggerMiddleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response> & EventEmitter;
  let nextMock: NextFunction;

  beforeEach(() => {
    mockRequest = {
      method: 'GET',
      originalUrl: '/api/v1/transactions',
    };
    mockResponse = Object.assign(new EventEmitter(), {
      statusCode: 200,
    }) as unknown as Partial<Response> & EventEmitter;
    nextMock = jest.fn();
  });

  it('should call next() immediately and bypass logging in production', () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    try {
      loggerMiddleware(mockRequest as Request, mockResponse as unknown as Response, nextMock);

      expect(nextMock).toHaveBeenCalledTimes(1);
      // No finish listener should be attached in production
      expect(mockResponse.listenerCount('finish')).toBe(0);
    } finally {
      process.env.NODE_ENV = originalEnv;
    }
  });

  it('should call next() and attach finish listener in development mode', () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    try {
      loggerMiddleware(mockRequest as Request, mockResponse as unknown as Response, nextMock);

      expect(nextMock).toHaveBeenCalledTimes(1);
      expect(mockResponse.listenerCount('finish')).toBe(1);
    } finally {
      process.env.NODE_ENV = originalEnv;
    }
  });

  it('should format log line with timestamp, method, url, status, and duration on finish in dev mode', () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    try {
      loggerMiddleware(mockRequest as Request, mockResponse as unknown as Response, nextMock);
      mockResponse.emit('finish');

      expect(consoleSpy).toHaveBeenCalledTimes(1);
      const logOutput = consoleSpy.mock.calls[0]?.[0];
      expect(logOutput).toContain('GET');
      expect(logOutput).toContain('/api/v1/transactions');
      // Green color \x1b[32m for 200 OK
      expect(logOutput).toContain('\x1b[32m200\x1b[0m');
    } finally {
      process.env.NODE_ENV = originalEnv;
      consoleSpy.mockRestore();
    }
  });

  it('should format errors with red color for 4xx and 5xx statuses in dev mode', () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    try {
      // 404 Client Error
      mockResponse.statusCode = 404;
      loggerMiddleware(mockRequest as Request, mockResponse as unknown as Response, nextMock);
      mockResponse.emit('finish');

      expect(consoleSpy).toHaveBeenCalledTimes(1);
      const log404 = consoleSpy.mock.calls[0]?.[0];
      // Red color \x1b[31m for 404
      expect(log404).toContain('\x1b[31m404\x1b[0m');

      // 500 Server Error
      mockResponse.removeAllListeners('finish');
      mockResponse.statusCode = 500;
      loggerMiddleware(mockRequest as Request, mockResponse as unknown as Response, nextMock);
      mockResponse.emit('finish');

      expect(consoleSpy).toHaveBeenCalledTimes(2);
      const log500 = consoleSpy.mock.calls[1]?.[0];
      // Bold Red color \x1b[1;31m for 500
      expect(log500).toContain('\x1b[1;31m500\x1b[0m');
    } finally {
      process.env.NODE_ENV = originalEnv;
      consoleSpy.mockRestore();
    }
  });
});
