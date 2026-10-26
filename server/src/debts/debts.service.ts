import { Prisma } from '@prisma/client';
import { prisma } from '../prisma/prisma.service';
import { AppError } from '../common/errors';
import type {
  AddRepaymentDto,
  CreateDebtDto,
  DebtQueryDto,
  DebtResponse,
  DebtSummaryResponse,
  RepaymentResponse,
  UpdateDebtDto,
} from './debts.types';

export class DebtsService {
  /**
   * Helper to format a Repayment Prisma record
   */
  private mapRepayment(r: {
    id: string;
    debtId: string;
    amount: Prisma.Decimal;
    date: Date;
    note: string | null;
    affectsCashBalance: boolean;
    isDeleted: boolean;
    version: bigint;
    createdAt: Date;
    updatedAt: Date;
  }): RepaymentResponse {
    return {
      id: r.id,
      debtId: r.debtId,
      amount: Number(r.amount.toFixed(2)),
      date: r.date.toISOString(),
      note: r.note,
      affectsCashBalance: r.affectsCashBalance,
      isDeleted: r.isDeleted,
      version: r.version.toString(),
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
    };
  }

  /**
   * Helper to format a Debt Prisma record with calculated repayment summaries
   */
  private mapDebt(
    d: {
      id: string;
      userId: string;
      personName: string;
      title: string;
      amount: Prisma.Decimal;
      date: Date;
      direction: string;
      isSettled: boolean;
      note: string | null;
      isDeleted: boolean;
      version: bigint;
      createdAt: Date;
      updatedAt: Date;
    },
    repayments: Array<{
      id: string;
      debtId: string;
      amount: Prisma.Decimal;
      date: Date;
      note: string | null;
      affectsCashBalance: boolean;
      isDeleted: boolean;
      version: bigint;
      createdAt: Date;
      updatedAt: Date;
    }> = [],
  ): DebtResponse {
    const activeRepayments = repayments.filter((r) => !r.isDeleted);
    let totalRepaidDecimal = new Prisma.Decimal(0);

    for (const r of activeRepayments) {
      totalRepaidDecimal = totalRepaidDecimal.add(r.amount);
    }

    const remainingDecimal = d.amount.sub(totalRepaidDecimal);
    const remainingAmount = remainingDecimal.isNegative() ? 0 : Number(remainingDecimal.toFixed(2));
    const totalRepaid = Number(totalRepaidDecimal.toFixed(2));
    const isSettled = remainingAmount <= 0.001;

    return {
      id: d.id,
      userId: d.userId,
      personName: d.personName,
      title: d.title,
      amount: Number(d.amount.toFixed(2)),
      totalRepaid,
      remainingAmount,
      isSettled,
      date: d.date.toISOString(),
      direction: d.direction as DebtResponse['direction'],
      note: d.note,
      isDeleted: d.isDeleted,
      version: d.version.toString(),
      repayments: activeRepayments.map((r) => this.mapRepayment(r)),
      createdAt: d.createdAt.toISOString(),
      updatedAt: d.updatedAt.toISOString(),
    };
  }

