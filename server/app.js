// src/app.ts
import express from 'express';

// src/auth/auth.route.ts
import { Router } from 'express';

// src/auth/auth.dto.ts
import { z } from 'zod';
var GoogleSignInSchema = z.object({
  idToken: z.string().min(1, 'Google ID token is required'),
});

// src/auth/auth.service.ts
import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';

// src/common/errors/app-error.ts
class AppError extends Error {
  statusCode;
  code;
  isOperational;
  details;
  constructor(message, statusCode = 500, code = 'INTERNAL_SERVER_ERROR', details) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true;
    Object.setPrototypeOf(this, new.target.prototype);
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
  static badRequest(message = 'Bad Request', details) {
    return new AppError(message, 400, 'BAD_REQUEST', details);
  }
  static unauthorized(message = 'Unauthorized', details) {
    return new AppError(message, 401, 'UNAUTHORIZED', details);
  }
  static forbidden(message = 'Forbidden', details) {
    return new AppError(message, 403, 'FORBIDDEN', details);
  }
  static notFound(message = 'Not Found', details) {
    return new AppError(message, 404, 'NOT_FOUND', details);
  }
  static conflict(message = 'Conflict', details) {
    return new AppError(message, 409, 'CONFLICT', details);
  }
  static internal(message = 'Internal Server Error', details) {
    return new AppError(message, 500, 'INTERNAL_SERVER_ERROR', details);
  }
}
// src/prisma/prisma.service.ts
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

class PrismaService extends PrismaClient {
  static instance;
  pool;
  constructor() {
    const connectionString = process.env.DATABASE_URL;
    const pool = new pg.Pool({ connectionString });
    const adapter = new PrismaPg(pool);
    super({ adapter });
    this.pool = pool;
  }
  static getInstance() {
    if (!PrismaService.instance) {
      PrismaService.instance = new PrismaService();
    }
    return PrismaService.instance;
  }
  async connect() {
    await this.$connect();
  }
  async disconnect() {
    await this.$disconnect();
    await this.pool.end();
  }
}
var prisma = PrismaService.getInstance();

// src/users/users.service.ts
class UsersService {
  async findById(id) {
    const user = await prisma.user.findUnique({
      where: { id },
    });
    if (!user) {
      throw AppError.notFound('User profile not found');
    }
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      bio: user.bio,
      currency: user.currency,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
      syncVersion: user.syncVersion.toString(),
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
  async findByEmail(email) {
    return prisma.user.findUnique({
      where: { email },
    });
  }
  async upsertGoogleUser(dto) {
    return prisma.user.upsert({
      where: { email: dto.email },
      update: {
        googleId: dto.googleId,
        name: dto.name || undefined,
        avatar: dto.avatar !== undefined ? dto.avatar : undefined,
      },
      create: {
        googleId: dto.googleId,
        email: dto.email,
        name: dto.name || 'User',
        avatar: dto.avatar,
      },
    });
  }
  async updateProfile(id, dto) {
    await this.findById(id);
    const updated = await prisma.user.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.bio !== undefined ? { bio: dto.bio } : {}),
        ...(dto.currency !== undefined ? { currency: dto.currency } : {}),
        ...(dto.avatar !== undefined ? { avatar: dto.avatar } : {}),
        ...(dto.hasCompletedOnboarding !== undefined
          ? { hasCompletedOnboarding: dto.hasCompletedOnboarding }
          : {}),
      },
    });
    return {
      id: updated.id,
      email: updated.email,
      name: updated.name,
      avatar: updated.avatar,
      bio: updated.bio,
      currency: updated.currency,
      hasCompletedOnboarding: updated.hasCompletedOnboarding,
      syncVersion: updated.syncVersion.toString(),
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    };
  }
}
var usersService = new UsersService();

// src/auth/auth.service.ts
var getJwtSecret = () => {
  return process.env.JWT_SECRET || 'dev-secret-jwt-key-replace-in-env';
};

