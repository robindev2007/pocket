import type { Request, Response } from 'express';
import { transactionsService } from './transactions.service';
import {
  CreateTransactionSchema,
  TransactionQuerySchema,
  UpdateTransactionSchema,
} from './transactions.dto';
import { ApiResponse } from '../common/utils';
import type { AuthenticatedRequest } from '../common/types/express';

export class TransactionsController {
  async createTransaction(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const validated = CreateTransactionSchema.parse(req.body);
    const result = await transactionsService.create(authReq.user.id, validated);

    return ApiResponse.created(res, result, {
      message: 'Transaction created successfully',
    });
  }

  async getTransactions(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const query = TransactionQuerySchema.parse(req.query);
    const { items, total, page, limit } = await transactionsService.findAll(authReq.user.id, query);

    return ApiResponse.paginated(res, items, { page, limit, total });
  }

  async getBalanceSummary(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const summary = await transactionsService.getBalanceSummary(authReq.user.id);
    return ApiResponse.success(res, summary);
  }

  async getTransactionById(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    const transaction = await transactionsService.findById(authReq.user.id, id);
    return ApiResponse.success(res, transaction);
  }

  async updateTransaction(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    const validated = UpdateTransactionSchema.parse(req.body);
    const updated = await transactionsService.update(authReq.user.id, id, validated);

    return ApiResponse.success(res, updated, {
      message: 'Transaction updated successfully',
    });
  }

  async deleteTransaction(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    await transactionsService.softDelete(authReq.user.id, id);

    return ApiResponse.success(
      res,
      { id },
      {
        message: 'Transaction deleted successfully',
      },
    );
  }
}

export const transactionsController = new TransactionsController();