  /**
   * Creates a new debt record atomically
   */
  async createDebt(userId: string, dto: CreateDebtDto): Promise<DebtResponse> {
    return prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      const debt = await tx.debt.create({
        data: {
          ...(dto.id ? { id: dto.id } : {}),
          userId,
          personName: dto.personName,
          title: dto.title,
          amount: new Prisma.Decimal(dto.amount.toFixed(2)),
          date: dto.date,
          direction: dto.direction,
          isSettled: false,
          note: dto.note || null,
          version: user.syncVersion,
        },
      });

      return this.mapDebt(debt, []);
    });
  }

  /**
   * Retrieves all non-deleted debts with active repayments for cloud sync hydration
   */
  async findAllForSync(userId: string, since?: Date): Promise<DebtResponse[]> {
    const where: Prisma.DebtWhereInput = {
      userId,
      isDeleted: false,
      ...(since ? { updatedAt: { gte: since } } : {}),
    };

    const records = await prisma.debt.findMany({
      where,
      include: {
        repayments: {
          where: { isDeleted: false },
          orderBy: { date: 'asc' },
        },
      },
      orderBy: [{ isSettled: 'asc' }, { date: 'desc' }, { createdAt: 'desc' }],
    });

    return records.map((r) => this.mapDebt(r, r.repayments));
  }

  /**
   * Lists debts for the user with filters and pagination
   */
  async getDebts(
    userId: string,
    query: DebtQueryDto,
  ): Promise<{ items: DebtResponse[]; total: number; page: number; limit: number }> {
    const where: Prisma.DebtWhereInput = {
      userId,
      isDeleted: false,
      ...(query.direction ? { direction: query.direction } : {}),
      ...(query.isSettled !== undefined ? { isSettled: query.isSettled } : {}),
      ...(query.personName
        ? { personName: { equals: query.personName, mode: 'insensitive' } }
        : {}),
      ...(query.search
        ? {
            OR: [
              { title: { contains: query.search, mode: 'insensitive' } },
              { personName: { contains: query.search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [total, records] = await Promise.all([
      prisma.debt.count({ where }),
      prisma.debt.findMany({
        where,
        include: {
          repayments: {
            where: { isDeleted: false },
            orderBy: { date: 'asc' },
          },
        },
        orderBy: [{ isSettled: 'asc' }, { date: 'desc' }, { createdAt: 'desc' }],
        skip: (query.page - 1) * query.limit,
        take: query.limit,
      }),
    ]);

    return {
      items: records.map((r) => this.mapDebt(r, r.repayments)),
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  /**
   * Fetches single debt with all active repayments
   */
  async getDebtById(userId: string, id: string): Promise<DebtResponse> {
    const debt = await prisma.debt.findFirst({
      where: { id, userId, isDeleted: false },
      include: {
        repayments: {
          where: { isDeleted: false },
          orderBy: { date: 'asc' },
        },
      },
    });

    if (!debt) {
      throw AppError.notFound('Debt record not found');
    }

    return this.mapDebt(debt, debt.repayments);
  }

  /**
   * Updates debt metadata and recalculates settlement status
   */
  async updateDebt(userId: string, id: string, dto: UpdateDebtDto): Promise<DebtResponse> {
    const existing = await this.getDebtById(userId, id);

    return prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      const newAmount =
        dto.amount !== undefined
          ? new Prisma.Decimal(dto.amount.toFixed(2))
          : new Prisma.Decimal(existing.amount.toFixed(2));

      const totalRepaidDecimal = new Prisma.Decimal(existing.totalRepaid.toFixed(2));
      const remaining = newAmount.sub(totalRepaidDecimal);
      const isSettled = remaining.isNegative() || remaining.isZero();

      const updated = await tx.debt.update({
        where: { id },
        data: {
          ...(dto.personName !== undefined ? { personName: dto.personName } : {}),
          ...(dto.title !== undefined ? { title: dto.title } : {}),
          ...(dto.amount !== undefined ? { amount: newAmount } : {}),
          ...(dto.date !== undefined ? { date: dto.date } : {}),
          ...(dto.direction !== undefined ? { direction: dto.direction } : {}),
          ...(dto.note !== undefined ? { note: dto.note } : {}),
          isSettled,
          version: user.syncVersion,
        },
        include: {
          repayments: {
            where: { isDeleted: false },
            orderBy: { date: 'asc' },
          },
        },
      });

      return this.mapDebt(updated, updated.repayments);
    });
  }

  /**
   * Soft-deletes a debt and all its associated repayments
   */
  async softDeleteDebt(userId: string, id: string): Promise<void> {
    await this.getDebtById(userId, id);

    await prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      // Soft delete repayments
      await tx.repayment.updateMany({
        where: { debtId: id, isDeleted: false },
        data: { isDeleted: true, version: user.syncVersion },
      });

      // Soft delete debt
      await tx.debt.update({
        where: { id },
        data: { isDeleted: true, version: user.syncVersion },
      });
    });
  }

  /**
   * Records a repayment for an existing debt and handles optional balancing transaction
   */
  async addRepayment(userId: string, debtId: string, dto: AddRepaymentDto): Promise<DebtResponse> {
    const debt = await this.getDebtById(userId, debtId);

    return prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      // 1. Create repayment record
      await tx.repayment.create({
        data: {
          ...(dto.id ? { id: dto.id } : {}),
          debtId,
          amount: new Prisma.Decimal(dto.amount.toFixed(2)),
          date: dto.date,
          note: dto.note || null,
          affectsCashBalance: dto.affectsCashBalance,
          version: user.syncVersion,
        },
      });

      // 2. If affectsCashBalance is true, generate balancing Transaction entry
      if (dto.affectsCashBalance) {
        const isLent = debt.direction === 'LENT';
        const transactionType = isLent ? 'INCOME' : 'EXPENSE';
        const prefix = isLent ? 'Repayment from' : 'Repayment to';
        const title = `${prefix} ${debt.personName}: ${debt.title}`;

        await tx.transaction.create({
          data: {
            userId,
            title,
            amount: new Prisma.Decimal(dto.amount.toFixed(2)),
            type: transactionType,
            date: dto.date,
            tag: 'Debt Repayment',
            note: dto.note || `Repayment for debt "${debt.title}"`,
            version: user.syncVersion,
          },
        });
      }

      // 3. Recalculate settlement status
      const allRepayments = await tx.repayment.findMany({
        where: { debtId, isDeleted: false },
      });

      let totalRepaid = new Prisma.Decimal(0);
      for (const r of allRepayments) {
        totalRepaid = totalRepaid.add(r.amount);
      }

      const debtAmount = new Prisma.Decimal(debt.amount.toFixed(2));
      const remaining = debtAmount.sub(totalRepaid);
      const isSettled = remaining.isNegative() || remaining.isZero();

      const updatedDebt = await tx.debt.update({
        where: { id: debtId },
        data: {
          isSettled,
          version: user.syncVersion,
        },
        include: {
          repayments: {
            where: { isDeleted: false },
            orderBy: { date: 'asc' },
          },
        },
      });

      return this.mapDebt(updatedDebt, updatedDebt.repayments);
    });
  }

  /**
   * Soft-deletes a repayment and updates the debt's settlement status
   */
  async deleteRepayment(
    userId: string,
    debtId: string,
    repaymentId: string,
  ): Promise<DebtResponse> {
    const debt = await this.getDebtById(userId, debtId);

    const repayment = await prisma.repayment.findFirst({
      where: { id: repaymentId, debtId, isDeleted: false },
    });

    if (!repayment) {
      throw AppError.notFound('Repayment record not found');
    }

    return prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      await tx.repayment.update({
        where: { id: repaymentId },
        data: { isDeleted: true, version: user.syncVersion },
      });

      const activeRepayments = await tx.repayment.findMany({
        where: { debtId, isDeleted: false },
      });

      let totalRepaid = new Prisma.Decimal(0);
      for (const r of activeRepayments) {
        totalRepaid = totalRepaid.add(r.amount);
      }

      const debtAmount = new Prisma.Decimal(debt.amount.toFixed(2));
      const remaining = debtAmount.sub(totalRepaid);
      const isSettled = remaining.isNegative() || remaining.isZero();

      const updatedDebt = await tx.debt.update({
        where: { id: debtId },
        data: {
          isSettled,
          version: user.syncVersion,
        },
        include: {
          repayments: {
            where: { isDeleted: false },
            orderBy: { date: 'asc' },
          },
        },
      });

      return this.mapDebt(updatedDebt, updatedDebt.repayments);
    });
  }

  /**
   * Calculates "They Owe Me" vs "I Owe Them" receivables and payables summary
   */
  async getDebtSummary(userId: string): Promise<DebtSummaryResponse> {
    const debts = await prisma.debt.findMany({
      where: { userId, isDeleted: false },
      include: {
        repayments: {
          where: { isDeleted: false },
        },
      },
    });

    let theyOweMe = new Prisma.Decimal(0);
    let iOweThem = new Prisma.Decimal(0);
    let activeDebtsCount = 0;
    let settledDebtsCount = 0;

    for (const d of debts) {
      let totalRepaid = new Prisma.Decimal(0);
      for (const r of d.repayments) {
        totalRepaid = totalRepaid.add(r.amount);
      }

      const remaining = d.amount.sub(totalRepaid);
      const remainingPositive = remaining.isNegative() ? new Prisma.Decimal(0) : remaining;

      if (remainingPositive.isZero()) {
        settledDebtsCount++;
      } else {
        activeDebtsCount++;
        if (d.direction === 'LENT') {
          theyOweMe = theyOweMe.add(remainingPositive);
        } else if (d.direction === 'BORROWED') {
          iOweThem = iOweThem.add(remainingPositive);
        }
      }
    }

    const netBalance = theyOweMe.sub(iOweThem);

    return {
      theyOweMe: Number(theyOweMe.toFixed(2)),
      iOweThem: Number(iOweThem.toFixed(2)),
      netBalance: Number(netBalance.toFixed(2)),
      activeDebtsCount,
      settledDebtsCount,
    };
  }
}

export const debtsService = new DebtsService();
