import 'debt_model.dart';

class PersonDebtSummary {
  final String name;
  final double theyOweMe;
  final double iOweThem;
  final double netBalance;
  final int activeDebtsCount;
  final int settledDebtsCount;
  final int totalDebtsCount;
  final DateTime? lastActivityDate;

  const PersonDebtSummary({
    required this.name,
    required this.theyOweMe,
    required this.iOweThem,
    required this.netBalance,
    required this.activeDebtsCount,
    required this.settledDebtsCount,
    required this.totalDebtsCount,
    this.lastActivityDate,
  });

  bool get isSettled => netBalance.abs() < 0.01;
  bool get theyOweUser => netBalance > 0.009;
  bool get userOwesThem => netBalance < -0.009;
}

enum PersonLedgerType {
  loanGiven,          // User gave money (they owe user)
  loanTaken,          // User took money (user owes them)
  repaymentCollected, // Repayment received from them
  repaymentPaid,      // Repayment paid to them
}

class PersonLedgerItem {
  final String id;
  final String debtId;
  final PersonLedgerType type;
  final String title;
  final double amount;
  final DateTime date;
  final String? note;
  final bool isSettled;
  final DebtModel? debt;
  final DebtRepaymentModel? repayment;

  const PersonLedgerItem({
    required this.id,
    required this.debtId,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.note,
    this.isSettled = false,
    this.debt,
    this.repayment,
  });
}
