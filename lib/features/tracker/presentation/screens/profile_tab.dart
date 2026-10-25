import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/backup_restore_dialog.dart';
import '../dialogs/edit_profile_dialog.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController.to;
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final themeController = ThemeController.to;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final profile = controller.userProfile.value;
        final name = profile.name.isNotEmpty ? profile.name : 'User';
        final avatar = profile.avatar.isNotEmpty ? profile.avatar : '👤';
        final email = profile.email;
        final bio = profile.bio;
        final spendingByTag = controller.spendingByTag;
        final totalExpenses = controller.totalExpenses;

        return ScreenContainer(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. USER PROFILE HERO CARD
              BorderlessCard(
                padding: const EdgeInsets.all(AppSizes.p20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            avatar,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        AppSizes.gapW16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (email != null && email.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: customColors.subtleText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (bio != null && bio.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  bio,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: customColors.subtleText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSizes.gapH16,
                    const Divider(height: 1),
                    AppSizes.gapH12,
                    AppButton.outline(
                      text: 'Edit Profile & Avatar',
                      prefixIcon: const Icon(Icons.edit_outlined, size: 16),
                      isFullWidth: true,
                      size: ButtonSize.sm,
                      onPressed: () => EditProfileDialog.show(context),
                    ),
                  ],
                ),
              ),
              AppSizes.gapH24,

              // 2. QUICK ACTIVITY STATS
              Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSizes.gapH12,
              Row(
                children: [
                  Expanded(
                    child: BorderlessCard(
                      padding: const EdgeInsets.all(AppSizes.p14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transactions',
                            style: TextStyle(fontSize: 12, color: customColors.subtleText),
                          ),
                          AppSizes.gapH4,
                          Text(
                            '${controller.transactions.length}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSizes.gapW12,
                  Expanded(
                    child: BorderlessCard(
                      padding: const EdgeInsets.all(AppSizes.p14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Debts',
                            style: TextStyle(fontSize: 12, color: customColors.subtleText),
                          ),
                          AppSizes.gapH4,
                          Text(
                            '${controller.outstandingDebts.length}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AppSizes.gapH24,

              // 3. SPENDING BREAKDOWN
              if (spendingByTag.isNotEmpty) ...[
                Text(
                  'Spending by Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                AppSizes.gapH12,
                BorderlessCard(
                  child: Column(
                    children: spendingByTag.entries.map((entry) {
                      final percentage = totalExpenses > 0 ? (entry.value / totalExpenses) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${CurrencyFormatter.format(entry.value)} (${(percentage * 100).toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: customColors.subtleText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 5,
                                backgroundColor: customColors.surfaceHover,
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSizes.gapH24,
              ],

              // 4. THEME & PALETTE SETTINGS
              Text(
                'Theme & Appearance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSizes.gapH12,
              BorderlessCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.isDarkMode ? 'Dark Mode Active' : 'Light Mode Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: customColors.subtleText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AppFilterPill(
                          label: 'Light',
                          isSelected: !context.isDarkMode,
                          onTap: () => themeController.setThemeMode(ThemeMode.light),
                        ),
                        AppSizes.gapW8,
                        AppFilterPill(
                          label: 'Dark',
                          isSelected: context.isDarkMode,
                          onTap: () => themeController.setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSizes.gapH24,

              // 5. BACKUP & RESTORE
              Text(
                'Data Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSizes.gapH12,
              BorderlessCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export your entire database to JSON or restore from an existing backup.',
                      style: TextStyle(fontSize: 12.5, color: customColors.subtleText),
                    ),
                    AppSizes.gapH12,
                    AppButton.outline(
                      text: 'Backup & Restore (JSON)',
                      prefixIcon: const Icon(Icons.backup_outlined, size: 16),
                      isFullWidth: true,
                      onPressed: () => BackupRestoreDialog.show(context),
                    ),
                  ],
                ),
              ),
              AppSizes.gapH32,

              Center(
                child: Text(
                  '${AppConstants.appName} • 100% Private & Local',
                  style: TextStyle(fontSize: 12, color: customColors.subtleText),
                ),
              ),
              AppSizes.gapH20,
            ],
          ),
        );
      }),
    );
  }
}
