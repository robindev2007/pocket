import type { Request, Response } from 'express';
import { usersService } from './users.service';
import { UpdateProfileSchema } from './users.dto';
import { ApiResponse } from '../common/utils';
import type { AuthenticatedRequest } from '../common/types/express';

export class UsersController {
  async getProfile(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const profile = await usersService.findById(authReq.user.id);
    return ApiResponse.success(res, profile);
  }

  async updateProfile(req: Request, res: Response): Promise<Response> {
    const authReq = req as AuthenticatedRequest;
    const validated = UpdateProfileSchema.parse(req.body);
    const updated = await usersService.updateProfile(authReq.user.id, validated);

    return ApiResponse.success(res, updated, {
      message: 'Profile updated successfully',
    });
  }
}

export const usersController = new UsersController();
