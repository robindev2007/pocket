import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/sync_controller.dart';

class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key});

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge> {
  Worker? _syncStateWorker;
  bool _showSyncedConfirmation = false;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _setupWorker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupWorker();
  }

  void _setupWorker() {
    if (_syncStateWorker != null) return;
    if (Get.isRegistered<SyncController>()) {
      _syncStateWorker =
          ever<SyncState>(SyncController.to.state, _handleStateChange);
    }
  }

  void _handleStateChange(SyncState state) {
    if (!mounted) return;
    if (state == SyncState.synced) {
      _fadeTimer?.cancel();
      setState(() => _showSyncedConfirmation = true);
      // Show tick mark and "OK", then fade/animate out after 2.5 seconds
      _fadeTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() => _showSyncedConfirmation = false);
        }
      });
    } else {
      _fadeTimer?.cancel();
      if (_showSyncedConfirmation) {
        setState(() => _showSyncedConfirmation = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _syncStateWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setupWorker();

    if (!Get.isRegistered<AuthController>() ||
        !Get.isRegistered<SyncController>()) {
      return const SizedBox.shrink();
    }

    final authController = AuthController.to;
    final syncController = SyncController.to;
    final isDark = context.isDarkMode;
    final cardBg = context.customColors.cardBackground;
    final cardBorder = context.customColors.cardBorder;

    return Obx(() {
      // Only display sync badge when authenticated
      if (!authController.isAuthenticated.value) {
        return const SizedBox.shrink();
      }

      final isSyncing = syncController.isSyncing;
      final isError = syncController.state.value == SyncState.error;
      final hasPending = syncController.hasPending;
      final pendingCount = syncController.pendingCount.value;

      final bool isVisible =
          isSyncing || isError || hasPending || _showSyncedConfirmation;

      Widget content;
      VoidCallback? onTap;

      if (isSyncing) {
        // 1. Syncing state: Circular progress indicator only, NO text
        content = const SizedBox(
          key: ValueKey('syncing'),
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
        );
      } else if (_showSyncedConfirmation) {
        // 2. Synced state: Tick mark and green "OK"
        const greenLight = Color(0xFF16A34A);
        const greenDark = Color(0xFF4ADE80);
        final greenColor = isDark ? greenDark : greenLight;

        content = Row(
          key: const ValueKey('synced_ok'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: 15,
              color: greenColor,
            ),
            const SizedBox(width: 4),
            Text(
              'OK',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: greenColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      } else if (isError) {
        // 3. Error state: Retry prompt
        final orangeColor =
            isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);

        content = Row(
          key: const ValueKey('error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 13,
              color: orangeColor,
            ),
            const SizedBox(width: 4),
            Text(
              pendingCount == 1 ? '1 • Retry' : '$pendingCount • Retry',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: orangeColor,
              ),
            ),
          ],
        );
        onTap = () => syncController.syncPendingItems(showFeedback: true);
      } else if (hasPending) {
        // 4. Pending items: Yellow dot + count
        const yellowColor = Color(0xFFEAB308);

        content = Row(
          key: const ValueKey('pending'),
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
            const SizedBox(width: 5),
            Text(
              '$pendingCount unsynced',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFFACC15) : const Color(0xFF854D0E),
              ),
            ),
          ],
        );
        onTap = () => syncController.syncPendingItems(showFeedback: true);
      } else {
        content = const SizedBox.shrink(key: ValueKey('empty'));
      }

      final badgeCard = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: content,
              ),
            ),
          ),
        ),
      );

      return AnimatedCrossFade(
        firstChild: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: badgeCard,
        ),
        secondChild: const SizedBox.shrink(),
        crossFadeState: isVisible
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 300),
        sizeCurve: Curves.easeInOut,
        firstCurve: Curves.easeInOut,
        secondCurve: Curves.easeInOut,
      );
    });
  }
}
