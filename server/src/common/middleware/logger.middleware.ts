import type { NextFunction, Request, Response } from 'express';

// Standard ANSI terminal escape codes (zero dependencies)
const ANSI = {
  reset: '\x1b[0m',
  dim: '\x1b[90m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
  boldRed: '\x1b[1;31m',
} as const;

/**
 * Returns color code based on HTTP method
 */
const getMethodColor = (method: string): string => {
  switch (method.toUpperCase()) {
    case 'GET':
      return ANSI.cyan;
    case 'POST':
      return ANSI.green;
    case 'PUT':
    case 'PATCH':
      return ANSI.yellow;
    case 'DELETE':
      return ANSI.red;
    default:
      return ANSI.magenta;
  }
};

/**
 * Returns color code based on HTTP response status code
 * Errors (4xx & 5xx) are colored Red / Bold Red
 */
const getStatusColor = (status: number): string => {
  if (status >= 500) return ANSI.boldRed; // Server error: bold red
  if (status >= 400) return ANSI.red; // Client error: red
  if (status >= 300) return ANSI.cyan; // Redirect: cyan
  if (status >= 200) return ANSI.green; // Success: green
  return ANSI.reset;
};

/**
 * Simple API Request Logger Middleware
 * Logs incoming HTTP method, route, timestamp, response status (in red on error), and duration.
 * Only active in development mode; bypassed in production.
 */
export const loggerMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  // Only log in development mode; skip in production or automated tests
  const isDevelopment =
    process.env.NODE_ENV === 'development' ||
    (!process.env.NODE_ENV && process.env.NODE_ENV !== 'production');

  if (!isDevelopment) {
    next();
    return;
  }

  const start = performance.now();
  const timestamp = new Date().toISOString();

  res.on('finish', () => {
    const duration = (performance.now() - start).toFixed(2);
    const methodColor = getMethodColor(req.method);
    const statusColor = getStatusColor(res.statusCode);

    const logMessage = `${ANSI.dim}[${timestamp}]${ANSI.reset} ${methodColor}${req.method}${ANSI.reset} ${req.originalUrl} ${statusColor}${res.statusCode}${ANSI.reset} ${ANSI.dim}(${duration}ms)${ANSI.reset}`;

    console.log(logMessage);
  });

  next();
};
