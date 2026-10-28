import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/debt_model.dart';
import '../../../../data/models/person_debt_model.dart';
import '../../../sync/presentation/widgets/item_sync_dot.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_debt_dialog.dart';

class PersonLedgerScreen extends StatelessWidget {
  const PersonLedgerScreen({
    super.key,
    required this.personName,
  });

  final String personName;

  static void navigate(BuildContext context, String personName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonLedgerScreen(personName: personName),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF3D83F5),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF06B6D4),
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _confirmDeletePerson(BuildContext context, TrackerController controller) {
    final summary = controller.getPersonSummary(personName);
    if (summary.totalDebtsCount > 0 && !summary.isSettled) {
      Get.snackbar(
        'Cannot Delete',
        '$personName has active outstanding debts. Settle all debts first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $personName?'),
        content: const Text(
          'This will remove this contact from your people list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.deletePerson(personName);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController.to;
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final isDark = context.isDarkMode;

    return Obx(() {
      final summary = controller.getPersonSummary(personName);
      final ledgerItems = controller.getPersonLedger(personName);

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: _getAvatarColor(personName),
                child: Text(
                  _getInitials(personName),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              AppSizes.gapW10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      summary.isSettled
                          ? 'Settled • ${summary.totalDebtsCount} total'
                          : '${summary.activeDebtsCount} active loan(s)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: customColors.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: customColors.subtleText,
              ),
              tooltip: 'Delete Contact',
              onPressed: () => _confirmDeletePerson(context, controller),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // 1. Hero Balance Card
                  _buildHeroBalanceCard(context, summary, controller),
                  AppSizes.gapH16,

                  // 2. Timeline Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ledger Statement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${ledgerItems.length} entries',
                        style: TextStyle(
                          fontSize: 12,
                          color: customColors.subtleText,
                        ),
                      ),
                    ],
                  ),
                  AppSizes.gapH10,

                  // 3. Chronological Statement Timeline
                  if (ledgerItems.isEmpty)
                    _buildEmptyTimeline(context)
                  else
                    ...ledgerItems.map((item) => _buildTimelineTile(context, item)),

                  AppSizes.gapH24,
                ],
              ),
            ),

            // 4. Bottom Sticky Action Bar
            _buildBottomActionBar(context, summary),
          ],
        ),
      );
    });
  }

  Widget _buildHeroBalanceCard(
    BuildContext context,
    PersonDebtSummary summary,
    TrackerController controller,
  ) {
    final customColors = context.customColors;
    final isDark = context.isDarkMode;

    final Color balanceColor;
    final String balanceLabel;
    final String balanceAmount;

    if (summary.theyOweUser) {
      balanceColor = const Color(0xFF059669); // Emerald
      balanceLabel = 'They owe you in total';
      balanceAmount = '+ ${CurrencyFormatter.format(summary.netBalance.abs())}';
    } else if (summary.userOwesThem) {
      balanceColor = const Color(0xFFD97706); // Amber
      balanceLabel = 'You owe them in total';
      balanceAmount = '- ${CurrencyFormatter.format(summary.netBalance.abs())}';
    } else {
      balanceColor = const Color(0xFF059669);
      balanceLabel = 'All debts settled';
      balanceAmount = CurrencyFormatter.format(0);
    }

    return BorderlessCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balanceLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: customColors.subtleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    balanceAmount,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: balanceColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              if (!summary.isSettled)
                InkWell(
                  onTap: () async {
                    await controller.settleAllDebtsForPerson(personName);
                    Get.snackbar(
                      'Settled',
                      'All accounts with $personName have been settled.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green.withValues(alpha: 0.9),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Settle Up',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 12),
          // Sub-metrics row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lent to them',
                      style: TextStyle(
                        fontSize: 11,
                        color: customColors.subtleText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(summary.theyOweMe),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: customColors.cardBorder),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Borrowed from them',
                      style: TextStyle(
                        fontSize: 11,
                        color: customColors.subtleText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(summary.iOweThem),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline(BuildContext context) {
    final customColors = context.customColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: customColors.subtleText.withValues(alpha: 0.5),
            ),
            AppSizes.gapH12,
            Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use the buttons below to record a loan given or borrowed with $personName.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: customColors.subtleText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, PersonLedgerItem item) {
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final isDark = context.isDarkMode;

    final IconData icon;
    final Color badgeColor;
    final String typeLabel;
    final String prefix;

    switch (item.type) {
      case PersonLedgerType.loanGiven:
        icon = Icons.arrow_outward_rounded;
        badgeColor = const Color(0xFF059669);
        typeLabel = 'You Lent';
        prefix = '+';
        break;
      case PersonLedgerType.loanTaken:
        icon = Icons.arrow_downward_rounded;
        badgeColor = const Color(0xFFD97706);
        typeLabel = 'You Borrowed';
        prefix = '-';
        break;
      case PersonLedgerType.repaymentCollected:
        icon = Icons.check_circle_outline_rounded;
        badgeColor = const Color(0xFF059669);
        typeLabel = 'Repayment Received';
        prefix = '-';
        break;
      case PersonLedgerType.repaymentPaid:
        icon = Icons.check_circle_outline_rounded;
        badgeColor = const Color(0xFF2563EB);
        typeLabel = 'Repayment Paid';
        prefix = '+';
        break;
    }

    final isDebt = item.debt != null && item.repayment == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDebt
              ? () => AddDebtDialog.show(
                    context,
                    personName: personName,
                    debtToEdit: item.debt,
                  )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: BorderlessCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type icon badge
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 17, color: badgeColor),
                    ),
                    AppSizes.gapW12,
                    // Title and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.debt != null)
                                ItemSyncDot(isSynced: item.debt!.isSynced),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(item.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: customColors.subtleText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSizes.gapW10,
                    // Amount
                    Text(
                      '$prefix${CurrencyFormatter.format(item.amount)}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.note!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: customColors.subtleText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                // Debt status footer (tap to edit)
                if (isDebt) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (item.debt!.isSettled
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.debt!.isSettled
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_outlined,
                              size: 12,
                              color: item.debt!.isSettled
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.debt!.isSettled ? 'Settled' : 'Unsettled / Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: item.debt!.isSettled
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: customColors.subtleText,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 14, color: customColors.subtleText),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, PersonDebtSummary summary) {
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. You Lent Button (+)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                AddDebtDialog.show(
                  context,
                  personName: personName,
                  initialDirection: DebtDirection.theyOweMe,
                );
              },
              icon: const Icon(Icons.arrow_outward_rounded, size: 16),
              label: const Text('You Lent (+)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          AppSizes.gapW10,

          // 2. You Borrowed Button (-)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                AddDebtDialog.show(
                  context,
                  personName: personName,
                  initialDirection: DebtDirection.iOweThem,
                );
              },
              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
              label: const Text('You Took (-)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
