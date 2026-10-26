import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/person_debt_model.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_debt_dialog.dart';
import '../dialogs/add_person_dialog.dart';
import 'person_ledger_screen.dart';

class DebtsTab extends StatefulWidget {
  const DebtsTab({super.key});

  @override
  State<DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<DebtsTab> {
  int _filterIndex = 0; // 0: All People, 1: They Owe Me, 2: I Owe Them, 3: Settled
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'No activity';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showAddActionSheet(BuildContext context) {
    final controller = TrackerController.to;
    if (controller.people.isEmpty) {
      AddPersonDialog.show(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final customColors = context.customColors;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: customColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: customColors.bottomSheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppSizes.gapH16,
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D83F5).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Color(0xFF3D83F5)),
                ),
                title: const Text('Add New Person', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Add a new contact to track debts with'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  AddPersonDialog.show(context);
                },
              ),
              const Divider(height: 12),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_outward_rounded, color: Color(0xFF059669)),
                ),
                title: const Text('Add Loan / Debt Entry', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Record money given or borrowed'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showSelectPersonPicker(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSelectPersonPicker(BuildContext context) {
    final controller = TrackerController.to;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final customColors = context.customColors;
        final colorScheme = context.colorScheme;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: customColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: customColors.bottomSheetHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSizes.gapH16,
              Text(
                'Select Person',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose who you want to record a debt with:',
                style: TextStyle(fontSize: 12, color: customColors.subtleText),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.people.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, idx) {
                    final p = controller.people[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: _getAvatarColor(p),
                        child: Text(
                          _getInitials(p),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        AddDebtDialog.show(context, personName: p);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController.to;
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        onPressed: () => _showAddActionSheet(context),
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // 1. Debt Top Summary Cards (Global Overview)
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

                  // Search Box
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search people by name...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: customColors.subtleText,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 19,
                          color: customColors.subtleText,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                    ),
                  ),
                  AppSizes.gapH10,

                  // Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AppFilterPill(
                          label: 'All (${controller.peopleSummaries.length})',
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
                          label: 'Settled',
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

          // 2. People Directory List
          Expanded(
            child: Obx(() {
              final allSummaries = controller.peopleSummaries;

              // Filter by tab
              List<PersonDebtSummary> filtered;
              if (_filterIndex == 0) {
                filtered = allSummaries;
              } else if (_filterIndex == 1) {
                filtered = allSummaries.where((p) => p.theyOweUser).toList();
              } else if (_filterIndex == 2) {
                filtered = allSummaries.where((p) => p.userOwesThem).toList();
              } else {
                filtered = allSummaries.where((p) => p.isSettled).toList();
              }

              // Filter by search query
              if (_searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((p) =>
                        p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              if (allSummaries.isEmpty) {
                return _buildEmptyPeopleState(context);
              }

              if (filtered.isEmpty) {
                return _buildNoResultsState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final summary = filtered[index];
                  return _buildPersonCard(context, summary);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(BuildContext context, PersonDebtSummary summary) {
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final isDark = context.isDarkMode;

    final Color statusColor;
    final String statusText;
    final String balanceText;

    if (summary.theyOweUser) {
      statusColor = const Color(0xFF059669); // Emerald
      statusText = 'Owes you';
      balanceText = '+ ${CurrencyFormatter.format(summary.theyOweMe)}';
    } else if (summary.userOwesThem) {
      statusColor = const Color(0xFFD97706); // Amber
      statusText = 'You owe';
      balanceText = '- ${CurrencyFormatter.format(summary.iOweThem)}';
    } else {
      statusColor = isDark ? Colors.white54 : const Color(0xFF64748B);
      statusText = 'All settled';
      balanceText = CurrencyFormatter.format(0);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => PersonLedgerScreen.navigate(context, summary.name),
          borderRadius: BorderRadius.circular(16),
          child: BorderlessCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar with initials
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(summary.name),
                  child: Text(
                    _getInitials(summary.name),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                AppSizes.gapW12,

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary.isSettled
                            ? 'Settled • ${_formatDate(summary.lastActivityDate)}'
                            : '${summary.activeDebtsCount} active • ${_formatDate(summary.lastActivityDate)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: customColors.subtleText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balanceText,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (summary.isSettled)
                          const Icon(Icons.check_rounded, size: 12, color: Color(0xFF059669)),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: customColors.subtleText.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPeopleState(BuildContext context) {
    final customColors = context.customColors;
    final colorScheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
            AppSizes.gapH16,
            Text(
              'No People Added Yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            AppSizes.gapH8,
            Text(
              'Add friends, colleagues, or vendors to keep an organized history of loans, borrowings, and repayments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: customColors.subtleText,
                height: 1.4,
              ),
            ),
            AppSizes.gapH20,
            AppButton(
              text: 'Add First Person',
              prefixIcon: const Icon(Icons.person_add_rounded, size: 18),
              onPressed: () => AddPersonDialog.show(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final customColors = context.customColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: customColors.subtleText.withValues(alpha: 0.5),
          ),
          AppSizes.gapH12,
          Text(
            'No contacts found',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filter tab',
            style: TextStyle(fontSize: 12, color: customColors.subtleText),
          ),
        ],
      ),
    );
  }
}
