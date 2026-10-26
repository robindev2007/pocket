import { Router } from 'express';
import { debtsController } from './debts.controller';
import { authMiddleware } from '../common/middleware';

const router = Router();

// All debt endpoints require authentication
router.use(authMiddleware);

router.post('/', (req, res, next) => {
  debtsController.createDebt(req, res).catch(next);
});

router.get('/', (req, res, next) => {
  debtsController.getDebts(req, res).catch(next);
});

router.get('/summary', (req, res, next) => {
  debtsController.getDebtSummary(req, res).catch(next);
});

router.get('/:id', (req, res, next) => {
  debtsController.getDebtById(req, res).catch(next);
});

router.patch('/:id', (req, res, next) => {
  debtsController.updateDebt(req, res).catch(next);
});

router.delete('/:id', (req, res, next) => {
  debtsController.deleteDebt(req, res).catch(next);
});

router.post('/:id/repayments', (req, res, next) => {
  debtsController.addRepayment(req, res).catch(next);
});

router.delete('/:id/repayments/:repaymentId', (req, res, next) => {
  debtsController.deleteRepayment(req, res).catch(next);
});

export const debtsRouter = router;
