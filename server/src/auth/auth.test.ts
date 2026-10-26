import jwt from 'jsonwebtoken';
import request from 'supertest';
import { app } from '../app';
import { prisma } from '../prisma/prisma.service';
import { authService } from './auth.service';

describe('Auth Feature', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';

  describe('POST /auth/google', () => {
    it('should return 400 Bad Request when idToken is missing', async () => {
      const response = await request(app).post('/auth/google').send({});

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('success', false);
      expect(response.body.error).toHaveProperty('code', 'BAD_REQUEST');
    });

    it('should authenticate user and return token when Google verification succeeds', async () => {
      // Mock Google verification
      const verifySpy = jest.spyOn(authService, 'verifyGoogleToken').mockResolvedValueOnce({
        iss: 'https://accounts.google.com',
        sub: 'google-uid-12345',
        aud: 'test-aud',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        email: 'alex@example.com',
        name: 'Alex Developer',
        picture: 'https://avatar.example.com/alex.png',
      });

      // Mock Prisma upsert
      const upsertSpy = jest.spyOn(prisma.user, 'upsert').mockResolvedValueOnce({
        id: 'usr_test_uuid_123',
        googleId: 'google-uid-12345',
        email: 'alex@example.com',
        name: 'Alex Developer',
        avatar: 'https://avatar.example.com/alex.png',
        bio: null,
        currency: 'USD',
        hasCompletedOnboarding: false,
        syncVersion: BigInt(1),
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const response = await request(app)
        .post('/auth/google')
        .send({ idToken: 'valid-google-id-token-mock' });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('accessToken');
      expect(response.body.data.user).toEqual({
        id: 'usr_test_uuid_123',
        email: 'alex@example.com',
        name: 'Alex Developer',
        avatar: 'https://avatar.example.com/alex.png',
        currency: 'USD',
        hasCompletedOnboarding: false,
      });

      // Verify token is valid JWT
      const decoded = jwt.verify(response.body.data.accessToken, JWT_SECRET) as {
        id: string;
        email: string;
      };
      expect(decoded.id).toBe('usr_test_uuid_123');
      expect(decoded.email).toBe('alex@example.com');

      verifySpy.mockRestore();
      upsertSpy.mockRestore();
    });
  });

  describe('GET /auth/me', () => {
    it('should return 401 Unauthorized when no Authorization header is present', async () => {
      const response = await request(app).get('/auth/me');

      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('success', false);
      expect(response.body.error).toHaveProperty('code', 'UNAUTHORIZED');
    });

    it('should return 401 Unauthorized when token is invalid or corrupted', async () => {
      const response = await request(app)
        .get('/auth/me')
        .set('Authorization', 'Bearer invalid-token-string');

      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('success', false);
    });

    it('should return 200 OK with user profile when valid Bearer token is provided', async () => {
      const testUserId = 'usr_test_me_456';
      const validToken = jwt.sign({ id: testUserId, email: 'me@example.com' }, JWT_SECRET, {
        expiresIn: '1h',
      });

      const findUniqueSpy = jest.spyOn(prisma.user, 'findUnique').mockResolvedValueOnce({
        id: testUserId,
        googleId: 'google-sub-456',
        email: 'me@example.com',
        name: 'Me User',
        avatar: null,
        bio: 'Hello world',
        currency: 'EUR',
        hasCompletedOnboarding: true,
        syncVersion: BigInt(1),
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const response = await request(app)
        .get('/auth/me')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('id', testUserId);
      expect(response.body.data).toHaveProperty('email', 'me@example.com');
      expect(response.body.data).toHaveProperty('currency', 'EUR');

      findUniqueSpy.mockRestore();
    });
  });
});
