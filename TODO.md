# Pocket Server — Implementation Roadmap & Feature Checklist

This document outlines the detailed roadmap for the backend server (`server/`), built to power and synchronize the **Pocket Flutter App** (`../app/`). It is structured following the **Feature-First / Vertical-Slice Architecture** defined in [`AGENT.md`](./AGENT.md) and the high-scalability principles in [`SYSTEM_DESIGN.md`](./SYSTEM_DESIGN.md).

---

## 🗺️ Architectural Overview & Alignment with Mobile App

The mobile client is a **Local-First, Offline-Capable Flutter App** storing records in local storage (`shared_preferences`). The server must support:

1. **Standard REST Endpoints**: For immediate CRUD operations when online.
2. **Delta Sync Protocol**: To batch-upload offline changes and download server-side deltas without payload bloat.
3. **Strict Precision**: Server uses `Decimal(14, 2)` to eliminate floating-point rounding errors on financial values.

---

## 📋 Feature Roadmap & Task List

### Phase 1: Core Foundation & Infrastructure (Completed)

- [x] **Runtime & Framework**: Initialized Bun with Express 5, TypeScript, and SWC-powered Jest.
- [x] **Database Setup**: Prisma 7 with PostgreSQL adapter (`@prisma/adapter-pg` + `pg`) and modular multi-file schema (`prisma/schema/`).
- [x] **Code Quality & Git Hooks**: Prettier formatting, `tsc --noEmit` build verification, and Husky `pre-commit` & `pre-push` hooks.
- [x] **Unified API Response Formatter**: `ApiResponse` envelope (`ApiResponse.success`, `ApiResponse.created`, `ApiResponse.paginated`, etc.).
- [x] **Error Handling Hierarchy**: `AppError` class with HTTP static factories (`notFound`, `badRequest`, etc.) + Express 5 global `errorMiddleware` catching Zod, Prisma, and unhandled errors.
- [x] **Development Logger**: Color-coded ANSI logger logging `method`, `route`, `status` (red on errors), and duration in development mode, bypassed in production.
- [x] **Pluggable Logger Service**: `LoggerService` singleton supporting custom 3rd-party transports (Datadog, Sentry, CloudWatch) with JSON output in production.

---

### Phase 2: Authentication & User Profile (Completed)

- [x] **Google OAuth ID Token Verification**: Official `google-auth-library` verifying cryptographic signatures against Google certs.
- [x] **App JWT Issuance**: Signs 7-day access tokens via `jsonwebtoken`.
- [x] **Authentication Guard**: `authMiddleware` reading `Authorization: Bearer <token>` and injecting typed `req.user`.
- [x] **Dedicated Users Feature**: Centralized `UsersService` owning `findById`, `upsertGoogleUser`, and `updateProfile` (ready for Redis caching).
- [x] **Endpoints Implemented**:
  - `POST /auth/google` (sign-in & user registration)
  - `GET /auth/me` (current session identity)
  - `GET /users/profile` (user profile data)
  - `PATCH /users/profile` (update currency, bio, name, avatar, onboarding)

---

### Phase 3: Transactions Feature (`src/transactions/`)

Matches `TransactionModel` in mobile app (`../app/lib/data/models/transaction_model.dart`).

- [ ] **Data Contracts & Types**:
  - [ ] `transactions.types.ts`: Domain models, pagination query types, balance summary types.
  - [ ] `transactions.dto.ts`: Zod validation schemas:
    - `CreateTransactionSchema` (`title`, `amount`, `type: 'INCOME' | 'EXPENSE'`, `date`, `tag?`, `note?`).
    - `UpdateTransactionSchema` (partial updates).
    - `TransactionQuerySchema` (`page`, `limit`, `type`, `tag`, `startDate`, `endDate`, `search`).
- [ ] **Business Logic (`transactions.service.ts`)**:
  - [ ] `create(userId, dto)`: Atomic creation, increments user's monotonic `syncVersion`.
  - [ ] `findAll(userId, query)`: Filtered, paginated transaction list with metadata.
  - [ ] `findById(userId, id)`: Single transaction lookup with ownership check.
  - [ ] `update(userId, id, dto)`: Updates transaction fields and bumps `version`.
  - [ ] `softDelete(userId, id)`: Sets `isDeleted = true` (tombstone) so mobile sync can purge locally.
  - [ ] `getBalanceSummary(userId)`: Calculates total income, total expense, and net cash balance.
