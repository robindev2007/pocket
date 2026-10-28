import { Router } from 'express';
import { authController } from './auth.controller';
import { authMiddleware } from '../common/middleware';
import { ApiResponse } from '../common/utils/api-response';

const router = Router();

router.get('/config', (_req, res) => {
  return ApiResponse.success(res, {
    googleClientId: process.env.GOOGLE_CLIENT_ID || null,
  });
});

router.post('/google', (req, res, next) => {
  authController.signInWithGoogle(req, res).catch(next);
});

router.get('/me', authMiddleware, (req, res, next) => {
  authController.getMe(req, res).catch(next);
});

export const authRouter = router;
