import jwt from 'jsonwebtoken';
import request from 'supertest';
import { app } from '../app';
import { prisma } from '../prisma/prisma.service';

describe('Users Feature', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';
  const testUserId = 'usr_test_profile_123';
  let validToken: string;

  beforeAll(() => {
    validToken = jwt.sign({ id: testUserId, email: 'user@example.com' }, JWT_SECRET, {
      expiresIn: '1h',
    });
  });

  describe('GET /users/profile', () => {
    it('should return 401 Unauthorized when no token is provided', async () => {
      const response = await request(app).get('/users/profile');

      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('success', false);
    });

    it('should return 200 OK with user profile for authenticated user', async () => {
      const findSpy = jest.spyOn(prisma.user, 'findUnique').mockResolvedValueOnce({
        id: testUserId,
        googleId: 'google-sub-123',
        email: 'user@example.com',
        name: 'Jane Doe',
        avatar: 'https://avatar.example.com/jane.jpg',
        bio: 'Budgeting enthusiast',
        currency: 'USD',
        hasCompletedOnboarding: true,
        syncVersion: BigInt(2),
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const response = await request(app)
        .get('/users/profile')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toEqual({
        id: testUserId,
        email: 'user@example.com',
        name: 'Jane Doe',
        avatar: 'https://avatar.example.com/jane.jpg',
        bio: 'Budgeting enthusiast',
        currency: 'USD',
        hasCompletedOnboarding: true,
        syncVersion: '2',
        createdAt: expect.any(String),
        updatedAt: expect.any(String),
      });

      findSpy.mockRestore();
    });

    it('should return 404 Not Found if user is not found in database', async () => {
      const findSpy = jest.spyOn(prisma.user, 'findUnique').mockResolvedValueOnce(null);

      const response = await request(app)
        .get('/users/profile')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('success', false);
      expect(response.body.error).toHaveProperty('code', 'NOT_FOUND');

      findSpy.mockRestore();
    });
  });

  describe('PATCH /users/profile', () => {
    it('should return 400 Bad Request when payload is invalid (e.g. invalid currency length)', async () => {
      const response = await request(app)
        .patch('/users/profile')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ currency: 'US' }); // must be 3 chars

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('success', false);
    });

    it('should update profile and return updated data', async () => {
      const findSpy = jest.spyOn(prisma.user, 'findUnique').mockResolvedValueOnce({
        id: testUserId,
        googleId: 'google-sub-123',
        email: 'user@example.com',
        name: 'Jane Doe',
        avatar: null,
        bio: null,
        currency: 'USD',
        hasCompletedOnboarding: false,
        syncVersion: BigInt(1),
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const updateSpy = jest.spyOn(prisma.user, 'update').mockResolvedValueOnce({
        id: testUserId,
        googleId: 'google-sub-123',
        email: 'user@example.com',
        name: 'Jane Smith',
        avatar: null,
        bio: 'Saving up for a house',
        currency: 'EUR',
        hasCompletedOnboarding: true,
        syncVersion: BigInt(2),
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const response = await request(app)
        .patch('/users/profile')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Jane Smith',
          bio: 'Saving up for a house',
          currency: 'EUR',
          hasCompletedOnboarding: true,
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data.name).toBe('Jane Smith');
      expect(response.body.data.currency).toBe('EUR');
      expect(response.body.data.hasCompletedOnboarding).toBe(true);

      findSpy.mockRestore();
      updateSpy.mockRestore();
    });
  });
});
