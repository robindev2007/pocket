import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/services/storage_service.dart';

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
    loadAllData();
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
    String? email,
    String? avatar,
    String? bio,
    bool? hasCompletedOnboarding,
  }) async {
    final updated = userProfile.value.copyWith(
      name: name.trim(),
      email: email?.trim(),
      avatar: avatar ?? userProfile.value.avatar,
      bio: bio?.trim(),
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

  /// Calculation: Cash balance + money owed to me - money I owe others
  double get adjustedBalance => cashBalance + totalOwedToMe - totalIOwe;

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
    );

    transactions.add(newTransaction);
    await _storageService.saveTransactions(transactions);
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    final index = transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      transactions[index] = updated;
      await _storageService.saveTransactions(transactions);
    }
  }

  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
    await _storageService.saveTransactions(transactions);
  }

  // --- People Actions ---

  Future<void> addPerson(String name) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !people.contains(trimmed)) {
      people.add(trimmed);
      await _storageService.savePeople(people);
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
    );

    debts.add(newDebt);
    await _storageService.saveDebts(debts);
  }

  Future<void> recordRepayment({
    required String debtId,
    required double amount,
    required DateTime date,
    String? note,
    bool affectsCashBalance = true,
  }) async {
    final index = debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final targetDebt = debts[index];
    final repayment = DebtRepaymentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: date,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      affectsCashBalance: affectsCashBalance,
    );

    final updatedRepayments = List<DebtRepaymentModel>.from(targetDebt.repayments)..add(repayment);
    final updatedDebt = targetDebt.copyWith(repayments: updatedRepayments);
    debts[index] = updatedDebt;
    await _storageService.saveDebts(debts);

    // If repayment was in cash, record corresponding cash transaction
    if (affectsCashBalance) {
      if (targetDebt.isTheyOweMe) {
        // Someone paid me cash -> Cash Balance increases (Income)
        await addTransaction(
          title: 'Repayment from ${targetDebt.personName}',
          amount: amount,
          type: TransactionType.income,
          date: date,
          tag: 'Debt Repayment',
          note: 'Repayment for "${targetDebt.title}"',
        );
      } else {
        // I paid someone cash -> Cash Balance decreases (Expense)
        await addTransaction(
          title: 'Repayment to ${targetDebt.personName}',
          amount: amount,
          type: TransactionType.expense,
          date: date,
          tag: 'Debt Repayment',
          note: 'Repayment for "${targetDebt.title}"',
        );
      }
    }
  }

  Future<void> deleteDebt(String id) async {
    debts.removeWhere((d) => d.id == id);
    await _storageService.saveDebts(debts);
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

