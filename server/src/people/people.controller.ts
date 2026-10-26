import type { Request, Response } from 'express';
import { ApiResponse } from '../common/utils';
import { PeopleService } from './people.service';

export class PeopleController {
  constructor(private readonly peopleService = new PeopleService()) {}

  getPeople = async (req: Request, res: Response): Promise<void> => {
    const userId = req.user!.id;
    const people = await this.peopleService.getPeople(userId);
    ApiResponse.success(res, people, { message: 'People summaries retrieved successfully' });
  };

  getPersonLedger = async (req: Request, res: Response): Promise<void> => {
    const userId = req.user!.id;
    const name = decodeURIComponent(req.params.name as string);
    const ledger = await this.peopleService.getPersonLedger(userId, name);
    ApiResponse.success(res, ledger, { message: 'Person ledger statement retrieved successfully' });
  };
}
