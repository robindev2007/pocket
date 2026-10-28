import express, { type Application, type Request, type Response } from 'express';
import { authRouter } from './auth/auth.route';
import { usersRouter } from './users/users.route';
import { transactionsRouter } from './transactions/transactions.route';
import { debtsRouter } from './debts/debts.route';
import { peopleRouter } from './people/people.route';
import { syncRouter } from './sync/sync.route';
import { aiRouter } from './ai/ai.route';
import { errorMiddleware, loggerMiddleware, notFoundMiddleware } from './common/middleware';

// Safely serialize BigInt to string in JSON responses
(BigInt.prototype as unknown as { toJSON: () => string }).toJSON = function () {
  return this.toString();
};

export const createApp = (): Application => {
  const app = express();

  // CORS Middleware for Web and Local Development
  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
    res.header('Access-Control-Allow-Credentials', 'true');
    if (req.method === 'OPTIONS') {
      res.sendStatus(204);
      return;
    }
    next();
  });

  // Core Middlewares
  app.use(loggerMiddleware);
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Root endpoint
  app.get('/', (_req: Request, res: Response) => {
    res.status(200).json({
      message: 'Pocket API is running',
      docs: '/health',
    });
  });

  // Health check endpoint
  app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'ok',
      uptime: +process.uptime().toPrecision(2),
      timestamp: new Date().toISOString(),
    });
  });

  // Feature Routes
  app.use('/auth', authRouter);
  app.use('/users', usersRouter);
  app.use('/transactions', transactionsRouter);
  app.use('/debts', debtsRouter);
  app.use('/people', peopleRouter);
  app.use('/sync', syncRouter);
  app.use('/ai', aiRouter);

  // 404 Not Found Middleware (catches unhandled routes)
  app.use(notFoundMiddleware);

  // Global Error Handling Middleware (catches thrown errors / next(err))
  app.use(errorMiddleware);

  return app;
};

export const app = createApp();
export default app;
