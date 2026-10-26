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

  final StorageService _storageService = StorageService();
  final SyncApiService _syncApiService = SyncApiService();

  final Rx<SyncState> state = SyncState.idle.obs;
  final RxInt pendingCount = 0.obs;
  final RxString lastError = ''.obs;

  bool get isSyncing => state.value == SyncState.syncing;
  bool get hasPending => pendingCount.value > 0;

  @override
  void onInit() {
    super.onInit();

    // Listen to auth changes
    ever(AuthController.to.isAuthenticated, (isAuth) {
      if (isAuth) {
        checkPendingStatus();
        syncPendingItems();
      } else {
        state.value = SyncState.idle;
        pendingCount.value = 0;
      }
    });

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
    if (!AuthController.to.isAuthenticated.value) {
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

  /// Triggers background upload for all unsynced items with full error handling
  Future<void> syncPendingItems({bool showFeedback = false}) async {
    if (!AuthController.to.isAuthenticated.value) {
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
