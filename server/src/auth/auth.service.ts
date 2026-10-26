import { OAuth2Client, type TokenPayload } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import { AppError } from '../common/errors';
import { usersService } from '../users/users.service';
import type { AuthResponse } from './auth.types';

const getJwtSecret = (): string => {
  return process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';
};

export class AuthService {
  private googleClient: OAuth2Client;

  constructor() {
    this.googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
  }

  /**
   * Verifies Google ID token cryptographically using Google's public certs
   */
  async verifyGoogleToken(idToken: string): Promise<TokenPayload> {
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID || undefined,
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.sub || !payload.email) {
        throw AppError.unauthorized('Invalid Google token payload');
      }

      return payload;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw AppError.unauthorized('Failed to verify Google ID token');
    }
  }

  /**
   * Authenticates user via Google ID Token and issues app JWT
   */
  async googleSignIn(idToken: string): Promise<AuthResponse> {
    const payload = await this.verifyGoogleToken(idToken);

    // Delegate user upsert to centralized UsersService
    const user = await usersService.upsertGoogleUser({
      googleId: payload.sub,
      email: payload.email!,
      name: payload.name,
      avatar: payload.picture,
    });

    // Generate App JWT (7-day duration)
    const accessToken = jwt.sign(
      {
        id: user.id,
        email: user.email,
      },
      getJwtSecret(),
      { expiresIn: '7d' },
    );

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatar: user.avatar,
        currency: user.currency,
        hasCompletedOnboarding: user.hasCompletedOnboarding,
      },
      accessToken,
    };
  }

  /**
   * Fetches current authenticated user profile via centralized UsersService
   */
  async getUserById(userId: string) {
    return usersService.findById(userId);
  }
}

export const authService = new AuthService();
