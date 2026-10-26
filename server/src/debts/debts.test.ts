import jwt from 'jsonwebtoken';
import request from 'supertest';
import { Prisma } from '@prisma/client';
import { app } from '../app';
import { prisma } from '../prisma/prisma.service';

describe('Debts Feature', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';
  const testUserId = 'usr_test_debts_123';
  let validToken: string;

  beforeAll(() => {
    validToken = jwt.sign({ id: testUserId, email: 'debts_tester@example.com' }, JWT_SECRET, {
      expiresIn: '1h',
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Authentication Guard', () => {
    it('should return 401 Unauthorized when no Bearer token is provided', async () => {
      const response = await request(app).get('/debts');
      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('success', false);
    });
  });

  describe('POST /debts', () => {
    it('should return 400 Bad Request when required fields are missing', async () => {
      const response = await request(app)
        .post('/debts')
        .set('Authorization', `Bearer ${validToken}`)
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should return 400 when direction is invalid', async () => {
      const response = await request(app)
        .post('/debts')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          personName: 'Alice',
          title: 'Lunch money',
          amount: 25.0,
          date: '2026-10-26T12:00:00Z',
          direction: 'INVALID_DIRECTION',
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should create debt and return 201 Created on valid payload', async () => {
      const mockDebt = {
        id: 'debt-101',
        userId: testUserId,
        personName: 'Bob',
        title: 'Dinner Bill',
        amount: new Prisma.Decimal('120.00'),
        date: new Date('2026-10-26T12:00:00Z'),
        direction: 'LENT',
        isSettled: false,
        note: 'Pizza dinner',
        isDeleted: false,
        version: BigInt(2),
        createdAt: new Date('2026-10-26T12:00:00Z'),
        updatedAt: new Date('2026-10-26T12:00:00Z'),
      };

      jest.spyOn(prisma, '$transaction').mockImplementation(async (cb: any) => {
        return cb({
          user: { update: jest.fn().mockResolvedValue({ syncVersion: BigInt(2) }) },
          debt: { create: jest.fn().mockResolvedValue(mockDebt) },
        });
      });

      const response = await request(app)
        .post('/debts')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          personName: 'Bob',
          title: 'Dinner Bill',
          amount: 120.0,
          date: '2026-10-26T12:00:00Z',
          direction: 'theyOweMe', // Test mapping of theyOweMe -> LENT
          note: 'Pizza dinner',
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        id: 'debt-101',
        userId: testUserId,
        personName: 'Bob',
        title: 'Dinner Bill',
        amount: 120.0,
        totalRepaid: 0,
        remainingAmount: 120.0,
        isSettled: false,
        direction: 'LENT',
      });
    });
  });

  describe('GET /debts', () => {
    it('should return paginated list of debts with calculated totals', async () => {
      const mockDebt = {
        id: 'debt-201',
        userId: testUserId,
        personName: 'Charlie',
        title: 'Concert Ticket',
        amount: new Prisma.Decimal('100.00'),
        date: new Date('2026-10-20T12:00:00Z'),
        direction: 'BORROWED',
        isSettled: false,
        note: null,
        isDeleted: false,
        version: BigInt(1),
        repayments: [
          {
            id: 'rep-1',
            debtId: 'debt-201',
            amount: new Prisma.Decimal('40.00'),
            date: new Date('2026-10-22T12:00:00Z'),
            note: 'First installment',
            affectsCashBalance: true,
            isDeleted: false,
            version: BigInt(2),
            createdAt: new Date('2026-10-22T12:00:00Z'),
            updatedAt: new Date('2026-10-22T12:00:00Z'),
          },
        ],
        createdAt: new Date('2026-10-20T12:00:00Z'),
        updatedAt: new Date('2026-10-22T12:00:00Z'),
      };

      jest.spyOn(prisma.debt, 'count').mockResolvedValueOnce(1);
      jest.spyOn(prisma.debt, 'findMany').mockResolvedValueOnce([mockDebt]);

      const response = await request(app)
        .get('/debts?page=1&limit=10')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0]).toMatchObject({
        id: 'debt-201',
        amount: 100,
        totalRepaid: 40,
        remainingAmount: 60,
        isSettled: false,
        direction: 'BORROWED',
      });
      expect(response.body.data[0].repayments).toHaveLength(1);
    });
  });

  describe('GET /debts/summary', () => {
    it('should calculate receivables and payables summary correctly', async () => {
      const mockDebts = [
        {
          id: 'd-1',
          userId: testUserId,
          amount: new Prisma.Decimal('200.00'),
          direction: 'LENT',
          repayments: [{ amount: new Prisma.Decimal('50.00'), isDeleted: false }],
        },
        {
          id: 'd-2',
          userId: testUserId,
          amount: new Prisma.Decimal('100.00'),
          direction: 'BORROWED',
          repayments: [{ amount: new Prisma.Decimal('20.00'), isDeleted: false }],
        },
        {
          id: 'd-3',
          userId: testUserId,
          amount: new Prisma.Decimal('50.00'),
          direction: 'LENT',
          repayments: [{ amount: new Prisma.Decimal('50.00'), isDeleted: false }], // Fully settled
        },
      ];

      jest.spyOn(prisma.debt, 'findMany').mockResolvedValueOnce(mockDebts as any);

      const response = await request(app)
        .get('/debts/summary')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual({
        theyOweMe: 150.0, // 200 - 50 = 150
        iOweThem: 80.0, // 100 - 20 = 80
        netBalance: 70.0, // 150 - 80 = 70
        activeDebtsCount: 2,
        settledDebtsCount: 1,
      });
    });
  });

  describe('POST /debts/:id/repayments', () => {
    it('should record repayment, create balancing transaction, and settle debt if paid off', async () => {
      const existingDebt = {
        id: 'debt-301',
        userId: testUserId,
        personName: 'David',
        title: 'Loan for phone',
        amount: new Prisma.Decimal('100.00'),
        date: new Date('2026-10-15T12:00:00Z'),
        direction: 'LENT',
        isSettled: false,
        note: null,
        isDeleted: false,
        version: BigInt(1),
        repayments: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const mockRepayment = {
        id: 'rep-301-1',
        debtId: 'debt-301',
        amount: new Prisma.Decimal('100.00'),
        date: new Date('2026-10-26T12:00:00Z'),
        note: 'Full payoff',
        affectsCashBalance: true,
        isDeleted: false,
        version: BigInt(2),
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const updatedDebt = {
        ...existingDebt,
        isSettled: true,
        version: BigInt(2),
        repayments: [mockRepayment],
      };

      jest.spyOn(prisma.debt, 'findFirst').mockResolvedValueOnce(existingDebt as any);

      const mockTxCreate = jest.fn();
      jest.spyOn(prisma, '$transaction').mockImplementation(async (cb: any) => {
        return cb({
          user: { update: jest.fn().mockResolvedValue({ syncVersion: BigInt(2) }) },
          repayment: {
            create: jest.fn().mockResolvedValue(mockRepayment),
            findMany: jest.fn().mockResolvedValue([mockRepayment]),
          },
          transaction: {
            create: mockTxCreate,
          },
          debt: {
            update: jest.fn().mockResolvedValue(updatedDebt),
          },
        });
      });

      const response = await request(app)
        .post('/debts/debt-301/repayments')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          amount: 100.0,
          date: '2026-10-26T12:00:00Z',
          note: 'Full payoff',
          affectsCashBalance: true,
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.isSettled).toBe(true);
      expect(response.body.data.remainingAmount).toBe(0);
      expect(response.body.data.totalRepaid).toBe(100.0);
      expect(mockTxCreate).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            userId: testUserId,
            type: 'INCOME', // LENT debt receiving repayment = INCOME
            amount: expect.any(Prisma.Decimal),
          }),
        }),
      );
    });
  });

  describe('DELETE /debts/:id', () => {
    it('should soft delete debt and associated repayments', async () => {
      const existingDebt = {
        id: 'debt-401',
        userId: testUserId,
        personName: 'Eve',
        title: 'Book loan',
        amount: new Prisma.Decimal('15.00'),
        date: new Date(),
        direction: 'LENT',
        isSettled: false,
        note: null,
        isDeleted: false,
        version: BigInt(1),
        repayments: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      jest.spyOn(prisma.debt, 'findFirst').mockResolvedValueOnce(existingDebt as any);

      const mockRepaymentUpdateMany = jest.fn();
      const mockDebtUpdate = jest.fn();

      jest.spyOn(prisma, '$transaction').mockImplementation(async (cb: any) => {
        return cb({
          user: { update: jest.fn().mockResolvedValue({ syncVersion: BigInt(2) }) },
          repayment: { updateMany: mockRepaymentUpdateMany },
          debt: { update: mockDebtUpdate },
        });
      });

      const response = await request(app)
        .delete('/debts/debt-401')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(mockRepaymentUpdateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { debtId: 'debt-401', isDeleted: false },
          data: expect.objectContaining({ isDeleted: true }),
        }),
      );
      expect(mockDebtUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'debt-401' },
          data: expect.objectContaining({ isDeleted: true }),
        }),
      );
    });
  });
});
