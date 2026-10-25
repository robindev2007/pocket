import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt_model.dart';
import '../models/transaction_model.dart';
import '../models/user_profile_model.dart';

class StorageService {
  static const String _keyTransactions = 'mm_transactions';
  static const String _keyDebts = 'mm_debts';
  static const String _keyPeople = 'mm_people';
  static const String _keyUserProfile = 'mm_user_profile';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    try {
      await _prefs?.reload();
    } catch (_) {}
  }

  // --- Transactions ---
  Future<List<TransactionModel>> loadTransactions() async {
    await init();
    final jsonStr = _prefs?.getString(_keyTransactions);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    await init();
    final jsonStr = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await _prefs?.setString(_keyTransactions, jsonStr);
  }

  // --- Debts ---
  Future<List<DebtModel>> loadDebts() async {
    await init();
    final jsonStr = _prefs?.getString(_keyDebts);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => DebtModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDebts(List<DebtModel> debts) async {
    await init();
    final jsonStr = jsonEncode(debts.map((d) => d.toJson()).toList());
    await _prefs?.setString(_keyDebts, jsonStr);
  }

  // --- People ---
  Future<List<String>> loadPeople() async {
    await init();
    final list = _prefs?.getStringList(_keyPeople);
    return list ?? [];
  }

  Future<void> savePeople(List<String> people) async {
    await init();
    await _prefs?.setStringList(_keyPeople, people);
  }

  // --- User Profile ---
  Future<UserProfileModel> loadUserProfile() async {
    await init();
    final jsonStr = _prefs?.getString(_keyUserProfile);
    if (jsonStr == null || jsonStr.isEmpty) {
      return UserProfileModel(name: '');
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfileModel.fromJson(map);
    } catch (_) {
      return UserProfileModel(name: '');
    }
  }

  Future<void> saveUserProfile(UserProfileModel profile) async {
    await init();
    final jsonStr = jsonEncode(profile.toJson());
    await _prefs?.setString(_keyUserProfile, jsonStr);
  }

  // --- Backup & Restore (JSON) ---
  Future<String> exportBackupJson() async {
    final transactions = await loadTransactions();
    final debts = await loadDebts();
    final people = await loadPeople();
    final profile = await loadUserProfile();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'debts': debts.map((d) => d.toJson()).toList(),
      'people': people,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> data =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['profile'] != null) {
        final profile = UserProfileModel.fromJson(
            data['profile'] as Map<String, dynamic>);
        await saveUserProfile(profile);
      }

      final transactionsList = (data['transactions'] as List<dynamic>?)
              ?.map((item) =>
                  TransactionModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      final debtsList = (data['debts'] as List<dynamic>?)
              ?.map((item) => DebtModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      final peopleList = (data['people'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      await saveTransactions(transactionsList);
      await saveDebts(debtsList);
      await savePeople(peopleList);
      return true;
    } catch (_) {
      return false;
    }
  }
}
