import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/borderless_card.dart';
import '../../../tracker/controllers/tracker_controller.dart';
import '../../controllers/auth_controller.dart';

class GoogleAuthCard extends StatelessWidget {
  const GoogleAuthCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final authController = AuthController.to;

    return Obx(() {
      final isLoggedIn = authController.isAuthenticated.value;
      final isLoading = authController.isLoading.value;
      final user = authController.authUser.value;
      final currentEmail = user?.email ?? TrackerController.to.userEmail;

      if (isLoggedIn) {
        return BorderlessCard(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  AppSizes.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Account Connected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (currentEmail != null && currentEmail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            currentEmail,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: customColors.subtleText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
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
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSizes.gapH12,
              Text(
                'Your account is linked. Changes can sync seamlessly with the cloud.',
                style: TextStyle(
                  fontSize: 12,
                  color: customColors.subtleText,
                ),
              ),
              AppSizes.gapH16,
              AppButton.outline(
                text: 'Sign Out of Google',
                prefixIcon: const Icon(Icons.logout_rounded, size: 16),
                isFullWidth: true,
                size: ButtonSize.sm,
                isLoading: isLoading,
                onPressed: () => _confirmSignOut(context, authController),
              ),
            ],
          ),
        );
      }

      // Unauthenticated state: Create Account or Login with Google
      return BorderlessCard(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                AppSizes.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Sync & Backup',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create an account or login',
                        style: TextStyle(
                          fontSize: 12,
                          color: customColors.subtleText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSizes.gapH12,
            Text(
              'Sign in with your Google account to back up expenses, sync debts, and access your finances across devices.',
              style: TextStyle(
                fontSize: 12.5,
                color: customColors.subtleText,
                height: 1.35,
              ),
            ),
            AppSizes.gapH16,
            AppButton.primary(
              text: 'Continue with Google',
              prefixIcon: const Icon(Icons.login_rounded, size: 16),
              isFullWidth: true,
              size: ButtonSize.md,
              isLoading: isLoading,
              onPressed: () => authController.signInWithGoogle(),
            ),
          ],
        ),
      );
    });
  }

  void _confirmSignOut(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out from your Google account? Your local data will remain saved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              authController.signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
