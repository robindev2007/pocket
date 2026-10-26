import type { Response } from 'express';

// ---------------------------------------------------------
// RESPONSE TYPES & INTERFACES
// ---------------------------------------------------------

export interface ApiResponseMeta {
  page?: number;
  limit?: number;
  total?: number;
  totalPages?: number;
  hasNextPage?: boolean;
  hasPrevPage?: boolean;
  [key: string]: unknown;
}

export interface ApiSuccessResponse<T = unknown> {
  success: true;
  data: T;
  message?: string;
  meta?: ApiResponseMeta;
}

export interface ApiErrorDetail {
  code: string;
  message: string;
  method?: string;
  path?: string;
  details?: unknown;
  timestamp: string;
}

export interface ApiErrorResponse {
  success: false;
  error: ApiErrorDetail;
}

export type ApiResponsePayload<T = unknown> = ApiSuccessResponse<T> | ApiErrorResponse;

export interface SendSuccessOptions {
  message?: string;
  statusCode?: number;
  meta?: ApiResponseMeta;
}

export interface SendErrorOptions {
  statusCode?: number;
  code?: string;
  details?: unknown;
  method?: string;
  path?: string;
}

// ---------------------------------------------------------
// INTERNAL HELPERS
// ---------------------------------------------------------

const sendSuccess = <T>(res: Response, data: T, options?: SendSuccessOptions): Response => {
  const statusCode = options?.statusCode ?? 200;
  const payload: ApiSuccessResponse<T> = {
    success: true,
    data,
    ...(options?.message ? { message: options.message } : {}),
    ...(options?.meta ? { meta: options.meta } : {}),
  };

  return res.status(statusCode).json(payload);
};

const sendCreated = <T>(
  res: Response,
  data: T,
  options?: Omit<SendSuccessOptions, 'statusCode'>,
): Response => {
  return sendSuccess(res, data, {
    ...options,
    statusCode: 201,
  });
};

const sendPaginated = <T>(
  res: Response,
  items: T[],
  pagination: {
    page: number;
    limit: number;
    total: number;
  },
  message?: string,
): Response => {
  const totalPages = Math.ceil(pagination.total / pagination.limit) || 1;
  return sendSuccess(res, items, {
    message,
    statusCode: 200,
    meta: {
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages,
      hasNextPage: pagination.page < totalPages,
      hasPrevPage: pagination.page > 1,
    },
  });
};

const sendError = (res: Response, message: string, options?: SendErrorOptions): Response => {
  const statusCode = options?.statusCode ?? 500;
  const code = options?.code ?? 'INTERNAL_SERVER_ERROR';

  const payload: ApiErrorResponse = {
    success: false,
    error: {
      code,
      message,
      ...(options?.method ? { method: options.method } : {}),
      ...(options?.path ? { path: options.path } : {}),
      ...(options?.details !== undefined ? { details: options.details } : {}),
      timestamp: new Date().toISOString(),
    },
  };

  return res.status(statusCode).json(payload);
};

const sendBadRequest = (
  res: Response,
  message = 'Bad Request',
  options?: Omit<SendErrorOptions, 'statusCode'>,
): Response => {
  return sendError(res, message, {
    statusCode: 400,
    code: options?.code ?? 'BAD_REQUEST',
    ...options,
  });
};

const sendUnauthorized = (
  res: Response,
  message = 'Unauthorized',
  options?: Omit<SendErrorOptions, 'statusCode'>,
): Response => {
  return sendError(res, message, {
    statusCode: 401,
    code: options?.code ?? 'UNAUTHORIZED',
    ...options,
  });
};

const sendForbidden = (
  res: Response,
  message = 'Forbidden',
  options?: Omit<SendErrorOptions, 'statusCode'>,
): Response => {
  return sendError(res, message, {
    statusCode: 403,
    code: options?.code ?? 'FORBIDDEN',
    ...options,
  });
};

const sendNotFound = (
  res: Response,
  message = 'Not Found',
  options?: Omit<SendErrorOptions, 'statusCode'>,
): Response => {
  return sendError(res, message, {
    statusCode: 404,
    code: options?.code ?? 'NOT_FOUND',
    ...options,
  });
};

const sendConflict = (
  res: Response,
  message = 'Conflict',
  options?: Omit<SendErrorOptions, 'statusCode'>,
): Response => {
  return sendError(res, message, {
    statusCode: 409,
    code: options?.code ?? 'CONFLICT',
    ...options,
  });
};

// ---------------------------------------------------------
// EXPORT ONLY THE UNIFIED NAMESPACE
// ---------------------------------------------------------

export const ApiResponse = {
  success: sendSuccess,
  created: sendCreated,
  paginated: sendPaginated,
  error: sendError,
  badRequest: sendBadRequest,
  unauthorized: sendUnauthorized,
  forbidden: sendForbidden,
  notFound: sendNotFound,
  conflict: sendConflict,
} as const;
