import { Router } from 'express';
import { authController } from './auth.controller';
import { authMiddleware } from '../common/middleware';

const router = Router();

router.post('/google', (req, res, next) => {
  authController.signInWithGoogle(req, res).catch(next);
});

router.get('/me', authMiddleware, (req, res, next) => {
  authController.getMe(req, res).catch(next);
});

export const authRouter = router;
