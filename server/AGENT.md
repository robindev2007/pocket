# Agent Guidelines — Architecture & Coding Standards

This document establishes the architecture, folder structure conventions, and coding guidelines for this backend codebase. Any AI agent or developer working on this project must adhere strictly to these rules.

---

## 1. Core Architecture: Feature-Based (Vertical Slice)

All application code must follow a **feature-first / vertical-slice** folder structure under `src/`. Code is organized by domain concept (e.g., `auth`, `transactions`, `debts`, `users`, `sync`), not by technical layer.

> **Never** group files into generic global folders like `src/controllers/`, `src/services/`, or `src/routes/`. Keep each feature completely self-contained.

### Canonical Folder Structure

```text
server/
├── prisma/                          # Prisma schema and contract definitions
│   └── contract.prisma
├── src/
│   ├── auth/                        # Example Feature: Authentication
│   │   ├── auth.controller.ts       # Handles HTTP requests, responses, status codes
│   │   ├── auth.service.ts          # Core business logic & database queries
│   │   ├── auth.route.ts            # Route definitions & middleware binding
│   │   ├── auth.dto.ts              # Input schemas, validation, types
│   │   └── auth.test.ts             # Feature-specific tests
│   │
│   ├── users/                       # User Profiles & Accounts
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.route.ts
│   │   └── users.dto.ts
│   │
│   ├── transactions/                # Incomes & Expenses Cash Flow
│   │   ├── transactions.controller.ts
│   │   ├── transactions.service.ts
│   │   ├── transactions.route.ts
│   │   └── transactions.dto.ts
│   │
│   ├── debts/                       # Lending, Borrowing & Repayments
│   │   ├── debts.controller.ts
│   │   ├── debts.service.ts
│   │   ├── debts.route.ts
│   │   └── debts.dto.ts
│   │
│   ├── sync/                        # Local-First Delta Sync Protocol (Push & Pull)
│   │   ├── sync.controller.ts
│   │   ├── sync.service.ts
│   │   ├── sync.route.ts
│   │   └── sync.dto.ts
│   │
│   ├── prisma/                      # Database client runtime
│   │   ├── db.ts                    # DB connection instance
│   │   └── prisma.service.ts        # Database access helper
│   │
│   ├── common/                      # Shared cross-cutting concerns only
│   │   ├── middlewares/             # Auth guards, logging, rate limiting
│   │   ├── errors/                  # Custom application errors & handlers
│   │   └── utils/                   # Reusable helpers & formatters
│   │
│   └── index.ts                     # Server bootstrap & main application entry
├── .env.example
├── bun.lock
├── package.json
└── tsconfig.json
```

---

## 2. File Naming Conventions

Every file inside a feature folder must use kebab-case or dot-notation prefixed with the feature name:

| Role           | File Name Pattern         | Purpose                                                                                |
| :------------- | :------------------------ | :------------------------------------------------------------------------------------- |
| **Route**      | `<feature>.route.ts`      | Declares URL paths, HTTP methods (`GET`, `POST`, etc.), and wires controller handlers. |
| **Controller** | `<feature>.controller.ts` | Parses request parameters/body, calls the service, and returns JSON responses.         |
| **Service**    | `<feature>.service.ts`    | Contains business logic, validation rules, and database queries.                       |
| **DTO**        | `<feature>.dto.ts`        | Runtime validation schemas (Zod).                                                      |
| **Types**      | `<feature>.types.ts`      | Central domain models, interface contracts, and response types for the feature.        |
| **Tests**      | `<feature>.test.ts`       | Unit and integration tests for this feature.                                           |

---

## 3. Layer Responsibilities & Separation of Concerns

1. **Routes (`*.route.ts`)**:
   - Bind HTTP routes to controller methods.
   - Attach route-level middleware (e.g., authentication guards, request validators).
   - Do **not** contain request handling logic or database queries.

2. **Controllers (`*.controller.ts`)**:
   - Extract data from `req.body`, `req.params`, `req.query`, and auth context (`req.user`).
   - Delegate the actual work to the respective service method.
   - Return appropriate HTTP status codes (`200 OK`, `201 Created`, `400 Bad Request`, `404 Not Found`).
   - Do **not** query the database directly.

3. **Services (`*.service.ts`)**:
   - Pure business logic.
   - Interact with the database (via Prisma or repository layer).
   - Throw structured domain errors (which are mapped to HTTP responses by controllers or error middleware).
   - Avoid coupling to HTTP objects (`req`, `res`).

---

## 4. Engineering Standards & Runtime

- **Runtime**: Bun (`bun run`, `bun test`). Prefer Bun native APIs and fast TypeScript execution.
- **Data Integrity (Local-First Friendly)**:
  - Every syncable entity must include:
    - `id`: Client-generated `UUID` (string).
    - `updatedAt`: ISO timestamp for Last-Write-Wins (LWW) conflict resolution.
    - `isDeleted`: Boolean tombstone flag for reliable synchronization.
- **Code Cleanliness**:
  - Keep functions focused and concise.
  - Avoid duplicate logic; extract shared utilities to `src/common/`.
  - Strive for high testability with co-located `*.test.ts` files.
