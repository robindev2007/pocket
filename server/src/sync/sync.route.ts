import { Router } from 'express';
import { authMiddleware } from '../common/middleware';
import { syncController } from './sync.controller';

const router = Router();

router.use(authMiddleware);

router.get('/pull', (req, res, next) => {
  syncController.pull(req, res, next);
});

export { router as syncRouter };
