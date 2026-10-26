import type { Request } from 'express';

export interface AuthUser {
  id: string;
  email?: string | null;
}

export interface AuthenticatedRequest extends Request {
  user: AuthUser;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

