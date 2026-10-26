import { prisma } from '../prisma/prisma.service';
import { AppError } from '../common/errors';
import type { PersonLedgerItem, PersonLedgerResponse, PersonSummary } from './people.types';

export class PeopleService {
  /**
   * Retrieves aggregated summaries of all people the user has debts with.
   */
  async getPeople(userId: string): Promise<PersonSummary[]> {
    const debts = await prisma.debt.findMany({
      where: {
        userId,
        isDeleted: false,
      },
      include: {
        repayments: {
          where: { isDeleted: false },
        },
      },
      orderBy: { date: 'desc' },
    });

    const peopleMap = new Map<
      string,
      {
        displayName: string;
        theyOweMe: number;
        iOweThem: number;
        activeDebtsCount: number;
        settledDebtsCount: number;
        totalDebtsCount: number;
        lastActivityDate: Date | null;
      }
    >();

    for (const debt of debts) {
      const normalizedKey = debt.personName.trim().toLowerCase();
      if (!peopleMap.has(normalizedKey)) {
        peopleMap.set(normalizedKey, {
          displayName: debt.personName.trim(),
          theyOweMe: 0,
          iOweThem: 0,
          activeDebtsCount: 0,
          settledDebtsCount: 0,
          totalDebtsCount: 0,
          lastActivityDate: null,
        });
      }

      const person = peopleMap.get(normalizedKey)!;
      person.totalDebtsCount++;

      // Track latest activity date
      const debtDate = debt.date;
      if (!person.lastActivityDate || debtDate > person.lastActivityDate) {
        person.lastActivityDate = debtDate;
      }

      let totalRepaid = 0;
      for (const rep of debt.repayments) {
        totalRepaid += Number(rep.amount);
        if (!person.lastActivityDate || rep.date > person.lastActivityDate) {
          person.lastActivityDate = rep.date;
        }
      }

      const debtAmount = Number(debt.amount);
      const remaining = Math.max(0, debtAmount - totalRepaid);
      const isSettled = debt.isSettled || remaining <= 0;

      if (isSettled) {
        person.settledDebtsCount++;
      } else {
        person.activeDebtsCount++;
      }

      if (debt.direction === 'LENT') {
        person.theyOweMe += remaining;
      } else {
        person.iOweThem += remaining;
      }
    }

    const summaries: PersonSummary[] = Array.from(peopleMap.values()).map((p) => {
      const theyOweMe = Number(p.theyOweMe.toFixed(2));
      const iOweThem = Number(p.iOweThem.toFixed(2));
      const netBalance = Number((theyOweMe - iOweThem).toFixed(2));

      return {
        name: p.displayName,
        theyOweMe,
        iOweThem,
        netBalance,
        activeDebtsCount: p.activeDebtsCount,
        settledDebtsCount: p.settledDebtsCount,
        totalDebtsCount: p.totalDebtsCount,
        lastActivityDate: p.lastActivityDate ? p.lastActivityDate.toISOString() : null,
      };
    });

    // Sort: active balances first (highest absolute balance), then alphabetically
    return summaries.sort((a, b) => {
      const aHasBalance = Math.abs(a.netBalance) > 0;
      const bHasBalance = Math.abs(b.netBalance) > 0;
      if (aHasBalance && !bHasBalance) return -1;
      if (!aHasBalance && bHasBalance) return 1;
      if (Math.abs(b.netBalance) !== Math.abs(a.netBalance)) {
        return Math.abs(b.netBalance) - Math.abs(a.netBalance);
      }
      return a.name.localeCompare(b.name);
    });
  }

  /**
   * Retrieves the full ledger statement history for a specific person.
   */
  async getPersonLedger(userId: string, personName: string): Promise<PersonLedgerResponse> {
    const trimmedName = personName.trim();
    if (!trimmedName) {
      throw AppError.badRequest('Person name is required');
    }

    const debts = await prisma.debt.findMany({
      where: {
        userId,
        personName: { equals: trimmedName, mode: 'insensitive' },
        isDeleted: false,
      },
      include: {
        repayments: {
          where: { isDeleted: false },
        },
      },
      orderBy: { date: 'desc' },
    });

    if (debts.length === 0) {
      // Check if person exists or return empty zero-balance ledger
      return {
        person: {
          name: trimmedName,
          theyOweMe: 0,
          iOweThem: 0,
          netBalance: 0,
          activeDebtsCount: 0,
          settledDebtsCount: 0,
          totalDebtsCount: 0,
          lastActivityDate: null,
        },
        items: [],
      };
    }

    let theyOweMe = 0;
    let iOweThem = 0;
    let activeDebtsCount = 0;
    let settledDebtsCount = 0;
    let lastActivityDate: Date | null = null;

    const items: PersonLedgerItem[] = [];

    for (const debt of debts) {
      const debtAmount = Number(debt.amount);
      let totalRepaid = 0;

      if (!lastActivityDate || debt.date > lastActivityDate) {
        lastActivityDate = debt.date;
      }

      // Add the debt entry itself
      items.push({
        id: debt.id,
        debtId: debt.id,
        type: debt.direction === 'LENT' ? 'LOAN_GIVEN' : 'LOAN_TAKEN',
        title: debt.title,
        amount: Number(debtAmount.toFixed(2)),
        date: debt.date.toISOString(),
        note: debt.note,
        affectsCashBalance: true,
        isSettled: debt.isSettled,
      });

      // Add each repayment entry
      for (const rep of debt.repayments) {
        const repAmount = Number(rep.amount);
        totalRepaid += repAmount;

        if (!lastActivityDate || rep.date > lastActivityDate) {
          lastActivityDate = rep.date;
        }

        items.push({
          id: rep.id,
          debtId: debt.id,
          type: debt.direction === 'LENT' ? 'REPAYMENT_COLLECTED' : 'REPAYMENT_PAID',
          title: `Repayment: ${debt.title}`,
          amount: Number(repAmount.toFixed(2)),
          date: rep.date.toISOString(),
          note: rep.note,
          affectsCashBalance: rep.affectsCashBalance,
        });
      }

      const remaining = Math.max(0, debtAmount - totalRepaid);
      const isSettled = debt.isSettled || remaining <= 0;

      if (isSettled) {
        settledDebtsCount++;
      } else {
        activeDebtsCount++;
      }

      if (debt.direction === 'LENT') {
        theyOweMe += remaining;
      } else {
        iOweThem += remaining;
      }
    }

    // Sort items chronologically descending (newest first)
    items.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    const finalTheyOweMe = Number(theyOweMe.toFixed(2));
    const finalIOweThem = Number(iOweThem.toFixed(2));
    const netBalance = Number((finalTheyOweMe - finalIOweThem).toFixed(2));

    return {
      person: {
        name: debts[0]?.personName ?? trimmedName, // Preserve original casing
        theyOweMe: finalTheyOweMe,
        iOweThem: finalIOweThem,
        netBalance,
        activeDebtsCount,
        settledDebtsCount,
        totalDebtsCount: debts.length,
        lastActivityDate: lastActivityDate ? lastActivityDate.toISOString() : null,
      },
      items,
    };
  }
}
