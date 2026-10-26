import type { NextFunction, Request, Response } from 'express';
import { ApiResponse } from '../utils';

export const notFoundMiddleware = (req: Request, res: Response, _next: NextFunction): void => {
  ApiResponse.notFound(res, `Cannot ${req.method} ${req.originalUrl}`, {
    method: req.method,
    path: req.originalUrl,
  });
};
