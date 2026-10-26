import type { Request, Response } from 'express';
import { GoogleSignInSchema } from './auth.dto';
import { authService } from './auth.service';
import { ApiResponse } from '../common/utils';

export class AuthController {
  async signInWithGoogle(req: Request, res: Response): Promise<Response> {
    const validated = GoogleSignInSchema.parse(req.body);
    const result = await authService.googleSignIn(validated.idToken);

    return ApiResponse.success(res, result, {
      message: 'Authenticated successfully with Google',
    });
  }

  async getMe(req: Request, res: Response): Promise<Response> {
    const user = await authService.getUserById(req.user!.id);
    return ApiResponse.success(res, user);
  }
}

export const authController = new AuthController();
