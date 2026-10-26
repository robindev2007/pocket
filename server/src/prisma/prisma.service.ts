import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

export const DEFAULT_TRANSACTION_OPTIONS = {
  maxWait: 15000, // 15 seconds to acquire connection and start transaction
  timeout: 30000, // 30 seconds to execute transaction
} as const;

export class PrismaService extends PrismaClient {
  private static instance: PrismaService;
  private readonly pool: pg.Pool;

  constructor() {
    const connectionString = process.env.DATABASE_URL!;
    const pool = new pg.Pool({
      connectionString,
      max: 10,
      connectionTimeoutMillis: 15000,
      idleTimeoutMillis: 30000,
    });
    const adapter = new PrismaPg(pool);
    super({ adapter });
    this.pool = pool;
  }

  public static getInstance(): PrismaService {
    if (!PrismaService.instance) {
      PrismaService.instance = new PrismaService();
    }
    return PrismaService.instance;
  }

  /**
   * Overrides $transaction to set high-resilience defaults for cloud-hosted databases
   * (e.g. Prisma Data Platform, Neon) and automatically retries transient P2028 timeouts.
   */
  override $transaction: PrismaClient['$transaction'] = (async (args: any, options?: any) => {
    if (typeof args === 'function') {
      const mergedOptions = {
        ...DEFAULT_TRANSACTION_OPTIONS,
        ...options,
      };

      try {
        return await (super.$transaction as any)(args, mergedOptions);
      } catch (err: any) {
        if (
          err?.code === 'P2028' ||
          (typeof err?.message === 'string' &&
            err.message.includes('Unable to start a transaction in the given time'))
        ) {
          return await (super.$transaction as any)(args, {
            ...mergedOptions,
            maxWait: 25000,
            timeout: 45000,
          });
        }
        throw err;
      }
    }
    return (super.$transaction as any)(args, options);
  }) as PrismaClient['$transaction'];

  async connect(): Promise<void> {
    await this.$connect();
  }

  async disconnect(): Promise<void> {
    await this.$disconnect();
    await this.pool.end();
  }
}

export const prisma = PrismaService.getInstance();
