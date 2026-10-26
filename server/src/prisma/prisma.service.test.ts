import { describe, expect, it } from '@jest/globals';
import { prisma } from './prisma.service';

describe('PrismaService (Prisma 7)', () => {
  it('should instantiate and export singleton PrismaClient instance', () => {
    expect(prisma).toBeDefined();
    expect(typeof prisma.$connect).toBe('function');
    expect(typeof prisma.$disconnect).toBe('function');
    expect(typeof prisma.user.findMany).toBe('function');
    expect(typeof prisma.transaction.findMany).toBe('function');
    expect(typeof prisma.debt.findMany).toBe('function');
    expect(typeof prisma.repayment.findMany).toBe('function');
  });
});
