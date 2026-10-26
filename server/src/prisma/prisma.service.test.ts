import { describe, expect, it, jest } from '@jest/globals';
import { DEFAULT_TRANSACTION_OPTIONS, prisma, PrismaService } from './prisma.service';

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

  it('should configure high-resilience DEFAULT_TRANSACTION_OPTIONS for cloud databases', () => {
    expect(DEFAULT_TRANSACTION_OPTIONS.maxWait).toBe(15000);
    expect(DEFAULT_TRANSACTION_OPTIONS.timeout).toBe(30000);
  });

  it('should pass default transaction options into interactive transaction execution', async () => {
    const superTxSpy = jest
      .spyOn(Object.getPrototypeOf(PrismaService.prototype), '$transaction')
      .mockResolvedValue('tx-success' as any);

    const result = await prisma.$transaction(async () => 'ok');

    expect(result).toBe('tx-success');
    expect(superTxSpy).toHaveBeenCalledWith(
      expect.any(Function),
      expect.objectContaining({
        maxWait: 15000,
        timeout: 30000,
      }),
    );

    superTxSpy.mockRestore();
  });

  it('should automatically retry on P2028 transient transaction start timeout with extended limits', async () => {
    const p2028Error = new Error('Transaction API error: Unable to start a transaction in the given time.');
    (p2028Error as any).code = 'P2028';

    const superTxSpy = jest
      .spyOn(Object.getPrototypeOf(PrismaService.prototype), '$transaction')
      .mockRejectedValueOnce(p2028Error)
      .mockResolvedValueOnce('retried-success' as any);

    const result = await prisma.$transaction(async () => 'ok');

    expect(result).toBe('retried-success');
    expect(superTxSpy).toHaveBeenCalledTimes(2);
    expect(superTxSpy).toHaveBeenLastCalledWith(
      expect.any(Function),
      expect.objectContaining({
        maxWait: 25000,
        timeout: 45000,
      }),
    );

    superTxSpy.mockRestore();
  });
});
