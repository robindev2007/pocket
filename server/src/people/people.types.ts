export interface PersonSummary {
  name: string;
  theyOweMe: number;
  iOweThem: number;
  netBalance: number;
  activeDebtsCount: number;
  settledDebtsCount: number;
  totalDebtsCount: number;
  lastActivityDate: string | null;
}

export type LedgerItemType =
  | 'LOAN_GIVEN'       // User lent money (LENT debt created)
  | 'LOAN_TAKEN'       // User borrowed money (BORROWED debt created)
  | 'REPAYMENT_COLLECTED' // Repayment received on a LENT debt
  | 'REPAYMENT_PAID';     // Repayment made on a BORROWED debt

export interface PersonLedgerItem {
  id: string;
  debtId: string;
  type: LedgerItemType;
  title: string;
  amount: number;
  date: string;
  note: string | null;
  affectsCashBalance: boolean;
  isSettled?: boolean;
}

export interface PersonLedgerResponse {
  person: PersonSummary;
  items: PersonLedgerItem[];
}
