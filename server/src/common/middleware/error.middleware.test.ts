import type { NextFunction, Request, Response } from 'express';
import { z, ZodError } from 'zod';
import { AppError } from '../errors';
import { errorMiddleware } from './error.middleware';

describe('errorMiddleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;
  let nextMock: NextFunction;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockImplementation(() => mockResponse);
    mockResponse = {
      status: statusMock,
      json: jsonMock,
    } as unknown as Response;
    mockRequest = {};
    nextMock = jest.fn();
  });

  it('should handle AppError and respond with its status code and details', () => {
    const error = AppError.badRequest('Custom bad request', ['field invalid']);

    errorMiddleware(error, mockRequest as Request, mockResponse as Response, nextMock);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({
      success: false,
      error: {
        code: 'BAD_REQUEST',
        message: 'Custom bad request',
        details: ['field invalid'],
        timestamp: expect.any(String),
      },
    });
  });

  it('should handle ZodError and respond with 400 Bad Request', () => {
    const schema = z.object({
      email: z.string().email(),
    });

    let zodErr: ZodError | null = null;
    try {
      schema.parse({ email: 'invalid-email' });
    } catch (err) {
      zodErr = err as ZodError;
    }

    expect(zodErr).not.toBeNull();
    errorMiddleware(zodErr!, mockRequest as Request, mockResponse as Response, nextMock);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({
      success: false,
      error: {
        code: 'BAD_REQUEST',
        message: 'Validation failed',
        details: expect.any(Array),
        timestamp: expect.any(String),
      },
    });
  });

  it('should handle unhandled standard Error and respond with 500', () => {
    const unknownError = new Error('Database connection failed');

    errorMiddleware(unknownError, mockRequest as Request, mockResponse as Response, nextMock);

    expect(statusMock).toHaveBeenCalledWith(500);
    expect(jsonMock).toHaveBeenCalledWith({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Database connection failed',
        timestamp: expect.any(String),
      },
    });
  });
});
