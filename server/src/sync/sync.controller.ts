import { type NextFunction, type Request, type Response } from 'express';
import { ApiResponse } from '../common/utils';
import type { AuthenticatedRequest } from '../common/types/express';
import { transactionsService } from '../transactions/transactions.service';
import { debtsService } from '../debts/debts.service';

export class SyncController {
  async pull(req: Request, res: Response, next: NextFunction) {
    try {
      const authReq = req as AuthenticatedRequest;
      const sinceQuery = req.query.since as string | undefined;
      const since = sinceQuery ? new Date(sinceQuery) : undefined;

      const [transactions, debts] = await Promise.all([
        transactionsService.findAllForSync(authReq.user.id, since),
        debtsService.findAllForSync(authReq.user.id, since),
      ]);

      return ApiResponse.success(res, {
        transactions,
        debts,
        serverTime: new Date().toISOString(),
      });
    } catch (error) {
      next(error);
    }
  }
}

export const syncController = new SyncController();
