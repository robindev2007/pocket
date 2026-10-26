import { logger, LoggerService } from './logger.service';

describe('LoggerService', () => {
  let customLogger: LoggerService;

  beforeEach(() => {
    customLogger = new LoggerService();
  });

  it('should be defined with standard logging methods', () => {
    expect(logger).toBeDefined();
    expect(typeof logger.info).toBe('function');
    expect(typeof logger.warn).toBe('function');
    expect(typeof logger.error).toBe('function');
    expect(typeof logger.debug).toBe('function');
    expect(typeof logger.addTransport).toBe('function');
  });

  it('should deliver logs to custom registered transports (3rd-party integration)', () => {
    const mockTransport = jest.fn();
    customLogger.addTransport(mockTransport);

    customLogger.info('User signed in', { userId: '123' });
    expect(mockTransport).toHaveBeenCalledWith('info', 'User signed in', { userId: '123' });

    customLogger.warn('High memory usage', { mem: '90%' });
    expect(mockTransport).toHaveBeenCalledWith('warn', 'High memory usage', { mem: '90%' });

    customLogger.debug('Cache hit');
    expect(mockTransport).toHaveBeenCalledWith('debug', 'Cache hit', undefined);
  });

  it('should format Error objects when logging errors to transports', () => {
    const mockTransport = jest.fn();
    customLogger.addTransport(mockTransport);

    const testError = new Error('Database connection failed');
    customLogger.error('Failed query', testError, { query: 'SELECT 1' });

    expect(mockTransport).toHaveBeenCalledWith(
      'error',
      'Failed query',
      expect.objectContaining({
        message: 'Database connection failed',
        query: 'SELECT 1',
        stack: expect.any(String),
      }),
    );
  });

  it('should format non-Error objects when logging errors', () => {
    const mockTransport = jest.fn();
    customLogger.addTransport(mockTransport);

    customLogger.error('String error', 'simple failure string');

    expect(mockTransport).toHaveBeenCalledWith('error', 'String error', {
      raw: 'simple failure string',
    });
  });

  it('should log to console in development mode', () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    try {
      customLogger.info('Server started on port 3000');
      expect(consoleSpy).toHaveBeenCalledTimes(1);
      expect(consoleSpy.mock.calls[0]?.[0]).toContain('INFO');
      expect(consoleSpy.mock.calls[0]?.[0]).toContain('Server started on port 3000');
    } finally {
      process.env.NODE_ENV = originalEnv;
      consoleSpy.mockRestore();
    }
  });

  it('should output structured JSON in production mode', () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    try {
      customLogger.info('Production log test', { cluster: 'us-east-1' });
      expect(consoleSpy).toHaveBeenCalledTimes(1);

      const parsedJson = JSON.parse(consoleSpy.mock.calls[0]?.[0]);
      expect(parsedJson).toEqual({
        timestamp: expect.any(String),
        level: 'info',
        message: 'Production log test',
        meta: { cluster: 'us-east-1' },
      });
    } finally {
      process.env.NODE_ENV = originalEnv;
      consoleSpy.mockRestore();
    }
  });
});