- [ ] **HTTP Layer**:
  - [ ] `transactions.controller.ts`: Delegates to service, returns `ApiResponse`.
  - [ ] `transactions.route.ts`: Protected by `authMiddleware`.
    - `POST /transactions` &rarr; Create transaction.
    - `GET /transactions` &rarr; Paginated & filtered list.
    - `GET /transactions/summary` &rarr; Income, expense, and cash-in-hand balance.
    - `GET /transactions/:id` &rarr; Get single transaction.
    - `PATCH /transactions/:id` &rarr; Update transaction.
    - `DELETE /transactions/:id` &rarr; Soft-delete transaction.
- [ ] **Testing**:
  - [ ] `transactions.test.ts`: 100% unit and integration test coverage.

---

### Phase 4: Debts & Repayments Feature (`src/debts/`)

Matches `DebtModel` & `DebtRepaymentModel` in mobile app (`../app/lib/data/models/debt_model.dart`).

- [ ] **Data Contracts & Types**:
  - [ ] `debts.types.ts`: Debt, Repayment, Direction (`LENT` / `BORROWED`), and Debt Summary interfaces.
  - [ ] `debts.dto.ts`: Zod schemas:
    - `CreateDebtSchema` (`personName`, `title`, `amount`, `date`, `direction: 'LENT' | 'BORROWED'`, `note?`).
    - `AddRepaymentSchema` (`amount`, `date`, `note?`, `affectsCashBalance?`).
    - `DebtQuerySchema` (`direction`, `isSettled`, `personName`, `search`).
- [ ] **Business Logic (`debts.service.ts`)**:
  - [ ] `createDebt(userId, dto)`: Creates debt record.
  - [ ] `getDebts(userId, query)`: Fetches debts including nested repayments, calculates `totalRepaid`, `remainingAmount`, and `isSettled`.
  - [ ] `getDebtById(userId, id)`: Fetches single debt with all repayments.
  - [ ] `addRepayment(userId, debtId, dto)`:
    - Appends repayment in transaction.
    - Automatically marks `isSettled = true` if `remainingAmount <= 0`.
    - Optional: If `affectsCashBalance: true`, automatically creates a balancing `Transaction` entry.
  - [ ] `deleteRepayment(userId, debtId, repaymentId)`: Soft-deletes repayment and recalculates settlement.
  - [ ] `softDeleteDebt(userId, id)`: Soft-deletes debt and all associated repayments.
  - [ ] `getDebtSummary(userId)`: Calculates "They Owe Me" (receivables) vs "I Owe Them" (payables) and net adjusted balance.
- [ ] **HTTP Layer**:
  - [ ] `debts.controller.ts` & `debts.route.ts`:
    - `POST /debts` &rarr; Create debt.
    - `GET /debts` &rarr; List debts with filters (`direction`, `isSettled`).
    - `GET /debts/summary` &rarr; Receivables vs payables summary.
    - `GET /debts/:id` &rarr; Get debt details & repayments.
    - `PATCH /debts/:id` &rarr; Update debt header.
    - `DELETE /debts/:id` &rarr; Soft-delete debt.
    - `POST /debts/:id/repayments` &rarr; Record partial or full repayment.
    - `DELETE /debts/:id/repayments/:repaymentId` &rarr; Remove repayment.
- [ ] **Testing**:
  - [ ] `debts.test.ts`: Settlement calculations and repayment transactions tests.

---

### Phase 5: People / Contact Aggregation (`src/people/`)

Matches `mm_people` contacts and debt breakdown by person in the mobile app.

- [ ] **Service & Route (`src/people/`)**:
  - [ ] `GET /people`: Returns unique list of all persons the user has lent to or borrowed from.
  - [ ] `GET /people/:name/debts`: Returns all active and settled debts specific to that individual.

---

