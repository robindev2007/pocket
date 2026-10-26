import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/sync_controller.dart';

class ItemSyncDot extends StatelessWidget {
  const ItemSyncDot({
    super.key,
    required this.isSynced,
  });

  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>() ||
        !Get.isRegistered<SyncController>()) {
      return const SizedBox.shrink();
    }

    final authController = AuthController.to;
    final syncController = SyncController.to;

    return Obx(() {
      // Only show sync indicators when logged in
      if (!authController.isAuthenticated.value) {
        return const SizedBox.shrink();
      }

      // If already synced, show nothing to keep item layout clean
      if (isSynced) {
        return const SizedBox.shrink();
      }

      // If currently syncing
      if (syncController.isSyncing) {
        return const Padding(
          padding: EdgeInsets.only(left: 6),
          child: SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        );
      }

      // Unsynced state: Clean, super simple yellow dot
      const yellowColor = Color(0xFFEAB308); // Amber-500
      return Tooltip(
        message: 'Pending cloud sync',
        child: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: yellowColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }
}