class AuthService {
  googleClient;
  constructor() {
    this.googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
  }
  async verifyGoogleToken(idToken) {
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID || undefined,
      });
      const payload = ticket.getPayload();
      if (!payload || !payload.sub || !payload.email) {
        throw AppError.unauthorized('Invalid Google token payload');
      }
      return payload;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw AppError.unauthorized('Failed to verify Google ID token');
    }
  }
  async googleSignIn(idToken) {
    const payload = await this.verifyGoogleToken(idToken);
    const user = await usersService.upsertGoogleUser({
      googleId: payload.sub,
      email: payload.email,
      name: payload.name,
      avatar: payload.picture,
    });
    const accessToken = jwt.sign(
      {
        id: user.id,
        email: user.email,
      },
      getJwtSecret(),
      { expiresIn: '7d' },
    );
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatar: user.avatar,
        currency: user.currency,
        hasCompletedOnboarding: user.hasCompletedOnboarding,
      },
      accessToken,
    };
  }
  async getUserById(userId) {
    return usersService.findById(userId);
  }
}
var authService = new AuthService();

// src/common/utils/api-response.ts
var sendSuccess = (res, data, options) => {
  const statusCode = options?.statusCode ?? 200;
  const payload = {
    success: true,
    data,
    ...(options?.message ? { message: options.message } : {}),
    ...(options?.meta ? { meta: options.meta } : {}),
  };
  return res.status(statusCode).json(payload);
};
var sendCreated = (res, data, options) => {
  return sendSuccess(res, data, {
    ...options,
    statusCode: 201,
  });
};
var sendPaginated = (res, items, pagination, message) => {
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
var sendError = (res, message, options) => {
  const statusCode = options?.statusCode ?? 500;
  const code = options?.code ?? 'INTERNAL_SERVER_ERROR';
  const payload = {
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
var sendBadRequest = (res, message = 'Bad Request', options) => {
  return sendError(res, message, {
    statusCode: 400,
    code: options?.code ?? 'BAD_REQUEST',
    ...options,
  });
};
var sendUnauthorized = (res, message = 'Unauthorized', options) => {
  return sendError(res, message, {
    statusCode: 401,
    code: options?.code ?? 'UNAUTHORIZED',
    ...options,
  });
};
var sendForbidden = (res, message = 'Forbidden', options) => {
  return sendError(res, message, {
    statusCode: 403,
    code: options?.code ?? 'FORBIDDEN',
    ...options,
  });
};
var sendNotFound = (res, message = 'Not Found', options) => {
  return sendError(res, message, {
    statusCode: 404,
    code: options?.code ?? 'NOT_FOUND',
    ...options,
  });
};
var sendConflict = (res, message = 'Conflict', options) => {
  return sendError(res, message, {
    statusCode: 409,
    code: options?.code ?? 'CONFLICT',
    ...options,
  });
};
var ApiResponse = {
  success: sendSuccess,
  created: sendCreated,
  paginated: sendPaginated,
  error: sendError,
  badRequest: sendBadRequest,
  unauthorized: sendUnauthorized,
  forbidden: sendForbidden,
  notFound: sendNotFound,
  conflict: sendConflict,
};
// src/auth/auth.controller.ts
class AuthController {
  async signInWithGoogle(req, res) {
    const validated = GoogleSignInSchema.parse(req.body);
    const result = await authService.googleSignIn(validated.idToken);
    return ApiResponse.success(res, result, {
      message: 'Authenticated successfully with Google',
    });
  }
  async getMe(req, res) {
    const authReq = req;
    const user = await authService.getUserById(authReq.user.id);
    return ApiResponse.success(res, user);
  }
}
var authController = new AuthController();

// src/common/middleware/auth.middleware.ts
import jwt2 from 'jsonwebtoken';
var getJwtSecret2 = () => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    if (false) {
    }
    return 'dev-secret-jwt-key-replace-in-env';
  }
  return secret;
};
var authMiddleware = (req, _res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw AppError.unauthorized('Authentication token is required');
  }
  const token = authHeader.split(' ')[1];
  if (!token) {
    throw AppError.unauthorized('Authentication token is missing');
  }
  try {
    const decoded = jwt2.verify(token, getJwtSecret2());
    if (!decoded || !decoded.id) {
      throw AppError.unauthorized('Invalid token payload');
    }
    req.user = {
      id: decoded.id,
      email: decoded.email,
    };
    next();
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    if (error instanceof jwt2.TokenExpiredError) {
      throw AppError.unauthorized('Authentication token has expired');
    }
    throw AppError.unauthorized('Invalid authentication token');
  }
};
// src/common/middleware/error.middleware.ts
import { ZodError } from 'zod';

