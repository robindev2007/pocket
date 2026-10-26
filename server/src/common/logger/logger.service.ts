export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export type LogTransport = (level: LogLevel, message: string, meta?: unknown) => void;

export interface LogEntry {
  level: LogLevel;
  message: string;
  meta?: unknown;
  timestamp: string;
}

// ANSI Color constants for terminal output
const ANSI = {
  reset: '\x1b[0m',
  dim: '\x1b[90m',
  blue: '\x1b[34m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  boldRed: '\x1b[1;31m',
} as const;

const LevelColors: Record<LogLevel, string> = {
  debug: ANSI.dim,
  info: ANSI.green,
  warn: ANSI.yellow,
  error: ANSI.boldRed,
};

/**
 * LoggerService
 * Pluggable, lightweight logging service.
 * Supports custom 3rd-party transports (e.g. Sentry, Datadog, CloudWatch, Axiom).
 */
export class LoggerService {
  private transports: LogTransport[] = [];

  constructor() {
    // Default transport: Formatted console output
    this.addTransport(this.defaultConsoleTransport.bind(this));
  }

  /**
   * Adds a custom transport for third-party services (e.g. Sentry, Datadog, Logtail).
   * Example: logger.addTransport((level, msg, meta) => Sentry.captureMessage(msg));
   */
  public addTransport(transport: LogTransport): void {
    this.transports.push(transport);
  }

  public info(message: string, meta?: unknown): void {
    this.log('info', message, meta);
  }

  public warn(message: string, meta?: unknown): void {
    this.log('warn', message, meta);
  }

  public error(message: string, error?: unknown, meta?: unknown): void {
    const errorDetails =
      error instanceof Error
        ? { message: error.message, stack: error.stack, ...((meta as object) || {}) }
        : { raw: error, ...((meta as object) || {}) };

    this.log('error', message, errorDetails);
  }

  public debug(message: string, meta?: unknown): void {
    this.log('debug', message, meta);
  }

  private log(level: LogLevel, message: string, meta?: unknown): void {
    for (const transport of this.transports) {
      try {
        transport(level, message, meta);
      } catch (err) {
        console.error('Logger transport error:', err);
      }
    }
  }

  /**
   * Default console transport:
   * - In development: Pretty human-readable colorized logs
   * - In production: Structured JSON (standard for Docker, CloudWatch, Datadog stdout ingestion)
   * - In test: Silenced
   */
  private defaultConsoleTransport(level: LogLevel, message: string, meta?: unknown): void {
    if (process.env.NODE_ENV === 'test') {
      return;
    }

    const timestamp = new Date().toISOString();

    if (process.env.NODE_ENV === 'production') {
      // Structured JSON format for cloud log drivers
      console.log(
        JSON.stringify({
          timestamp,
          level,
          message,
          ...(meta !== undefined ? { meta } : {}),
        }),
      );
      return;
    }

    // Pretty colored development format
    const color = LevelColors[level];
    const prefix = `${ANSI.dim}[${timestamp}]${ANSI.reset} ${color}${level.toUpperCase().padEnd(5)}${ANSI.reset}`;
    const metaStr = meta !== undefined ? `\n${JSON.stringify(meta, null, 2)}` : '';

    console.log(`${prefix} ${message}${metaStr}`);
  }
}

// Export singleton instance for app-wide use
export const logger = new LoggerService();
