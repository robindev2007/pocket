import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { AppError } from '../errors';
import type { AuthenticatedRequest } from '../types/express';

const getJwtSecret = (): string => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('FATAL: JWT_SECRET environment variable is missing in production');
    }
    return 'dev-secret-jwt-key-replace-in-env';
  }
  return secret;
};

export interface JwtPayload {
  id: string;
  email?: string | null;
  iat?: number;
  exp?: number;
}

/**
 * Authentication Guard Middleware
 * Validates 'Authorization: Bearer <accessToken>' and populates req.user
 */
export const authMiddleware = (req: Request, _res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw AppError.unauthorized('Authentication token is required');
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    throw AppError.unauthorized('Authentication token is missing');
  }

  try {
    const decoded = jwt.verify(token, getJwtSecret()) as JwtPayload;
    if (!decoded || !decoded.id) {
      throw AppError.unauthorized('Invalid token payload');
    }

    (req as AuthenticatedRequest).user = {
      id: decoded.id,
      email: decoded.email,
    };

    next();
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    if (error instanceof jwt.TokenExpiredError) {
      throw AppError.unauthorized('Authentication token has expired');
    }
    throw AppError.unauthorized('Invalid authentication token');
  }
};