// src/common/logger/logger.service.ts
var ANSI = {
  reset: '\x1B[0m',
  dim: '\x1B[90m',
  blue: '\x1B[34m',
  green: '\x1B[32m',
  yellow: '\x1B[33m',
  red: '\x1B[31m',
  boldRed: '\x1B[1;31m',
};
var LevelColors = {
  debug: ANSI.dim,
  info: ANSI.green,
  warn: ANSI.yellow,
  error: ANSI.boldRed,
};

class LoggerService {
  transports = [];
  constructor() {
    this.addTransport(this.defaultConsoleTransport.bind(this));
  }
  addTransport(transport) {
    this.transports.push(transport);
  }
  info(message, meta) {
    this.log('info', message, meta);
  }
  warn(message, meta) {
    this.log('warn', message, meta);
  }
  error(message, error, meta) {
    const errorDetails =
      error instanceof Error
        ? { message: error.message, stack: error.stack, ...(meta || {}) }
        : { raw: error, ...(meta || {}) };
    this.log('error', message, errorDetails);
  }
  debug(message, meta) {
    this.log('debug', message, meta);
  }
  log(level, message, meta) {
    for (const transport of this.transports) {
      try {
        transport(level, message, meta);
      } catch (err) {
        console.error('Logger transport error:', err);
      }
    }
  }
  defaultConsoleTransport(level, message, meta) {
    if (false) {
    }
    const timestamp = new Date().toISOString();
    if (false) {
    }
    const color = LevelColors[level];
    const prefix = `${ANSI.dim}[${timestamp}]${ANSI.reset} ${color}${level.toUpperCase().padEnd(5)}${ANSI.reset}`;
    const metaStr =
      meta !== undefined
        ? `
${JSON.stringify(meta, null, 2)}`
        : '';
    console.log(`${prefix} ${message}${metaStr}`);
  }
}
var logger = new LoggerService();
// src/common/middleware/error.middleware.ts
var errorMiddleware = (err, _req, res, _next) => {
  if (err instanceof AppError) {
    ApiResponse.error(res, err.message, {
      statusCode: err.statusCode,
      code: err.code,
      details: err.details,
    });
    return;
  }
  if (err instanceof ZodError) {
    ApiResponse.badRequest(res, 'Validation failed', {
      details: err.issues,
    });
    return;
  }
  logger.error('Unhandled Server Error', err);
  const message = err instanceof Error ? err.message : 'Internal Server Error';
  ApiResponse.error(res, message, {
    statusCode: 500,
    code: 'INTERNAL_SERVER_ERROR',
  });
};
// src/common/middleware/logger.middleware.ts
var ANSI2 = {
  reset: '\x1B[0m',
  dim: '\x1B[90m',
  green: '\x1B[32m',
  yellow: '\x1B[33m',
  red: '\x1B[31m',
  cyan: '\x1B[36m',
  magenta: '\x1B[35m',
  boldRed: '\x1B[1;31m',
};
var getMethodColor = (method) => {
  switch (method.toUpperCase()) {
    case 'GET':
      return ANSI2.cyan;
    case 'POST':
      return ANSI2.green;
    case 'PUT':
    case 'PATCH':
      return ANSI2.yellow;
    case 'DELETE':
      return ANSI2.red;
    default:
      return ANSI2.magenta;
  }
};
var getStatusColor = (status) => {
  if (status >= 500) return ANSI2.boldRed;
  if (status >= 400) return ANSI2.red;
  if (status >= 300) return ANSI2.cyan;
  if (status >= 200) return ANSI2.green;
  return ANSI2.reset;
};
var loggerMiddleware = (req, res, next) => {
  const isDevelopment = true;
  if (!isDevelopment) {
    next();
    return;
  }
  const start = performance.now();
  const timestamp = new Date().toISOString();
  res.on('finish', () => {
    const duration = (performance.now() - start).toFixed(2);
    const methodColor = getMethodColor(req.method);
    const statusColor = getStatusColor(res.statusCode);
    const logMessage = `${ANSI2.dim}[${timestamp}]${ANSI2.reset} ${methodColor}${req.method}${ANSI2.reset} ${req.originalUrl} ${statusColor}${res.statusCode}${ANSI2.reset} ${ANSI2.dim}(${duration}ms)${ANSI2.reset}`;
    console.log(logMessage);
  });
  next();
};
// src/common/middleware/not-found.middleware.ts
var notFoundMiddleware = (req, res, _next) => {
  ApiResponse.notFound(res, `Cannot ${req.method} ${req.originalUrl}`, {
    method: req.method,
    path: req.originalUrl,
  });
};
// src/auth/auth.route.ts
var router = Router();
router.post('/google', (req, res, next) => {
  authController.signInWithGoogle(req, res).catch(next);
});
router.get('/me', authMiddleware, (req, res, next) => {
  authController.getMe(req, res).catch(next);
});
var authRouter = router;

