import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/debt_model.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_debt_dialog.dart';
import '../dialogs/record_repayment_dialog.dart';

class DebtsTab extends StatefulWidget {
  const DebtsTab({super.key});

  @override
  State<DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<DebtsTab> {
  int _filterIndex = 0; // 0: Outstanding, 1: They Owe Me, 2: I Owe Them, 3: Settled

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController.to;
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        onPressed: () => AddDebtDialog.show(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Debt Entry', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Debt Top Summary Cards
          Obx(() {
            final totalOwedToMe = controller.totalOwedToMe;
            final totalIOwe = controller.totalIOwe;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BorderlessCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: Color(0xFF059669),
                                  ),
                                  AppSizes.gapW4,
                                  Text(
                                    'They Owe Me',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: customColors.subtleText,
                                    ),
                                  ),
                                ],
                              ),
                              AppSizes.gapH8,
                              Text(
                                CurrencyFormatter.format(totalOwedToMe),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSizes.gapW12,
                      Expanded(
                        child: BorderlessCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: Color(0xFFD97706),
                                  ),
                                  AppSizes.gapW4,
                                  Text(
                                    'I Owe Them',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: customColors.subtleText,
                                    ),
                                  ),
                                ],
                              ),
                              AppSizes.gapH8,
                              Text(
                                CurrencyFormatter.format(totalIOwe),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSizes.gapH12,

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AppFilterPill(
                          label: 'Outstanding (${controller.outstandingDebts.length})',
                          isSelected: _filterIndex == 0,
                          onTap: () => setState(() => _filterIndex = 0),
                        ),
                        AppSizes.gapW8,
                        AppFilterPill(
                          label: 'They Owe Me',
                          isSelected: _filterIndex == 1,
                          accentColor: const Color(0xFF059669),
                          onTap: () => setState(() => _filterIndex = 1),
                        ),
                        AppSizes.gapW8,
                        AppFilterPill(
                          label: 'I Owe Them',
                          isSelected: _filterIndex == 2,
                          accentColor: const Color(0xFFD97706),
                          onTap: () => setState(() => _filterIndex = 2),
                        ),
                        AppSizes.gapW8,
                        AppFilterPill(
                          label: 'Settled (${controller.settledDebts.length})',
                          isSelected: _filterIndex == 3,
                          onTap: () => setState(() => _filterIndex = 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Debts List
          Expanded(
            child: Obx(() {
              List<DebtModel> list;
              if (_filterIndex == 0) {
                list = controller.outstandingDebts;
              } else if (_filterIndex == 1) {
                list = controller.outstandingDebts.where((d) => d.isTheyOweMe).toList();
              } else if (_filterIndex == 2) {
                list = controller.outstandingDebts.where((d) => d.isIOweThem).toList();
              } else {
                list = controller.settledDebts;
              }

              if (list.isEmpty) {
                return EmptyStateView(
                  icon: Icons.handshake_outlined,
                  title: _filterIndex == 3 ? 'No settled debts' : 'No active debts',
                  description: _filterIndex == 3
                      ? 'Fully repaid debts will show up here.'
                      : 'Record when someone owes you or you owe someone.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                itemCount: list.length,
                separatorBuilder: (context, index) => AppSizes.gapH8,
                itemBuilder: (context, index) {
                  final debt = list[index];
                  final isTheyOweMe = debt.isTheyOweMe;
                  final isSettled = debt.isSettled;

                  final color = isTheyOweMe ? const Color(0xFF059669) : const Color(0xFFD97706);

                  return BorderlessCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isTheyOweMe
                                    ? Icons.call_received_rounded
                                    : Icons.call_made_rounded,
                                color: color,
                                size: 18,
                              ),
                            ),
                            AppSizes.gapW12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        debt.personName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isTheyOweMe ? 'They owe me' : 'I owe them',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    debt.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Started: ${CurrencyFormatter.formatDate(debt.date)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: customColors.subtleText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                              onPressed: () => controller.deleteDebt(debt.id),
                              tooltip: 'Delete debt record',
                            ),
                          ],
                        ),
                        AppSizes.gapH12,
                        const Divider(height: 1),
                        AppSizes.gapH12,

                        // Amount Breakdown & Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remaining Balance',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: customColors.subtleText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(debt.remainingAmount),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSettled ? Colors.grey : color,
                                  ),
                                ),
                                if (debt.totalRepaid > 0)
                                  Text(
                                    'Repaid: ${CurrencyFormatter.format(debt.totalRepaid)} of ${CurrencyFormatter.format(debt.amount)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: customColors.subtleText,
                                    ),
                                  ),
                              ],
                            ),
                            if (isSettled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Settled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              AppButton(
                                text: 'Repay',
                                size: ButtonSize.sm,
                                prefixIcon: const Icon(Icons.payment_rounded, size: 14),
                                onPressed: () => RecordRepaymentDialog.show(context, debt),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
