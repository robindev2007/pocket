import { z } from 'zod';

export const GoogleSignInSchema = z.object({
  idToken: z.string().min(1, 'Google ID token is required'),
});

export * from './auth.types';