// src/users/users.route.ts
import { Router as Router2 } from 'express';

// src/users/users.dto.ts
import { z as z2 } from 'zod';
var UpdateProfileSchema = z2.object({
  name: z2.string().min(1, 'Name cannot be empty').max(100).optional(),
  bio: z2.string().max(300).nullable().optional(),
  currency: z2.string().min(3).max(3).toUpperCase().optional(),
  avatar: z2.string().url('Invalid avatar URL').nullable().optional(),
  hasCompletedOnboarding: z2.boolean().optional(),
});

// src/users/users.controller.ts
class UsersController {
  async getProfile(req, res) {
    const authReq = req;
    const profile = await usersService.findById(authReq.user.id);
    return ApiResponse.success(res, profile);
  }
  async updateProfile(req, res) {
    const authReq = req;
    const validated = UpdateProfileSchema.parse(req.body);
    const updated = await usersService.updateProfile(authReq.user.id, validated);
    return ApiResponse.success(res, updated, {
      message: 'Profile updated successfully',
    });
  }
}
var usersController = new UsersController();

// src/users/users.route.ts
var router2 = Router2();
router2.get('/profile', authMiddleware, (req, res, next) => {
  usersController.getProfile(req, res).catch(next);
});
router2.patch('/profile', authMiddleware, (req, res, next) => {
  usersController.updateProfile(req, res).catch(next);
});
var usersRouter = router2;

// src/app.ts
BigInt.prototype.toJSON = function () {
  return this.toString();
};
var createApp = () => {
  const app = express();
  app.use(loggerMiddleware);
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  app.get('/', (_req, res) => {
    res.status(200).json({
      message: 'Pocket API is running',
      docs: '/health',
    });
  });
  app.get('/health', (_req, res) => {
    res.status(200).json({
      status: 'ok',
      uptime: +process.uptime().toPrecision(2),
      timestamp: new Date().toISOString(),
    });
  });
  app.use('/auth', authRouter);
  app.use('/users', usersRouter);
  app.use(notFoundMiddleware);
  app.use(errorMiddleware);
  return app;
};
var app = createApp();

// src/index.ts
var PORT = Number(process.env.PORT) || 3000;
if (!process.env.VERCEL) {
  const server = app.listen(PORT, () => {
    console.log(`\uD83D\uDE80 Server is running on http://localhost:${PORT}`);
  });
  const shutdown = (signal) => {
    console.log(`
Received ${signal}. Shutting down gracefully...`);
    server.close(() => {
      console.log('Server closed successfully.');
      process.exit(0);
    });
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}
var src_default = app;
export { src_default as default };