### Phase 6: Analytics & Visualizations (`src/analytics/`)

Powers the mobile dashboard's Period Spending Donut Chart (Week, Month, Year, All) and Category breakdown.

- [ ] **Business Logic (`analytics.service.ts`)**:
  - [ ] `getSpendingByTag(userId, period: 'week' | 'month' | 'year' | 'all')`: Aggregates expense totals grouped by tag/category.
  - [ ] `getCashFlowTrends(userId, period)`: Monthly/Weekly income vs expense breakdown for trend charts.
  - [ ] `getNetWorth(userId)`: Calculates total cash + total receivables - total payables.
- [ ] **Endpoints**:
  - [ ] `GET /analytics/categories?period=month`
  - [ ] `GET /analytics/cash-flow?period=year`
  - [ ] `GET /analytics/net-worth`

---

### Phase 7: Local-First Delta Sync Protocol (`src/sync/`)

Provides seamless synchronization between offline Flutter storage (`shared_preferences`) and the cloud.

- [ ] **Sync Protocol Design**:
  - [ ] `sync.dto.ts`:
    - `SyncPushDto`: Batch of newly created, modified, or soft-deleted transactions, debts, and repayments with client-generated UUIDs.
    - `SyncPullQuery`: `{ lastSyncVersion: number, lastSyncedAt: string }`.
- [ ] **Push Logic (`POST /sync/push`)**:
  - [ ] Applies client changes in a single atomic database transaction.
  - [ ] Upserts client records by ID (handles idempotency so network retries never create duplicates).
  - [ ] Increments user's `syncVersion`.
- [ ] **Pull Logic (`GET /sync/pull`)**:
  - [ ] Returns only records where `version > clientVersion` or `updatedAt > lastSyncedAt`.
  - [ ] Includes tombstoned items (`isDeleted = true`) so client can remove them locally.
- [ ] **Full Cloud Backup & Restore**:
  - [ ] `POST /sync/backup`: Generates a portable encrypted JSON export of user's complete data.
  - [ ] `POST /sync/restore`: Restores user data from backup file.

---

### Phase 8: Production Hardening & High Scale (100k - 1M+ Users)

- [ ] **Redis Caching**:
  - [ ] Cache user profiles (`user:${id}`) in `UsersService.findById`.
  - [ ] Invalidate cache automatically on profile mutation.
  - [ ] Cache monthly spending summaries with TTL.
- [ ] **Rate Limiting**:
  - [ ] Rate-limit auth endpoints (`POST /auth/google`) to prevent abuse (e.g. max 10 req/min per IP).
- [ ] **Database Connection Pooling**:
  - [ ] Configure PgBouncer for production Postgres to cap connections at 100 while serving 20,000 req/s.
- [ ] **Security Headers**:
  - [ ] Add `helmet` or custom security headers (HSTS, CSP, X-Frame-Options).
  - [ ] Add CORS whitelist for trusted web origins.

---

## 🏗️ Step-by-Step Implementation Guide for New Features

Whenever implementing a new feature from this list, follow this strict checklist:

```text
src/<feature>/
├── <feature>.types.ts       # 1. Define domain interfaces & response contracts
├── <feature>.dto.ts         # 2. Define Zod validation schemas
├── <feature>.service.ts     # 3. Pure business logic & database access
├── <feature>.controller.ts  # 4. HTTP handler using ApiResponse
├── <feature>.route.ts       # 5. Wire routes with authMiddleware
└── <feature>.test.ts        # 6. Unit & integration test coverage
```

1. **Create the Feature Folder** under `src/<feature>/`.
2. **Define `<feature>.types.ts` & `<feature>.dto.ts`** first to lock in data structures.
3. **Implement `<feature>.service.ts`**: Keep it decoupled from Express (`req`/`res`); throw `AppError` on failures.
4. **Implement `<feature>.controller.ts`**: Parse inputs with Zod, delegate to service, return via `ApiResponse`.
5. **Attach to Router**: Wire routes in `<feature>.route.ts` and register in `src/app.ts`.
6. **Verify Quality**: Run `bun run format`, `bun run build` (`tsc --noEmit`), and `bun run test`.
