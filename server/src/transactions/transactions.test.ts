import jwt from 'jsonwebtoken';
import request from 'supertest';
import { Prisma } from '@prisma/client';
import { app } from '../app';
import { prisma } from '../prisma/prisma.service';

describe('Transactions Feature', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';
  const testUserId = 'usr_test_transactions_123';
  let validToken: string;

  beforeAll(() => {
    validToken = jwt.sign({ id: testUserId, email: 'tester@example.com' }, JWT_SECRET, {
      expiresIn: '1h',
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Authentication Guard', () => {
    it('should return 401 Unauthorized when no Bearer token is provided', async () => {
      const response = await request(app).get('/transactions');
      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('success', false);
    });
  });

  describe('POST /transactions', () => {
    it('should return 400 Bad Request when required fields are missing', async () => {
      const response = await request(app)
        .post('/transactions')
        .set('Authorization', `Bearer ${validToken}`)
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should return 400 Bad Request when amount is negative or zero', async () => {
      const response = await request(app)
        .post('/transactions')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          title: 'Grocery Store',
          amount: -50,
          type: 'EXPENSE',
          date: '2026-10-26T12:00:00Z',
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should create transaction and return 201 Created on valid payload', async () => {
      const mockCreated = {
        id: 'tx-12345',
        userId: testUserId,
        title: 'Monthly Salary',
        amount: new Prisma.Decimal('3500.50'),
        type: 'INCOME',
        date: new Date('2026-10-26T10:00:00Z'),
        tag: 'Salary',
        note: 'October paycheck',
        isDeleted: false,
        version: BigInt(2),
        createdAt: new Date('2026-10-26T10:00:00Z'),
        updatedAt: new Date('2026-10-26T10:00:00Z'),
      };

      jest.spyOn(prisma, '$transaction').mockImplementation(async (cb: any) => {
        return cb({
          user: {
            update: jest.fn().mockResolvedValue({ syncVersion: BigInt(2) }),
          },
          transaction: {
            create: jest.fn().mockResolvedValue(mockCreated),
          },
        });
      });

      const response = await request(app)
        .post('/transactions')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          title: 'Monthly Salary',
          amount: 3500.5,
          type: 'income',
          date: '2026-10-26T10:00:00Z',
          tag: 'Salary',
          note: 'October paycheck',
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        id: 'tx-12345',
        userId: testUserId,
        title: 'Monthly Salary',
        amount: 3500.5,
        type: 'INCOME',
        tag: 'Salary',
        version: '2',
      });
    });
  });

  describe('GET /transactions', () => {
    it('should return paginated list of transactions with metadata', async () => {
      const mockRecord = {
        id: 'tx-100',
        userId: testUserId,
        title: 'Dinner with friends',
        amount: new Prisma.Decimal('65.00'),
        type: 'EXPENSE',
        date: new Date('2026-10-25T18:00:00Z'),
        tag: 'Food',
        note: null,
        isDeleted: false,
        version: BigInt(1),
        createdAt: new Date('2026-10-25T18:00:00Z'),
        updatedAt: new Date('2026-10-25T18:00:00Z'),
      };

      jest.spyOn(prisma.transaction, 'count').mockResolvedValueOnce(1);
      jest.spyOn(prisma.transaction, 'findMany').mockResolvedValueOnce([mockRecord]);

      const response = await request(app)
        .get('/transactions?page=1&limit=10&tag=Food')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title).toBe('Dinner with friends');
      expect(response.body.meta).toMatchObject({
        page: 1,
        limit: 10,
        total: 1,
        totalPages: 1,
        hasNextPage: false,
        hasPrevPage: false,
      });
    });
  });

  describe('GET /transactions/summary', () => {
    it('should calculate balance summary accurately with Decimal arithmetic', async () => {
      jest.spyOn(prisma.user, 'findUnique').mockResolvedValueOnce({
        id: testUserId,
        currency: 'EUR',
      } as any);

      jest.spyOn(prisma.transaction, 'findMany').mockResolvedValueOnce([
        { amount: new Prisma.Decimal('1000.50'), type: 'INCOME' },
        { amount: new Prisma.Decimal('200.25'), type: 'EXPENSE' },
        { amount: new Prisma.Decimal('50.00'), type: 'EXPENSE' },
      ] as any);

      const response = await request(app)
        .get('/transactions/summary')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual({
        totalIncome: 1000.5,
        totalExpenses: 250.25,
        cashBalance: 750.25,
        currency: 'EUR',
        transactionCount: 3,
      });
    });
  });

  describe('GET /transactions/:id', () => {
    it('should return 404 when transaction is not found or deleted', async () => {
      jest.spyOn(prisma.transaction, 'findFirst').mockResolvedValueOnce(null);

      const response = await request(app)
        .get('/transactions/tx-non-existent')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    it('should return 200 with transaction when found', async () => {
      const mock = {
        id: 'tx-200',
        userId: testUserId,
        title: 'Book purchase',
        amount: new Prisma.Decimal('29.99'),
        type: 'EXPENSE',
        date: new Date('2026-10-24T12:00:00Z'),
        tag: 'Education',
        note: 'TypeScript Handbook',
        isDeleted: false,
        version: BigInt(3),
        createdAt: new Date('2026-10-24T12:00:00Z'),
        updatedAt: new Date('2026-10-24T12:00:00Z'),
      };

      jest.spyOn(prisma.transaction, 'findFirst').mockResolvedValueOnce(mock);

      const response = await request(app)
        .get('/transactions/tx-200')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe('tx-200');
      expect(response.body.data.amount).toBe(29.99);
    });
  });

  describe('PATCH /transactions/:id', () => {
    it('should update transaction and return 200 on success', async () => {
      const existing = {
        id: 'tx-300',
        userId: testUserId,
        title: 'Old Title',
        amount: new Prisma.Decimal('10.00'),
        type: 'EXPENSE',
        date: new Date(),
        tag: null,
        note: null,
        isDeleted: false,
        version: BigInt(1),
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const updated = {
        ...existing,
        title: 'New Title',
        amount: new Prisma.Decimal('15.50'),
        version: BigInt(2),
      };

      jest.spyOn(prisma.transaction, 'findFirst').mockResolvedValueOnce(existing);
      jest.spyOn(prisma, '$transaction').mockImplementation(async (cb: any) => {
        return cb({
          user: { update: jest.fn().mockResolvedValue({ syncVersion: BigInt(2) }) },
          transaction: { update: jest.fn().mockResolvedValue(updated) },
        });
      });

      const response = await request(app)
        .patch('/transactions/tx-300')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          title: 'New Title',
          amount: 15.5,
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe('New Title');
      expect(response.body.data.amount).toBe(15.5);
    });
  });

  describe('DELETE /transactions/:id', () => {
    it('should soft-delete transaction and return 200 on success', async () => {
      const existing = {
        id: 'tx-400',
        userId: testUserId,
        title: 'Item to delete',
        amount: new Prisma.Decimal('10.00'),
        type: 'EXPENSE',
        date: new Date(),
        tag: null,
        note: null,
        isDeleted: false,
        version: BigInt(1),
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      jest.spyOn(prisma.transaction, 'findFirst').mockResolvedValueOnce(existing);
      jest.spyOn(prisma, '$transaction').mockImplementation(async (cb: any) => {
        return cb({
          user: { update: jest.fn().mockResolvedValue({ syncVersion: BigInt(2) }) },
          transaction: { update: jest.fn().mockResolvedValue({ ...existing, isDeleted: true }) },
        });
      });

      const response = await request(app)
        .delete('/transactions/tx-400')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual({ id: 'tx-400' });
    });
  });
});
