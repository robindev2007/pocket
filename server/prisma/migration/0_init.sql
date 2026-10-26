-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('INCOME', 'EXPENSE', 'TRANSFER');

-- CreateEnum
CREATE TYPE "DebtDirection" AS ENUM ('LENT', 'BORROWED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "googleId" TEXT,
    "email" TEXT,
    "name" TEXT NOT NULL,
    "avatar" TEXT,
    "bio" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "hasCompletedOnboarding" BOOLEAN NOT NULL DEFAULT false,
    "syncVersion" BIGINT NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Transaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" VARCHAR(150) NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "type" "TransactionType" NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "tag" VARCHAR(50),
    "note" VARCHAR(500),
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "version" BIGINT NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Debt" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "personName" VARCHAR(120) NOT NULL,
    "title" VARCHAR(150) NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "direction" "DebtDirection" NOT NULL,
    "isSettled" BOOLEAN NOT NULL DEFAULT false,
    "note" VARCHAR(500),
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "version" BIGINT NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Debt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Repayment" (
    "id" TEXT NOT NULL,
    "debtId" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "note" VARCHAR(500),
    "affectsCashBalance" BOOLEAN NOT NULL DEFAULT true,
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "version" BIGINT NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Repayment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_googleId_key" ON "User"("googleId");
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "Transaction_userId_isDeleted_date_idx" ON "Transaction"("userId", "isDeleted", "date" DESC);
CREATE INDEX "Transaction_userId_updatedAt_idx" ON "Transaction"("userId", "updatedAt" ASC);

-- CreateIndex
CREATE INDEX "Debt_userId_isDeleted_isSettled_idx" ON "Debt"("userId", "isDeleted", "isSettled");
CREATE INDEX "Debt_userId_updatedAt_idx" ON "Debt"("userId", "updatedAt" ASC);

-- CreateIndex
CREATE INDEX "Repayment_debtId_isDeleted_idx" ON "Repayment"("debtId", "isDeleted");
CREATE INDEX "Repayment_debtId_updatedAt_idx" ON "Repayment"("debtId", "updatedAt" ASC);

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Debt" ADD CONSTRAINT "Debt_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Repayment" ADD CONSTRAINT "Repayment_debtId_fkey" FOREIGN KEY ("debtId") REFERENCES "Debt"("id") ON DELETE CASCADE ON UPDATE CASCADE;
