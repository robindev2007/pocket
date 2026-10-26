import type { Request, Response } from 'express';
import { debtsService } from './debts.service';
import {
  AddRepaymentSchema,
  CreateDebtSchema,
  DebtQuerySchema,
  UpdateDebtSchema,
} from './debts.dto';
import { ApiResponse } from '../common/utils';
import type { AuthenticatedRequest } from '../common/types/express';

export class DebtsController {
  async createDebt(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const validated = CreateDebtSchema.parse(req.body);
    const result = await debtsService.createDebt(authReq.user.id, validated);

    return ApiResponse.created(res, result, {
      message: 'Debt record created successfully',
    });
  }

  async getDebts(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const query = DebtQuerySchema.parse(req.query);
    const { items, total, page, limit } = await debtsService.getDebts(authReq.user.id, query);

    return ApiResponse.paginated(res, items, { page, limit, total });
  }

  async getDebtSummary(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const summary = await debtsService.getDebtSummary(authReq.user.id);
    return ApiResponse.success(res, summary);
  }

  async getDebtById(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    const debt = await debtsService.getDebtById(authReq.user.id, id);
    return ApiResponse.success(res, debt);
  }

  async updateDebt(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    const validated = UpdateDebtSchema.parse(req.body);
    const updated = await debtsService.updateDebt(authReq.user.id, id, validated);

    return ApiResponse.success(res, updated, {
      message: 'Debt record updated successfully',
    });
  }

  async deleteDebt(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    await debtsService.softDeleteDebt(authReq.user.id, id);

    return ApiResponse.success(
      res,
      { id },
      {
        message: 'Debt record deleted successfully',
      },
    );
  }

  async addRepayment(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    const validated = AddRepaymentSchema.parse(req.body);
    const updated = await debtsService.addRepayment(authReq.user.id, id, validated);

    return ApiResponse.created(res, updated, {
      message: 'Repayment recorded successfully',
    });
  }

  async deleteRepayment(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const id = req.params.id as string;
    const repaymentId = req.params.repaymentId as string;
    const updated = await debtsService.deleteRepayment(authReq.user.id, id, repaymentId);

    return ApiResponse.success(res, updated, {
      message: 'Repayment deleted successfully',
    });
  }
}

export const debtsController = new DebtsController();
