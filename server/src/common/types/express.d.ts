import 'express';

export interface AuthUser {
  id: string;
  email?: string | null;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

declare module 'express-serve-static-core' {
  interface Request {
    user?: AuthUser;
  }
}
