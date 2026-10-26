import { AppError } from './app-error';

describe('AppError', () => {
  it('should instantiate an AppError with custom properties', () => {
    const error = new AppError('Something bad', 400, 'BAD_REQUEST', { field: 'name' });

    expect(error).toBeInstanceOf(Error);
    expect(error).toBeInstanceOf(AppError);
    expect(error.name).toBe('AppError');
    expect(error.message).toBe('Something bad');
    expect(error.statusCode).toBe(400);
    expect(error.code).toBe('BAD_REQUEST');
    expect(error.details).toEqual({ field: 'name' });
    expect(error.isOperational).toBe(true);
    expect(error.stack).toBeDefined();
  });

  describe('Static Factory Helpers', () => {
    it('AppError.badRequest', () => {
      const err = AppError.badRequest('Invalid input', ['email required']);
      expect(err.statusCode).toBe(400);
      expect(err.code).toBe('BAD_REQUEST');
      expect(err.details).toEqual(['email required']);
    });

    it('AppError.unauthorized', () => {
      const err = AppError.unauthorized('No token');
      expect(err.statusCode).toBe(401);
      expect(err.code).toBe('UNAUTHORIZED');
    });

    it('AppError.forbidden', () => {
      const err = AppError.forbidden('Forbidden action');
      expect(err.statusCode).toBe(403);
      expect(err.code).toBe('FORBIDDEN');
    });

    it('AppError.notFound', () => {
      const err = AppError.notFound('Resource missing');
      expect(err.statusCode).toBe(404);
      expect(err.code).toBe('NOT_FOUND');
    });

    it('AppError.conflict', () => {
      const err = AppError.conflict('Duplicate key');
      expect(err.statusCode).toBe(409);
      expect(err.code).toBe('CONFLICT');
    });

    it('AppError.internal', () => {
      const err = AppError.internal('Something crashed');
      expect(err.statusCode).toBe(500);
      expect(err.code).toBe('INTERNAL_SERVER_ERROR');
    });
  });
});
