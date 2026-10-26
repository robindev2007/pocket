import type { z } from 'zod';
import type { GoogleSignInSchema } from './auth.dto';

export type GoogleSignInDto = z.infer<typeof GoogleSignInSchema>;

export interface AuthUserPayload {
  id: string;
  email: string | null;
  name: string;
  avatar: string | null;
  currency: string;
  hasCompletedOnboarding: boolean;
}

export interface AuthResponse {
  user: AuthUserPayload;
  accessToken: string;
}

export interface GoogleTokenPayload {
  sub: string;
  email: string;
  name?: string;
  picture?: string;
}
