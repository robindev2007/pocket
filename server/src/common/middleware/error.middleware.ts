import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../errors';
import { logger } from '../logger';
import { ApiResponse } from '../utils';

/**
 * Global Error Handling Middleware
 * Catches all errors forwarded by next(err) or unhandled in async route handlers.
 */
export const errorMiddleware = (
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  // 1. Handled Operational Application Errors
  if (err instanceof AppError) {
    ApiResponse.error(res, err.message, {
      statusCode: err.statusCode,
      code: err.code,
      details: err.details,
    });
    return;
  }

  // 2. Zod Schema Validation Errors
  if (err instanceof ZodError) {
    ApiResponse.badRequest(res, 'Validation failed', {
      details: err.issues,
    });
    return;
  }

  // 3. Unhandled Bugs / Server Exceptions
  logger.error('Unhandled Server Error', err);

  const message =
    process.env.NODE_ENV === 'production'
      ? 'Internal Server Error'
      : err instanceof Error
        ? err.message
        : 'Internal Server Error';

  ApiResponse.error(res, message, {
    statusCode: 500,
    code: 'INTERNAL_SERVER_ERROR',
  });
};
