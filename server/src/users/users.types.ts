import type { z } from 'zod';
import type { UpdateProfileSchema } from './users.dto';

export type UpdateProfileDto = z.infer<typeof UpdateProfileSchema>;

export interface UpsertGoogleUserDto {
  googleId: string;
  email: string;
  name?: string;
  avatar?: string | null;
}

export interface UserProfileResponse {
  id: string;
  email: string | null;
  name: string;
  avatar: string | null;
  bio: string | null;
  currency: string;
  hasCompletedOnboarding: boolean;
  syncVersion: string;
  createdAt: Date;
  updatedAt: Date;
}
