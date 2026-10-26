import type { z } from 'zod';
import type {
  CreateTransactionSchema,
  TransactionQuerySchema,
  UpdateTransactionSchema,
} from './transactions.dto';

export type CreateTransactionDto = z.infer<typeof CreateTransactionSchema>;
export type UpdateTransactionDto = z.infer<typeof UpdateTransactionSchema>;
export type TransactionQueryDto = z.infer<typeof TransactionQuerySchema>;

export type TransactionType = 'INCOME' | 'EXPENSE' | 'TRANSFER';

export interface TransactionResponse {
  id: string;
  userId: string;
  title: string;
  amount: number;
  type: TransactionType;
  date: string;
  tag: string | null;
  note: string | null;
  isDeleted: boolean;
  version: string;
  createdAt: string;
  updatedAt: string;
}

export interface BalanceSummaryResponse {
  totalIncome: number;
  totalExpenses: number;
  cashBalance: number;
  currency: string;
  transactionCount: number;
}
