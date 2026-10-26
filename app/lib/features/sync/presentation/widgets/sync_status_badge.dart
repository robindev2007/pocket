import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/sync_controller.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>() ||
        !Get.isRegistered<SyncController>()) {
      return const SizedBox.shrink();
    }

    final authController = AuthController.to;
    final syncController = SyncController.to;
    final isDark = context.isDarkMode;

    return Obx(() {
      // Only show when the user is signed in to an account
      if (!authController.isAuthenticated.value) {
        return const SizedBox.shrink();
      }

      final isSyncing = syncController.isSyncing;
      final isError = syncController.state.value == SyncState.error;
      final hasPending = syncController.hasPending;
      final pendingCount = syncController.pendingCount.value;

      // 1. Currently Syncing state (Blue/Primary subtle indicator)
      if (isSyncing) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withValues(alpha: 0.15)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.3)
                      : const Color(0xFFBFDBFE),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Syncing...',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 2. Error / Failed State (Amber/Orange with Retry prompt)
      if (isError) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => syncController.syncPendingItems(showFeedback: true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFEA580C).withValues(alpha: 0.15)
                    : const Color(0xFFFFF7ED), // Orange-50
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFEA580C).withValues(alpha: 0.35)
                      : const Color(0xFFFDBA74), // Orange-300
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFFFB923C)
                        : const Color(0xFFC2410C),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    pendingCount == 1
                        ? '1 unsynced • Retry'
                        : '$pendingCount unsynced • Retry',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFFB923C)
                          : const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 3. Unsynced / Pending State (Clean Yellow/Amber indicator)
      if (hasPending) {
        const yellowColor = Color(0xFFEAB308); // Tailwind Amber-500
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => syncController.syncPendingItems(showFeedback: true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? yellowColor.withValues(alpha: 0.15)
                    : const Color(0xFFFEF9C3), // Tailwind Yellow-100
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? yellowColor.withValues(alpha: 0.3)
                      : const Color(0xFFFDE047),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: yellowColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    pendingCount == 1 ? '1 unsynced' : '$pendingCount unsynced',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFFACC15)
                          : const Color(0xFF854D0E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 4. Fully Synced state (Clean minimal green indicator)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () {
            Get.snackbar(
              'Up to date',
              'All data is safely synchronized with the cloud.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withValues(alpha: 0.9),
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.green.withValues(alpha: 0.12)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Synced',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
