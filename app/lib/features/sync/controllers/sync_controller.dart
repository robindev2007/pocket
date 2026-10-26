import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/sync_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../tracker/controllers/tracker_controller.dart';

enum SyncState {
  idle,
  pending,
  syncing,
  synced,
  error,
}

class SyncController extends GetxController {
  static SyncController get to => Get.find<SyncController>();

  final StorageService _storageService;
  final SyncApiService _syncApiService;

  SyncController({
    StorageService? storageService,
    SyncApiService? syncApiService,
  })  : _storageService = storageService ?? StorageService(),
        _syncApiService = syncApiService ?? SyncApiService();

  final Rx<SyncState> state = SyncState.idle.obs;
  final RxInt pendingCount = 0.obs;
  final RxString lastError = ''.obs;

  bool get isSyncing => state.value == SyncState.syncing;
  bool get hasPending => pendingCount.value > 0;

  @override
  void onInit() {
    super.onInit();

    // Listen to auth changes
    if (Get.isRegistered<AuthController>()) {
      ever(AuthController.to.isAuthenticated, (isAuth) {
        if (isAuth) {
          checkPendingStatus();
          syncPendingItems();
        } else {
          state.value = SyncState.idle;
          pendingCount.value = 0;
        }
      });
    }

    // Listen to changes in transactions or debts
    if (Get.isRegistered<TrackerController>()) {
      ever(TrackerController.to.transactions, (_) {
        if (!isSyncing) checkPendingStatus();
      });
      ever(TrackerController.to.debts, (_) {
        if (!isSyncing) checkPendingStatus();
      });
    }

    checkPendingStatus();
  }

  void checkPendingStatus() {
    if (!Get.isRegistered<AuthController>() ||
        !AuthController.to.isAuthenticated.value) {
      state.value = SyncState.idle;
      pendingCount.value = 0;
      return;
    }

    if (!Get.isRegistered<TrackerController>()) return;

    final tracker = TrackerController.to;
    final unsyncedTx = tracker.transactions.where((t) => !t.isSynced).length;
    final unsyncedDebts = tracker.debts.where((d) => !d.isSynced).length;
    final total = unsyncedTx + unsyncedDebts;

    pendingCount.value = total;

    if (state.value != SyncState.syncing) {
      state.value = total > 0 ? SyncState.pending : SyncState.synced;
    }
  }

  /// Pulls the newest transactions and debts from the cloud and merges them with local state.
  /// Any offline items created locally (!isSynced) are preserved and pushed up.
  Future<bool> hydrateFromServer(String token) async {
    if (isSyncing) return false;

    state.value = SyncState.syncing;
    lastError.value = '';

    try {
      final data = await _syncApiService.pullRemoteData(token);
      if (data == null) {
        state.value = SyncState.error;
        return false;
      }

      if (!Get.isRegistered<TrackerController>()) return false;
      final tracker = TrackerController.to;

      // 1. Parse remote transactions
      final remoteTxList = <TransactionModel>[];
      if (data['transactions'] is List) {
        for (final item in data['transactions']) {
          try {
            remoteTxList.add(
              TransactionModel.fromJson(item as Map<String, dynamic>)
                  .copyWith(isSynced: true),
            );
          } catch (_) {}
        }
      }

      // 2. Parse remote debts
      final remoteDebtList = <DebtModel>[];
      if (data['debts'] is List) {
        for (final item in data['debts']) {
          try {
            remoteDebtList.add(
              DebtModel.fromJson(item as Map<String, dynamic>)
                  .copyWith(isSynced: true),
            );
          } catch (_) {}
        }
      }

      // 3. Merge Transactions: cloud items + local offline items
      final mergedTxMap = <String, TransactionModel>{};
      for (final tx in remoteTxList) {
        mergedTxMap[tx.id] = tx;
      }
      for (final local in tracker.transactions) {
        if (!local.isSynced && !mergedTxMap.containsKey(local.id)) {
          mergedTxMap[local.id] = local;
        }
      }
      final mergedTx = mergedTxMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // 4. Merge Debts: cloud items + local offline items
      final mergedDebtMap = <String, DebtModel>{};
      for (final debt in remoteDebtList) {
        mergedDebtMap[debt.id] = debt;
      }
      for (final local in tracker.debts) {
        if (!local.isSynced && !mergedDebtMap.containsKey(local.id)) {
          mergedDebtMap[local.id] = local;
        }
      }
      final mergedDebts = mergedDebtMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // 5. Update TrackerController & persist to storage
      tracker.transactions.assignAll(mergedTx);
      tracker.debts.assignAll(mergedDebts);
      await _storageService.saveTransactions(mergedTx);
      await _storageService.saveDebts(mergedDebts);

      // 6. Update People list from all merged debts
      final peopleSet = <String>{...tracker.people};
      for (final d in mergedDebts) {
        if (d.personName.trim().isNotEmpty) {
          peopleSet.add(d.personName.trim());
        }
      }
      tracker.people.assignAll(peopleSet.toList());
      await _storageService.savePeople(tracker.people);

      state.value = SyncState.synced;

      // 7. Push any remaining offline creations to the server
      await syncPendingItems();
      return true;
    } catch (e) {
      lastError.value = e.toString();
      state.value = SyncState.error;
      return false;
    } finally {
      checkPendingStatus();
    }
  }

