import jwt from 'jsonwebtoken';
import request from 'supertest';
import { Prisma } from '@prisma/client';
import { app } from '../app';
import { prisma } from '../prisma/prisma.service';

describe('Sync Feature', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';
  const testUserId = 'usr_test_sync_123';
  let validToken: string;

  beforeAll(() => {
    validToken = jwt.sign({ id: testUserId, email: 'syncer@example.com' }, JWT_SECRET, {
      expiresIn: '1h',
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Authentication Guard', () => {
    it('should return 401 Unauthorized when no token is passed to /sync/pull', async () => {
      const response = await request(app).get('/sync/pull');
      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('success', false);
    });
  });

  describe('GET /sync/pull', () => {
    it('should return empty transactions and debts when user has no records', async () => {
      jest.spyOn(prisma.transaction, 'findMany').mockResolvedValue([]);
      jest.spyOn(prisma.debt, 'findMany').mockResolvedValue([]);

      const response = await request(app)
        .get('/sync/pull')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('transactions', []);
      expect(response.body.data).toHaveProperty('debts', []);
      expect(response.body.data).toHaveProperty('serverTime');
    });

    it('should return all cloud transactions and debts with active repayments', async () => {
      const mockTransactions = [
        {
          id: 'tx-1',
          userId: testUserId,
          title: 'Grocery Store',
          amount: new Prisma.Decimal('45.50'),
          type: 'EXPENSE',
          date: new Date('2026-10-26T14:00:00Z'),
          tag: 'Groceries',
          note: null,
          isDeleted: false,
          version: BigInt(1),
          createdAt: new Date('2026-10-26T14:00:00Z'),
          updatedAt: new Date('2026-10-26T14:00:00Z'),
        },
      ];

      const mockDebts = [
        {
          id: 'debt-1',
          userId: testUserId,
          personName: 'Alice',
          title: 'Concert Ticket',
          amount: new Prisma.Decimal('100.00'),
          date: new Date('2026-10-25T10:00:00Z'),
          direction: 'LENT',
          isSettled: false,
          note: null,
          isDeleted: false,
          version: BigInt(1),
          createdAt: new Date('2026-10-25T10:00:00Z'),
          updatedAt: new Date('2026-10-25T10:00:00Z'),
          repayments: [
            {
              id: 'rep-1',
              debtId: 'debt-1',
              amount: new Prisma.Decimal('30.00'),
              date: new Date('2026-10-26T10:00:00Z'),
              note: 'Cash installment',
              affectsCashBalance: true,
              isDeleted: false,
              version: BigInt(1),
              createdAt: new Date('2026-10-26T10:00:00Z'),
              updatedAt: new Date('2026-10-26T10:00:00Z'),
            },
          ],
        },
      ];

      jest.spyOn(prisma.transaction, 'findMany').mockResolvedValue(mockTransactions as any);
      jest.spyOn(prisma.debt, 'findMany').mockResolvedValue(mockDebts as any);

      const response = await request(app)
        .get('/sync/pull')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.transactions).toHaveLength(1);
      expect(response.body.data.transactions[0].title).toBe('Grocery Store');
      expect(response.body.data.transactions[0].amount).toBe(45.5);

      expect(response.body.data.debts).toHaveLength(1);
      expect(response.body.data.debts[0].personName).toBe('Alice');
      expect(response.body.data.debts[0].totalRepaid).toBe(30);
      expect(response.body.data.debts[0].remainingAmount).toBe(70);
      expect(response.body.data.debts[0].repayments).toHaveLength(1);
    });
  });
});
