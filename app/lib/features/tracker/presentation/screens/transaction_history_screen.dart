import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../sync/presentation/widgets/item_sync_dot.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_edit_transaction_dialog.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  static void navigate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryScreen(),
      ),
    );
  }

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const int _pageSize = 20;
  int _displayedCount = _pageSize;
  int _filterIndex = 0; // 0: All, 1: Expense, 2: Income
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    _isLoadingMore = true;
    setState(() {
      _displayedCount += _pageSize;
      _isLoadingMore = false;
    });
  }

  Widget _buildTransactionCard({
    required BuildContext context,
    required TransactionModel tx,
    required ColorScheme colorScheme,
    required AppCustomColors customColors,
  }) {
    final isIncome = tx.isIncome;
    final txColor = AppColors.getTransactionColor(
      tag: tx.tag,
      title: tx.title,
      isIncome: isIncome,
    );

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
              color: txColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: txColor,
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
                    Flexible(
                      child: Text(
                        tx.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ItemSyncDot(isSynced: tx.isSynced),
                  ],
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
                    if (tx.tag != null && tx.tag!.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: customColors.subtleText,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tx.tag!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: txColor,
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
                  color: isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        onPressed: () => AddEditTransactionDialog.show(context),
        child: const Icon(Icons.add, size: 22),
      ),
      body: Obx(() {
        var list = controller.sortedTransactions;

        if (_filterIndex == 1) {
          list = list.where((t) => t.isExpense).toList();
        } else if (_filterIndex == 2) {
          list = list.where((t) => t.isIncome).toList();
        }

        final query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          list = list.where((t) {
            final titleMatch = t.title.toLowerCase().contains(query);
            final tagMatch = t.tag?.toLowerCase().contains(query) ?? false;
            final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
            return titleMatch || tagMatch || noteMatch;
          }).toList();
        }

        final totalMatching = list.length;
        final hasMore = _displayedCount < totalMatching;
        final visibleList = list.take(_displayedCount).toList();

        return Column(
          children: [
            // Search and Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  AppTextField(
                    controller: _searchController,
                    hint: 'Search by title, tag, or note...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    onChanged: (val) {
                      setState(() {
                        _displayedCount = _pageSize;
                      });
                    },
                  ),
                  AppSizes.gapH10,
                  Row(
                    children: [
                      AppFilterPill(
                        label: 'All',
                        isSelected: _filterIndex == 0,
                        onTap: () => setState(() {
                          _filterIndex = 0;
                          _displayedCount = _pageSize;
                        }),
                      ),
                      AppSizes.gapW8,
                      AppFilterPill(
                        label: 'Expense',
                        isSelected: _filterIndex == 1,
                        accentColor: const Color(0xFFDC2626),
                        onTap: () => setState(() {
                          _filterIndex = 1;
                          _displayedCount = _pageSize;
                        }),
                      ),
                      AppSizes.gapW8,
                      AppFilterPill(
                        label: 'Income',
                        isSelected: _filterIndex == 2,
                        accentColor: const Color(0xFF16A34A),
                        onTap: () => setState(() {
                          _filterIndex = 2;
                          _displayedCount = _pageSize;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Paginated Transactions List
            Expanded(
              child: visibleList.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions found',
                      description: 'Try adjusting your search or filters.',
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: visibleList.length + (hasMore ? 1 : 0),
                      separatorBuilder: (context, index) => AppSizes.gapH8,
                      itemBuilder: (context, index) {
                        if (index == visibleList.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }

                        final tx = visibleList[index];
                        return _buildTransactionCard(
                          context: context,
                          tx: tx,
                          colorScheme: colorScheme,
                          customColors: customColors,
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
