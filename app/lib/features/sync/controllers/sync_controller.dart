import 'dart:async';
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
  final Rx<DateTime?> lastSyncedAt = Rx<DateTime?>(null);
  Timer? _reconnectTimer;

  bool get isSyncing => state.value == SyncState.syncing;
  bool get hasPending => pendingCount.value > 0;

  @override
  void onInit() {
    super.onInit();
    _storageService.loadLastSyncedAt().then((val) => lastSyncedAt.value = val);

    // Auto-sync pending items when network is restored
    if (!Get.testMode) {
      _reconnectTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (hasPending &&
            !isSyncing &&
            Get.isRegistered<AuthController>() &&
            AuthController.to.isAuthenticated.value) {
          syncPendingItems();
        }
      });
    }

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

  @override
  void onClose() {
    _reconnectTimer?.cancel();
    super.onClose();
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
    final unsyncedRepayments = tracker.debts
        .fold(0, (sum, d) => sum + d.repayments.where((r) => !r.isSynced).length);
    final total = unsyncedTx + unsyncedDebts + unsyncedRepayments;

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
      final now = DateTime.now();
      lastSyncedAt.value = now;
      await _storageService.saveLastSyncedAt(now);

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
          final serverId = await _syncApiService.uploadTransaction(tx, token);
          if (serverId != null) {
            syncedTxCount++;
            updatedTxList.add(tx.copyWith(id: serverId, isSynced: true));
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

      // 2. Sync pending debts and repayments
      final updatedDebtList = <DebtModel>[];
      for (final debt in tracker.debts) {
        var currentDebt = debt;
        if (!currentDebt.isSynced) {
          final serverId = await _syncApiService.uploadDebt(currentDebt, token);
          if (serverId != null) {
            syncedDebtCount++;
            currentDebt = currentDebt.copyWith(id: serverId, isSynced: true);
          } else {
            anyFailure = true;
          }
        }

        // Sync pending repayments if debt is synced
        if (currentDebt.isSynced && currentDebt.repayments.any((r) => !r.isSynced)) {
          final updatedRepayments = <DebtRepaymentModel>[];
          for (final rep in currentDebt.repayments) {
            if (!rep.isSynced) {
              final repSuccess = await _syncApiService.uploadRepayment(
                currentDebt.id,
                rep,
                token,
              );
              if (repSuccess) {
                updatedRepayments.add(rep.copyWith(isSynced: true));
              } else {
                anyFailure = true;
                updatedRepayments.add(rep);
              }
            } else {
              updatedRepayments.add(rep);
            }
          }
          currentDebt = currentDebt.copyWith(repayments: updatedRepayments);
        }

        updatedDebtList.add(currentDebt);
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
      final remainingRep = tracker.debts
          .fold(0, (sum, d) => sum + d.repayments.where((r) => !r.isSynced).length);
      final remainingTotal = remainingTx + remainingDebts + remainingRep;

      pendingCount.value = remainingTotal;

      if (remainingTotal == 0) {
        state.value = SyncState.synced;
        final now = DateTime.now();
        lastSyncedAt.value = now;
        await _storageService.saveLastSyncedAt(now);
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