  /// Triggers background upload for all unsynced items with full error handling
  Future<void> syncPendingItems({bool showFeedback = false}) async {
    if (!Get.isRegistered<AuthController>() ||
        !AuthController.to.isAuthenticated.value) {
      state.value = SyncState.idle;
      return;
    }

    if (isSyncing) return;

    final token = await _storageService.loadAuthToken();
    if (token == null || token.isEmpty) {
      state.value = SyncState.idle;
      return;
    }

    final tracker = TrackerController.to;
    state.value = SyncState.syncing;
    lastError.value = '';

    bool anyFailure = false;
    int syncedTxCount = 0;
    int syncedDebtCount = 0;

    try {
      // 1. Sync pending transactions
      final updatedTxList = <TransactionModel>[];
      for (final tx in tracker.transactions) {
        if (!tx.isSynced) {
          final success = await _syncApiService.uploadTransaction(tx, token);
          if (success) {
            syncedTxCount++;
            updatedTxList.add(tx.copyWith(isSynced: true));
          } else {
            anyFailure = true;
            updatedTxList.add(tx);
          }
        } else {
          updatedTxList.add(tx);
        }
      }
      tracker.transactions.assignAll(updatedTxList);
      await _storageService.saveTransactions(updatedTxList);

      // 2. Sync pending debts
      final updatedDebtList = <DebtModel>[];
      for (final debt in tracker.debts) {
        if (!debt.isSynced) {
          final serverId = await _syncApiService.uploadDebt(debt, token);
          if (serverId != null) {
            syncedDebtCount++;
            updatedDebtList.add(debt.copyWith(isSynced: true));
          } else {
            anyFailure = true;
            updatedDebtList.add(debt);
          }
        } else {
          updatedDebtList.add(debt);
        }
      }
      tracker.debts.assignAll(updatedDebtList);
      await _storageService.saveDebts(updatedDebtList);
    } catch (e) {
      anyFailure = true;
      lastError.value = e.toString();
    } finally {
      // Re-evaluate pending count
      final remainingTx = tracker.transactions.where((t) => !t.isSynced).length;
      final remainingDebts = tracker.debts.where((d) => !d.isSynced).length;
      final remainingTotal = remainingTx + remainingDebts;

      pendingCount.value = remainingTotal;

      if (remainingTotal == 0) {
        state.value = SyncState.synced;
        if (showFeedback && (syncedTxCount > 0 || syncedDebtCount > 0)) {
          Get.snackbar(
            'Synced',
            'All items are successfully synced with the cloud.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
          );
        }
      } else if (anyFailure) {
        state.value = SyncState.error;
        if (showFeedback) {
          Get.snackbar(
            'Sync Incomplete',
            'Could not reach server. $remainingTotal item(s) remain safely saved on device.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
          );
        }
      } else {
        state.value = SyncState.pending;
      }
    }
  }
}
