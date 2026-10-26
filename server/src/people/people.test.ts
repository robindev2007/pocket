import jwt from 'jsonwebtoken';
import request from 'supertest';
import { Prisma } from '@prisma/client';
import { app } from '../app';
import { prisma } from '../prisma/prisma.service';

describe('People Feature', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';
  const testUserId = 'usr_test_people_123';
  let validToken: string;

  beforeAll(() => {
    validToken = jwt.sign({ id: testUserId, email: 'people_tester@example.com' }, JWT_SECRET, {
      expiresIn: '1h',
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Authentication Guard', () => {
    it('should return 401 Unauthorized when no Bearer token is provided', async () => {
      const response = await request(app).get('/people');
      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('success', false);
    });
  });

  describe('GET /people', () => {
    it('should return aggregated list of people with debt summaries', async () => {
      const mockDebts = [
        {
          id: 'debt-1',
          userId: testUserId,
          personName: 'Tanvir',
          title: 'Dinner bill',
          amount: new Prisma.Decimal('1000.00'),
          date: new Date('2026-10-25T12:00:00Z'),
          direction: 'LENT',
          isSettled: false,
          note: 'Buffet',
          isDeleted: false,
          repayments: [
            {
              id: 'rep-1',
              debtId: 'debt-1',
              amount: new Prisma.Decimal('400.00'),
              date: new Date('2026-10-26T12:00:00Z'),
              note: 'bKash part',
              affectsCashBalance: true,
              isDeleted: false,
            },
          ],
        },
        {
          id: 'debt-2',
          userId: testUserId,
          personName: 'Rahim',
          title: 'Uber share',
          amount: new Prisma.Decimal('500.00'),
          date: new Date('2026-10-24T12:00:00Z'),
          direction: 'BORROWED',
          isSettled: false,
          note: 'Airport ride',
          isDeleted: false,
          repayments: [],
        },
      ];

      jest.spyOn(prisma.debt, 'findMany').mockResolvedValue(mockDebts as any);

      const response = await request(app)
        .get('/people')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);

      const tanvir = response.body.data.find((p: any) => p.name === 'Tanvir');
      expect(tanvir).toBeDefined();
      expect(tanvir.theyOweMe).toBe(600); // 1000 - 400
      expect(tanvir.iOweThem).toBe(0);
      expect(tanvir.netBalance).toBe(600);
      expect(tanvir.activeDebtsCount).toBe(1);

      const rahim = response.body.data.find((p: any) => p.name === 'Rahim');
      expect(rahim).toBeDefined();
      expect(rahim.theyOweMe).toBe(0);
      expect(rahim.iOweThem).toBe(500);
      expect(rahim.netBalance).toBe(-500);
      expect(rahim.activeDebtsCount).toBe(1);
    });
  });

  describe('GET /people/:name/ledger', () => {
    it('should return chronological ledger statement for a specific person', async () => {
      const mockDebts = [
        {
          id: 'debt-1',
          userId: testUserId,
          personName: 'Tanvir',
          title: 'Dinner bill',
          amount: new Prisma.Decimal('1000.00'),
          date: new Date('2026-10-25T12:00:00Z'),
          direction: 'LENT',
          isSettled: false,
          note: 'Buffet',
          isDeleted: false,
          repayments: [
            {
              id: 'rep-1',
              debtId: 'debt-1',
              amount: new Prisma.Decimal('400.00'),
              date: new Date('2026-10-26T12:00:00Z'),
              note: 'bKash part',
              affectsCashBalance: true,
              isDeleted: false,
            },
          ],
        },
      ];

      jest.spyOn(prisma.debt, 'findMany').mockResolvedValue(mockDebts as any);

      const response = await request(app)
        .get('/people/Tanvir/ledger')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.person.name).toBe('Tanvir');
      expect(response.body.data.person.netBalance).toBe(600);
      expect(response.body.data.items).toHaveLength(2); // 1 debt + 1 repayment
      expect(response.body.data.items[0].type).toBe('REPAYMENT_COLLECTED'); // 26 Oct (newer)
      expect(response.body.data.items[1].type).toBe('LOAN_GIVEN'); // 25 Oct (older)
    });

    it('should return empty ledger for person with no records', async () => {
      jest.spyOn(prisma.debt, 'findMany').mockResolvedValue([]);

      const response = await request(app)
        .get('/people/Unknown/ledger')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.person.name).toBe('Unknown');
      expect(response.body.data.person.netBalance).toBe(0);
      expect(response.body.data.items).toHaveLength(0);
    });
  });
});
