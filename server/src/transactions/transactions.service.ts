import { Prisma } from '@prisma/client';
import { prisma } from '../prisma/prisma.service';
import { AppError } from '../common/errors';
import type {
  BalanceSummaryResponse,
  CreateTransactionDto,
  TransactionQueryDto,
  TransactionResponse,
  UpdateTransactionDto,
} from './transactions.types';

export class TransactionsService {
  /**
   * Helper to format Prisma Transaction record into standardized API response
   */
  private mapToResponse(record: {
    id: string;
    userId: string;
    title: string;
    amount: Prisma.Decimal;
    type: string;
    date: Date;
    tag: string | null;
    note: string | null;
    isDeleted: boolean;
    version: bigint;
    createdAt: Date;
    updatedAt: Date;
  }): TransactionResponse {
    return {
      id: record.id,
      userId: record.userId,
      title: record.title,
      amount: Number(record.amount.toFixed(2)),
      type: record.type as TransactionResponse['type'],
      date: record.date.toISOString(),
      tag: record.tag,
      note: record.note,
      isDeleted: record.isDeleted,
      version: record.version.toString(),
      createdAt: record.createdAt.toISOString(),
      updatedAt: record.updatedAt.toISOString(),
    };
  }

  /**
   * Atomically creates a transaction and increments user's monotonic syncVersion
   */
  async create(userId: string, dto: CreateTransactionDto): Promise<TransactionResponse> {
    return prisma.$transaction(async (tx) => {
      // 1. Increment user's sync version
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      // 2. Create transaction record
      const transaction = await tx.transaction.create({
        data: {
          ...(dto.id ? { id: dto.id } : {}),
          userId,
          title: dto.title,
          amount: new Prisma.Decimal(dto.amount.toFixed(2)),
          type: dto.type,
          date: dto.date,
          tag: dto.tag || null,
          note: dto.note || null,
          version: user.syncVersion,
        },
      });

      return this.mapToResponse(transaction);
    });
  }

  /**
   * Retrieves all non-deleted transactions for cloud sync hydration
   */
  async findAllForSync(userId: string, since?: Date): Promise<TransactionResponse[]> {
    const where: Prisma.TransactionWhereInput = {
      userId,
      isDeleted: false,
      ...(since ? { updatedAt: { gte: since } } : {}),
    };

    const records = await prisma.transaction.findMany({
      where,
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });

    return records.map((r) => this.mapToResponse(r));
  }

  /**
   * Retrieves filtered, paginated transactions for the authenticated user
   */
  async findAll(
    userId: string,
    query: TransactionQueryDto,
  ): Promise<{ items: TransactionResponse[]; total: number; page: number; limit: number }> {
    const where: Prisma.TransactionWhereInput = {
      userId,
      isDeleted: false,
      ...(query.type ? { type: query.type } : {}),
      ...(query.tag ? { tag: { equals: query.tag, mode: 'insensitive' } } : {}),
      ...(query.startDate || query.endDate
        ? {
            date: {
              ...(query.startDate ? { gte: query.startDate } : {}),
              ...(query.endDate ? { lte: query.endDate } : {}),
            },
          }
        : {}),
      ...(query.search
        ? {
            title: {
              contains: query.search,
              mode: 'insensitive',
            },
          }
        : {}),
    };

    const [total, records] = await Promise.all([
      prisma.transaction.count({ where }),
      prisma.transaction.findMany({
        where,
        orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
        skip: (query.page - 1) * query.limit,
        take: query.limit,
      }),
    ]);

    return {
      items: records.map((r) => this.mapToResponse(r)),
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  /**
   * Retrieves a single transaction with ownership verification
   */
  async findById(userId: string, id: string): Promise<TransactionResponse> {
    const transaction = await prisma.transaction.findFirst({
      where: { id, userId, isDeleted: false },
    });

    if (!transaction) {
      throw AppError.notFound('Transaction not found');
    }

    return this.mapToResponse(transaction);
  }

  /**
   * Updates an existing transaction with ownership verification and syncVersion bumping
   */
  async update(
    userId: string,
    id: string,
    dto: UpdateTransactionDto,
  ): Promise<TransactionResponse> {
    // Ensure transaction exists and belongs to user
    await this.findById(userId, id);

    return prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      const updated = await tx.transaction.update({
        where: { id },
        data: {
          ...(dto.title !== undefined ? { title: dto.title } : {}),
          ...(dto.amount !== undefined
            ? { amount: new Prisma.Decimal(dto.amount.toFixed(2)) }
            : {}),
          ...(dto.type !== undefined ? { type: dto.type } : {}),
          ...(dto.date !== undefined ? { date: dto.date } : {}),
          ...(dto.tag !== undefined ? { tag: dto.tag } : {}),
          ...(dto.note !== undefined ? { note: dto.note } : {}),
          version: user.syncVersion,
        },
      });

      return this.mapToResponse(updated);
    });
  }

  /**
   * Soft-deletes a transaction by setting isDeleted = true (tombstone)
   */
  async softDelete(userId: string, id: string): Promise<void> {
    await this.findById(userId, id);

    await prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { syncVersion: { increment: 1 } },
        select: { syncVersion: true },
      });

      await tx.transaction.update({
        where: { id },
        data: {
          isDeleted: true,
          version: user.syncVersion,
        },
      });
    });
  }

  /**
   * Calculates total income, total expenses, and net cash balance with strict precision
   */
  async getBalanceSummary(userId: string): Promise<BalanceSummaryResponse> {
    const [user, transactions] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: { currency: true },
      }),
      prisma.transaction.findMany({
        where: { userId, isDeleted: false },
        select: { amount: true, type: true },
      }),
    ]);

    let totalIncome = new Prisma.Decimal(0);
    let totalExpenses = new Prisma.Decimal(0);

    for (const t of transactions) {
      if (t.type === 'INCOME') {
        totalIncome = totalIncome.add(t.amount);
      } else if (t.type === 'EXPENSE') {
        totalExpenses = totalExpenses.add(t.amount);
      }
    }

    const cashBalance = totalIncome.sub(totalExpenses);

    return {
      totalIncome: Number(totalIncome.toFixed(2)),
      totalExpenses: Number(totalExpenses.toFixed(2)),
      cashBalance: Number(cashBalance.toFixed(2)),
      currency: user?.currency || 'USD',
      transactionCount: transactions.length,
    };
  }
}

export const transactionsService = new TransactionsService();
