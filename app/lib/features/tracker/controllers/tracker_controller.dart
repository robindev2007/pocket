import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/person_debt_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/services/storage_service.dart';
import '../../sync/controllers/sync_controller.dart';

enum TimePeriod {
  week,
  month,
  year,
  all;

  String get displayName {
    switch (this) {
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Month';
      case TimePeriod.year:
        return 'Year';
      case TimePeriod.all:
        return 'All';
    }
  }
}

class TrackerController extends GetxController {
  static TrackerController get to => Get.find<TrackerController>();

  final StorageService _storageService = StorageService();

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<DebtModel> debts = <DebtModel>[].obs;
  final RxList<String> people = <String>[].obs;
  final Rx<UserProfileModel> userProfile = UserProfileModel(name: '').obs;
  final RxBool isLoading = true.obs;

  String get userName => userProfile.value.name;
  String get userAvatar => userProfile.value.avatar;
  String? get userEmail => userProfile.value.email;
  String? get userBio => userProfile.value.bio;
  bool get hasCompletedOnboarding => userProfile.value.hasCompletedOnboarding;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAllData();
    });
  }

  Future<void> loadAllData() async {
    isLoading.value = true;
    try {
      final loadedTransactions = await _storageService.loadTransactions();
      final loadedDebts = await _storageService.loadDebts();
      final loadedPeople = await _storageService.loadPeople();
      final loadedProfile = await _storageService.loadUserProfile();

      transactions.assignAll(loadedTransactions);
      debts.assignAll(loadedDebts);
      people.assignAll(loadedPeople);
      userProfile.value = loadedProfile;

      // If people list is empty, pre-populate with people from existing debts
      for (final debt in debts) {
        if (!people.contains(debt.personName)) {
          people.add(debt.personName);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    required String name,
    String? id,
    String? email,
    String? avatar,
    String? bio,
    String? currency,
    bool? hasCompletedOnboarding,
  }) async {
    final updated = userProfile.value.copyWith(
      id: id ?? userProfile.value.id,
      name: name.trim(),
      email: email?.trim(),
      avatar: avatar ?? userProfile.value.avatar,
      bio: bio?.trim(),
      currency: currency ?? userProfile.value.currency,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? userProfile.value.hasCompletedOnboarding,
    );
    userProfile.value = updated;
    await _storageService.saveUserProfile(updated);
  }

  // --- Financial Computations ---

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get cashBalance => totalIncome - totalExpenses;

  double get totalOwedToMe => debts
      .where((d) => d.isTheyOweMe && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.remainingAmount);

  double get totalIOwe => debts
      .where((d) => d.isIOweThem && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.remainingAmount);

  List<TransactionModel> get sortedTransactions {
    final list = List<TransactionModel>.from(transactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<TransactionModel> get recentTransactions {
    final sorted = sortedTransactions;
    return sorted.take(5).toList();
  }

  List<DebtModel> get outstandingDebts {
    final list = debts.where((d) => !d.isSettled).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<DebtModel> get settledDebts {
    final list = debts.where((d) => d.isSettled).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  bool _isInPeriod(DateTime date, TimePeriod period) {
    if (period == TimePeriod.all) return true;
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return date.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      case TimePeriod.month:
        return date.year == now.year && date.month == now.month;
      case TimePeriod.year:
        return date.year == now.year;
      case TimePeriod.all:
        return true;
    }
  }

  double getTotalExpenseForPeriod(TimePeriod period) {
    return transactions
        .where((t) => t.isExpense && _isInPeriod(t.date, period))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalIncomeForPeriod(TimePeriod period) {
    return transactions
        .where((t) => t.isIncome && _isInPeriod(t.date, period))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getSpendingByTagForPeriod(TimePeriod period) {
    final map = <String, double>{};
    for (final t in transactions.where((t) => t.isExpense && _isInPeriod(t.date, period))) {
      final tag = (t.tag != null && t.tag!.trim().isNotEmpty) ? t.tag! : 'Other';
      map[tag] = (map[tag] ?? 0.0) + t.amount;
    }
    return map;
  }

  Map<String, double> get spendingByTag {
    final map = <String, double>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      final tag = (t.tag != null && t.tag!.trim().isNotEmpty) ? t.tag! : 'General';
      map[tag] = (map[tag] ?? 0.0) + t.amount;
    }
    return map;
  }

  // --- Transaction Actions ---

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? tag,
    String? note,
  }) async {
    final newTransaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      amount: amount,
      type: type,
      date: date,
      tag: tag?.trim().isEmpty ?? true ? null : tag?.trim(),
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      isSynced: false,
    );

    transactions.add(newTransaction);
    await _storageService.saveTransactions(transactions);
    _triggerSync();
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    final index = transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      transactions[index] = updated.copyWith(isSynced: false);
      await _storageService.saveTransactions(transactions);
      _triggerSync();
    }
  }

  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
    await _storageService.saveTransactions(transactions);
  }

  void _triggerSync() {
    if (Get.isRegistered<SyncController>()) {
      SyncController.to.syncPendingItems();
    }
  }

  // --- People Actions & Ledger Aggregations ---

  List<PersonDebtSummary> get peopleSummaries {
    final distinctNames = <String>{};
    for (final p in people) {
      if (p.trim().isNotEmpty) distinctNames.add(p.trim());
    }
    for (final d in debts) {
      if (d.personName.trim().isNotEmpty) distinctNames.add(d.personName.trim());
    }

    final list = distinctNames.map((name) => getPersonSummary(name)).toList();

    // Sort: Active non-zero balances first (highest absolute net balance), then alphabetically
    list.sort((a, b) {
      final aActive = !a.isSettled;
      final bActive = !b.isSettled;
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      if (a.netBalance.abs() != b.netBalance.abs()) {
        return b.netBalance.abs().compareTo(a.netBalance.abs());
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  }

  PersonDebtSummary getPersonSummary(String personName) {
    final trimmed = personName.trim().toLowerCase();
    final personDebts =
        debts.where((d) => d.personName.trim().toLowerCase() == trimmed).toList();

    double theyOweMe = 0.0;
    double iOweThem = 0.0;
    int activeDebts = 0;
    int settledDebts = 0;
    DateTime? lastActivity;

    for (final d in personDebts) {
      if (lastActivity == null || d.date.isAfter(lastActivity)) {
        lastActivity = d.date;
      }
      for (final r in d.repayments) {
        if (lastActivity == null || r.date.isAfter(lastActivity)) {
          lastActivity = r.date;
        }
      }

      if (d.isSettled) {
        settledDebts++;
      } else {
        activeDebts++;
      }

      if (d.isTheyOweMe) {
        theyOweMe += d.remainingAmount;
      } else {
        iOweThem += d.remainingAmount;
      }
    }

    final originalName = people.firstWhereOrNull((p) => p.trim().toLowerCase() == trimmed) ??
        (personDebts.isNotEmpty ? personDebts.first.personName : personName.trim());

    return PersonDebtSummary(
      name: originalName,
      theyOweMe: theyOweMe,
      iOweThem: iOweThem,
      netBalance: theyOweMe - iOweThem,
      activeDebtsCount: activeDebts,
      settledDebtsCount: settledDebts,
      totalDebtsCount: personDebts.length,
      lastActivityDate: lastActivity,
    );
  }

  List<PersonLedgerItem> getPersonLedger(String personName) {
    final trimmed = personName.trim().toLowerCase();
    final personDebts =
        debts.where((d) => d.personName.trim().toLowerCase() == trimmed).toList();

    final items = <PersonLedgerItem>[];

    for (final d in personDebts) {
      items.add(
        PersonLedgerItem(
          id: d.id,
          debtId: d.id,
          type: d.isTheyOweMe ? PersonLedgerType.loanGiven : PersonLedgerType.loanTaken,
          title: d.title,
          amount: d.amount,
          date: d.date,
          note: d.note,
          isSettled: d.isSettled,
          debt: d,
        ),
      );

      for (final r in d.repayments) {
        items.add(
          PersonLedgerItem(
            id: r.id,
            debtId: d.id,
            type: d.isTheyOweMe
                ? PersonLedgerType.repaymentCollected
                : PersonLedgerType.repaymentPaid,
            title: 'Repayment for "${d.title}"',
            amount: r.amount,
            date: r.date,
            note: r.note,
            debt: d,
            repayment: r,
          ),
        );
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> addPerson(String name) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !people.contains(trimmed)) {
      people.add(trimmed);
      await _storageService.savePeople(people);
    }
  }

  Future<void> deletePerson(String name) async {
    final trimmed = name.trim().toLowerCase();
    people.removeWhere((p) => p.trim().toLowerCase() == trimmed);
    await _storageService.savePeople(people);
  }

  Future<void> settleAllDebtsForPerson(String personName) async {
    final trimmed = personName.trim().toLowerCase();
    final activeDebts = debts
        .where((d) => d.personName.trim().toLowerCase() == trimmed && !d.isSettled)
        .toList();

    for (final debt in activeDebts) {
      if (debt.remainingAmount > 0.001) {
        await recordRepayment(
          debtId: debt.id,
          amount: debt.remainingAmount,
          date: DateTime.now(),
          note: 'Full settlement',
        );
      }
    }
  }

  // --- Debt Actions ---

  Future<void> addDebt({
    required String personName,
    required String title,
    required double amount,
    required DateTime date,
    required DebtDirection direction,
    String? note,
  }) async {
    final trimmedPerson = personName.trim();
    if (!people.contains(trimmedPerson)) {
      people.add(trimmedPerson);
      await _storageService.savePeople(people);
    }

    final newDebt = DebtModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      personName: trimmedPerson,
      title: title.trim(),
      amount: amount,
      date: date,
      direction: direction,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      isSynced: false,
    );

    debts.add(newDebt);
    await _storageService.saveDebts(debts);
    _triggerSync();
  }

  Future<void> updateDebt(DebtModel updated) async {
    final index = debts.indexWhere((d) => d.id == updated.id);
    if (index == -1) return;
    debts[index] = updated.copyWith(isSynced: false);
    await _storageService.saveDebts(debts);
    _triggerSync();
  }

  Future<void> deleteDebt(String id) async {
    debts.removeWhere((d) => d.id == id);
    await _storageService.saveDebts(debts);
    _triggerSync();
  }

  Future<void> recordRepayment({
    required String debtId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final index = debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final targetDebt = debts[index];
    final repayment = DebtRepaymentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: date,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      isSynced: false,
    );

    final updatedRepayments = List<DebtRepaymentModel>.from(targetDebt.repayments)..add(repayment);
    debts[index] = targetDebt.copyWith(repayments: updatedRepayments, isSynced: false);
    await _storageService.saveDebts(debts);
    _triggerSync();
  }

  // --- Data Backup / Restore ---

  Future<String> exportBackup() async {
    return _storageService.exportBackupJson();
  }

  Future<bool> importBackup(String jsonStr) async {
    final success = await _storageService.importBackupJson(jsonStr);
    if (success) {
      await loadAllData();
    }
    return success;
  }
}

