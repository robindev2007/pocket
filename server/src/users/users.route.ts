import { Router } from 'express';
import { usersController } from './users.controller';
import { authMiddleware } from '../common/middleware';

const router = Router();

router.get('/profile', authMiddleware, (req, res, next) => {
  usersController.getProfile(req, res).catch(next);
});

router.patch('/profile', authMiddleware, (req, res, next) => {
  usersController.updateProfile(req, res).catch(next);
});

export const usersRouter = router;
