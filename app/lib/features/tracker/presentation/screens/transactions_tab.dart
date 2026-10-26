import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_edit_transaction_dialog.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final _searchController = TextEditingController();
  int _filterIndex = 0; // 0: All, 1: Income, 2: Expense

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        onPressed: () => AddEditTransactionDialog.show(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Top Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                AppTextField(
                  controller: _searchController,
                  hint: 'Search by title, tag, or note...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  onChanged: (val) => setState(() {}),
                ),
                AppSizes.gapH12,
                Row(
                  children: [
                    AppFilterPill(
                      label: 'All',
                      isSelected: _filterIndex == 0,
                      onTap: () => setState(() => _filterIndex = 0),
                    ),
                    AppSizes.gapW8,
                    AppFilterPill(
                      label: 'Income',
                      isSelected: _filterIndex == 1,
                      accentColor: const Color(0xFF16A34A),
                      onTap: () => setState(() => _filterIndex = 1),
                    ),
                    AppSizes.gapW8,
                    AppFilterPill(
                      label: 'Expense',
                      isSelected: _filterIndex == 2,
                      accentColor: const Color(0xFFDC2626),
                      onTap: () => setState(() => _filterIndex = 2),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Obx(() {
              var list = controller.sortedTransactions;

              // Apply Type Filter
              if (_filterIndex == 1) {
                list = list.where((t) => t.isIncome).toList();
              } else if (_filterIndex == 2) {
                list = list.where((t) => t.isExpense).toList();
              }

              // Apply Search Query
              final query = _searchController.text.trim().toLowerCase();
              if (query.isNotEmpty) {
                list = list.where((t) {
                  final titleMatch = t.title.toLowerCase().contains(query);
                  final tagMatch = t.tag?.toLowerCase().contains(query) ?? false;
                  final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
                  return titleMatch || tagMatch || noteMatch;
                }).toList();
              }

              if (list.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions found',
                  description: 'Transactions will appear here once recorded.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: list.length,
                separatorBuilder: (context, index) => AppSizes.gapH8,
                itemBuilder: (context, index) {
                  final tx = list[index];
                  final isIncome = tx.isIncome;

                  return BorderlessCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => AddEditTransactionDialog.show(
                      context,
                      transactionToEdit: tx,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isIncome
                                ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                : const Color(0xFFDC2626).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            size: 18,
                          ),
                        ),
                        AppSizes.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    CurrencyFormatter.formatDate(tx.date),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: customColors.subtleText,
                                    ),
                                  ),
                                  if (tx.tag != null) ...[
                                    const SizedBox(width: 6),
                                    Text('•', style: TextStyle(color: customColors.subtleText, fontSize: 10)),
                                    const SizedBox(width: 6),
                                    Text(
                                      tx.tag!,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: customColors.subtleText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (tx.note != null && tx.note!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  tx.note!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: customColors.subtleText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
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
