import { z } from 'zod';

const normalizeType = (val: unknown): string => {
  if (typeof val === 'string') {
    return val.toUpperCase();
  }
  return val as string;
};

export const TransactionTypeEnum = z.preprocess(
  normalizeType,
  z.enum(['INCOME', 'EXPENSE', 'TRANSFER'], {
    message: "Type must be 'INCOME', 'EXPENSE', or 'TRANSFER'",
  }),
);

export const CreateTransactionSchema = z.object({
  id: z.string().uuid().optional(),
  title: z
    .string({ message: 'Title is required' })
    .trim()
    .min(1, 'Title cannot be empty')
    .max(150, 'Title cannot exceed 150 characters'),
  amount: z.coerce
    .number({ message: 'Amount is required' })
    .positive('Amount must be greater than zero')
    .max(999999999999.99, 'Amount exceeds maximum allowable limit'),
  type: TransactionTypeEnum,
  date: z.coerce.date({ message: 'Valid date is required' }),
  tag: z.string().trim().max(50, 'Tag cannot exceed 50 characters').nullable().optional(),
  note: z.string().trim().max(500, 'Note cannot exceed 500 characters').nullable().optional(),
});

export const UpdateTransactionSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, 'Title cannot be empty')
    .max(150, 'Title cannot exceed 150 characters')
    .optional(),
  amount: z.coerce
    .number()
    .positive('Amount must be greater than zero')
    .max(999999999999.99, 'Amount exceeds maximum allowable limit')
    .optional(),
  type: TransactionTypeEnum.optional(),
  date: z.coerce.date().optional(),
  tag: z.string().trim().max(50, 'Tag cannot exceed 50 characters').nullable().optional(),
  note: z.string().trim().max(500, 'Note cannot exceed 500 characters').nullable().optional(),
});

export const TransactionQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  type: TransactionTypeEnum.optional(),
  tag: z.string().trim().optional(),
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
  search: z.string().trim().optional(),
});

export * from './transactions.types';
