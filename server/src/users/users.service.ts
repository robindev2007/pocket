import { prisma } from '../prisma/prisma.service';
import { AppError } from '../common/errors';
import type { UpdateProfileDto, UpsertGoogleUserDto, UserProfileResponse } from './users.types';

export class UsersService {
  /**
   * Finds user by ID.
   * Central access point for user profile lookups (ideal location for Redis caching).
   */
  async findById(id: string): Promise<UserProfileResponse> {
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw AppError.notFound('User profile not found');
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      bio: user.bio,
      currency: user.currency,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
      syncVersion: user.syncVersion.toString(),
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  /**
   * Finds user by email address
   */
  async findByEmail(email: string) {
    return prisma.user.findUnique({
      where: { email },
    });
  }

  /**
   * Atomically creates or updates user profile from Google OAuth sign-in
   */
  async upsertGoogleUser(dto: UpsertGoogleUserDto) {
    return prisma.user.upsert({
      where: { email: dto.email },
      update: {
        googleId: dto.googleId,
        name: dto.name || undefined,
        avatar: dto.avatar !== undefined ? dto.avatar : undefined,
      },
      create: {
        googleId: dto.googleId,
        email: dto.email,
        name: dto.name || 'User',
        avatar: dto.avatar,
      },
    });
  }

  /**
   * Updates an existing user's profile settings
   */
  async updateProfile(id: string, dto: UpdateProfileDto): Promise<UserProfileResponse> {
    // Ensure user exists before updating
    await this.findById(id);

    const updated = await prisma.user.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.bio !== undefined ? { bio: dto.bio } : {}),
        ...(dto.currency !== undefined ? { currency: dto.currency } : {}),
        ...(dto.avatar !== undefined ? { avatar: dto.avatar } : {}),
        ...(dto.hasCompletedOnboarding !== undefined
          ? { hasCompletedOnboarding: dto.hasCompletedOnboarding }
          : {}),
      },
    });

    return {
      id: updated.id,
      email: updated.email,
      name: updated.name,
      avatar: updated.avatar,
      bio: updated.bio,
      currency: updated.currency,
      hasCompletedOnboarding: updated.hasCompletedOnboarding,
      syncVersion: updated.syncVersion.toString(),
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    };
  }
}

export const usersService = new UsersService();
