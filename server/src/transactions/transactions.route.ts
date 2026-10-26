import { Router } from 'express';
import { transactionsController } from './transactions.controller';
import { authMiddleware } from '../common/middleware';

const router = Router();

// All transaction endpoints require authentication
router.use(authMiddleware);

router.post('/', (req, res, next) => {
  transactionsController.createTransaction(req, res).catch(next);
});

router.get('/', (req, res, next) => {
  transactionsController.getTransactions(req, res).catch(next);
});

router.get('/summary', (req, res, next) => {
  transactionsController.getBalanceSummary(req, res).catch(next);
});

router.get('/:id', (req, res, next) => {
  transactionsController.getTransactionById(req, res).catch(next);
});

router.patch('/:id', (req, res, next) => {
  transactionsController.updateTransaction(req, res).catch(next);
});

router.delete('/:id', (req, res, next) => {
  transactionsController.deleteTransaction(req, res).catch(next);
});

export const transactionsRouter = router;
