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
}

class SyncController extends GetxController {
  static SyncController get to => Get.find<SyncController>();

  final StorageService _storageService = StorageService();
  final SyncApiService _syncApiService = SyncApiService();

  final Rx<SyncState> state = SyncState.idle.obs;
  final RxInt pendingCount = 0.obs;

  bool get isSyncing => state.value == SyncState.syncing;
  bool get hasPending => pendingCount.value > 0;

  @override
  void onInit() {
    super.onInit();

    // Listen to changes in auth or items to re-evaluate sync status
    ever(AuthController.to.isAuthenticated, (isAuth) {
      if (isAuth) {
        checkPendingStatus();
        syncPendingItems();
      } else {
        state.value = SyncState.idle;
        pendingCount.value = 0;
      }
    });

    if (Get.isRegistered<TrackerController>()) {
      ever(TrackerController.to.transactions, (_) => checkPendingStatus());
      ever(TrackerController.to.debts, (_) => checkPendingStatus());
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

  /// Triggers background upload for all unsynced items
  Future<void> syncPendingItems() async {
    if (!AuthController.to.isAuthenticated.value) return;
    if (isSyncing) return;

    final token = await _storageService.loadAuthToken();
    if (token == null || token.isEmpty) return;

    final tracker = TrackerController.to;
    state.value = SyncState.syncing;

    try {
      // 1. Sync pending transactions
      final updatedTxList = <TransactionModel>[];
      for (final tx in tracker.transactions) {
        if (!tx.isSynced) {
          final success = await _syncApiService.uploadTransaction(tx, token);
          if (success) {
            updatedTxList.add(tx.copyWith(isSynced: true));
          } else {
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
            updatedDebtList.add(debt.copyWith(isSynced: true));
          } else {
            updatedDebtList.add(debt);
          }
        } else {
          updatedDebtList.add(debt);
        }
      }
      tracker.debts.assignAll(updatedDebtList);
      await _storageService.saveDebts(updatedDebtList);
    } finally {
      checkPendingStatus();
    }
  }
}
