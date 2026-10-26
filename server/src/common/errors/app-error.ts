/**
 * Application Error
 * Base error class for all operational and expected application errors.
 */
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly isOperational: boolean;
  public readonly details?: unknown;

  constructor(
    message: string,
    statusCode = 500,
    code = 'INTERNAL_SERVER_ERROR',
    details?: unknown,
  ) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true;

    // Restore proper prototype chain for instanceof checks
    Object.setPrototypeOf(this, new.target.prototype);

    // Maintains proper stack trace for where our error was thrown (only available on V8)
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }

  static badRequest(message = 'Bad Request', details?: unknown): AppError {
    return new AppError(message, 400, 'BAD_REQUEST', details);
  }

  static unauthorized(message = 'Unauthorized', details?: unknown): AppError {
    return new AppError(message, 401, 'UNAUTHORIZED', details);
  }

  static forbidden(message = 'Forbidden', details?: unknown): AppError {
    return new AppError(message, 403, 'FORBIDDEN', details);
  }

  static notFound(message = 'Not Found', details?: unknown): AppError {
    return new AppError(message, 404, 'NOT_FOUND', details);
  }

  static conflict(message = 'Conflict', details?: unknown): AppError {
    return new AppError(message, 409, 'CONFLICT', details);
  }

  static internal(message = 'Internal Server Error', details?: unknown): AppError {
    return new AppError(message, 500, 'INTERNAL_SERVER_ERROR', details);
  }
}
