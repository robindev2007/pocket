import type { z } from 'zod';
import type {
  AddRepaymentSchema,
  CreateDebtSchema,
  DebtQuerySchema,
  UpdateDebtSchema,
} from './debts.dto';

export type CreateDebtDto = z.infer<typeof CreateDebtSchema>;
export type UpdateDebtDto = z.infer<typeof UpdateDebtSchema>;
export type AddRepaymentDto = z.infer<typeof AddRepaymentSchema>;
export type DebtQueryDto = z.infer<typeof DebtQuerySchema>;

export type DebtDirection = 'LENT' | 'BORROWED';

export interface RepaymentResponse {
  id: string;
  debtId: string;
  amount: number;
  date: string;
  note: string | null;
  affectsCashBalance: boolean;
  isDeleted: boolean;
  version: string;
  createdAt: string;
  updatedAt: string;
}

export interface DebtResponse {
  id: string;
  userId: string;
  personName: string;
  title: string;
  amount: number;
  totalRepaid: number;
  remainingAmount: number;
  isSettled: boolean;
  date: string;
  direction: DebtDirection;
  note: string | null;
  isDeleted: boolean;
  version: string;
  repayments: RepaymentResponse[];
  createdAt: string;
  updatedAt: string;
}

export interface DebtSummaryResponse {
  theyOweMe: number;
  iOweThem: number;
  netBalance: number;
  activeDebtsCount: number;
  settledDebtsCount: number;
}
