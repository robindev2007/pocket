import { z } from 'zod';

const normalizeDirection = (val: unknown): string => {
  if (typeof val === 'string') {
    const lower = val.trim();
    if (lower === 'theyOweMe') return 'LENT';
    if (lower === 'iOweThem') return 'BORROWED';
    return lower.toUpperCase();
  }
  return val as string;
};

export const DebtDirectionEnum = z.preprocess(
  normalizeDirection,
  z.enum(['LENT', 'BORROWED'], {
    message: "Direction must be 'LENT' (theyOweMe) or 'BORROWED' (iOweThem)",
  }),
);

export const CreateDebtSchema = z.object({
  id: z.string().uuid().optional(),
  personName: z
    .string({ message: 'Person name is required' })
    .trim()
    .min(1, 'Person name cannot be empty')
    .max(120, 'Person name cannot exceed 120 characters'),
  title: z
    .string({ message: 'Title is required' })
    .trim()
    .min(1, 'Title cannot be empty')
    .max(150, 'Title cannot exceed 150 characters'),
  amount: z.coerce
    .number({ message: 'Amount is required' })
    .positive('Amount must be greater than zero')
    .max(999999999999.99, 'Amount exceeds maximum allowable limit'),
  date: z.coerce.date({ message: 'Valid date is required' }),
  direction: DebtDirectionEnum,
  note: z.string().trim().max(500, 'Note cannot exceed 500 characters').nullable().optional(),
});

export const UpdateDebtSchema = z.object({
  personName: z.string().trim().min(1).max(120).optional(),
  title: z.string().trim().min(1).max(150).optional(),
  amount: z.coerce.number().positive().max(999999999999.99).optional(),
  date: z.coerce.date().optional(),
  direction: DebtDirectionEnum.optional(),
  note: z.string().trim().max(500).nullable().optional(),
});

export const AddRepaymentSchema = z.object({
  id: z.string().uuid().optional(),
  amount: z.coerce
    .number({ message: 'Repayment amount is required' })
    .positive('Repayment amount must be greater than zero')
    .max(999999999999.99, 'Amount exceeds maximum allowable limit'),
  date: z.coerce.date({ message: 'Valid date is required' }),
  note: z.string().trim().max(500, 'Note cannot exceed 500 characters').nullable().optional(),
  affectsCashBalance: z.coerce.boolean().default(true),
});

export const DebtQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  direction: DebtDirectionEnum.optional(),
  isSettled: z.preprocess((val) => {
    if (typeof val === 'string') {
      if (val === 'true') return true;
      if (val === 'false') return false;
    }
    return val;
  }, z.boolean().optional()),
  personName: z.string().trim().optional(),
  search: z.string().trim().optional(),
});

export * from './debts.types';
