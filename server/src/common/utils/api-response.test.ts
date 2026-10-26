import type { Response } from 'express';
import { ApiResponse } from './api-response';

describe('ApiResponse Utility', () => {
  let mockResponse: Partial<Response>;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockImplementation(() => mockResponse);
    mockResponse = {
      status: statusMock,
      json: jsonMock,
    } as unknown as Response;
  });

  describe('ApiResponse.success', () => {
    it('should send default 200 success response with data', () => {
      ApiResponse.success(mockResponse as Response, { id: '123' });

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({
        success: true,
        data: { id: '123' },
      });
    });

    it('should include optional message and meta', () => {
      ApiResponse.success(
        mockResponse as Response,
        { id: '123' },
        { message: 'Fetched', meta: { cached: true }, statusCode: 200 },
      );

      expect(jsonMock).toHaveBeenCalledWith({
        success: true,
        data: { id: '123' },
        message: 'Fetched',
        meta: { cached: true },
      });
    });
  });

  describe('ApiResponse.created', () => {
    it('should send 201 status with created data', () => {
      ApiResponse.created(mockResponse as Response, { id: '456' }, { message: 'Item created' });

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(jsonMock).toHaveBeenCalledWith({
        success: true,
        data: { id: '456' },
        message: 'Item created',
      });
    });
  });

  describe('ApiResponse.paginated', () => {
    it('should send 200 with pagination metadata calculations', () => {
      const items = [{ id: 1 }, { id: 2 }];
      ApiResponse.paginated(mockResponse as Response, items, { page: 1, limit: 10, total: 25 });

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({
        success: true,
        data: items,
        meta: {
          page: 1,
          limit: 10,
          total: 25,
          totalPages: 3,
          hasNextPage: true,
          hasPrevPage: false,
        },
      });
    });
  });

  describe('ApiResponse error methods', () => {
    it('ApiResponse.error should send default 500 internal server error', () => {
      ApiResponse.error(mockResponse as Response, 'Something crashed');

      expect(statusMock).toHaveBeenCalledWith(500);
      expect(jsonMock).toHaveBeenCalledWith({
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: 'Something crashed',
          timestamp: expect.any(String),
        },
      });
    });

    it('ApiResponse.badRequest should send 400 with details', () => {
      ApiResponse.badRequest(mockResponse as Response, 'Invalid input', {
        details: ['email is required'],
      });

      expect(statusMock).toHaveBeenCalledWith(400);
      expect(jsonMock).toHaveBeenCalledWith({
        success: false,
        error: {
          code: 'BAD_REQUEST',
          message: 'Invalid input',
          details: ['email is required'],
          timestamp: expect.any(String),
        },
      });
    });

    it('ApiResponse.unauthorized should send 401', () => {
      ApiResponse.unauthorized(mockResponse as Response);
      expect(statusMock).toHaveBeenCalledWith(401);
    });

    it('ApiResponse.forbidden should send 403', () => {
      ApiResponse.forbidden(mockResponse as Response);
      expect(statusMock).toHaveBeenCalledWith(403);
    });

    it('ApiResponse.notFound should send 404 with path and method', () => {
      ApiResponse.notFound(mockResponse as Response, 'Route not found', {
        method: 'GET',
        path: '/test',
      });
      expect(statusMock).toHaveBeenCalledWith(404);
      expect(jsonMock).toHaveBeenCalledWith({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Route not found',
          method: 'GET',
          path: '/test',
          timestamp: expect.any(String),
        },
      });
    });

    it('ApiResponse.conflict should send 409', () => {
      ApiResponse.conflict(mockResponse as Response, 'Email already registered');
      expect(statusMock).toHaveBeenCalledWith(409);
    });
  });
});
