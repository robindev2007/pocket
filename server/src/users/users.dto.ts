import { z } from 'zod';

export const UpdateProfileSchema = z.object({
  name: z.string().min(1, 'Name cannot be empty').max(100).optional(),
  bio: z.string().max(300).nullable().optional(),
  currency: z.string().min(3).max(3).toUpperCase().optional(),
  avatar: z.string().url('Invalid avatar URL').nullable().optional(),
  hasCompletedOnboarding: z.boolean().optional(),
});

export * from './users.types';
