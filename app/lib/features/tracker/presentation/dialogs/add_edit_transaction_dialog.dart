import 'package:flutter/material.dart';
import 'package:luthor/luthor.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/transaction_model.dart';
import '../../controllers/tracker_controller.dart';

class AddEditTransactionDialog extends StatefulWidget {
  const AddEditTransactionDialog({
    super.key,
    this.initialType = TransactionType.expense,
    this.transactionToEdit,
  });

  final TransactionType initialType;
  final TransactionModel? transactionToEdit;

  static Future<void> show(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
    TransactionModel? transactionToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditTransactionDialog(
        initialType: initialType,
        transactionToEdit: transactionToEdit,
      ),
    );
  }

  @override
  State<AddEditTransactionDialog> createState() =>
      _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _tagController;
  late final TextEditingController _noteController;

  late TransactionType _selectedType;
  late DateTime _selectedDate;
  String? _selectedTag;
  String? _titleError;
  String? _amountError;

  // Zod-like schema using Luthor
  static final _transactionSchema = l.schema({
    'amount': l
        .string()
        .required(message: 'Please enter an amount')
        .min(1, message: 'Please enter an amount')
        .custom((value) {
          final parsed = double.tryParse(value.trim());
          return parsed != null && parsed > 0;
        }, message: 'Enter a valid amount greater than 0'),
    'title': l
        .string()
        .required(message: 'Please enter a title')
        .min(1, message: 'Please enter a title')
        .custom(
          (value) => value.trim().isNotEmpty,
          message: 'Please enter a title',
        ),
  });

  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;
    _selectedType = edit?.type ?? widget.initialType;
    _selectedDate = edit?.date ?? DateTime.now();
    _selectedTag = edit?.tag;

    _titleController = TextEditingController(text: edit?.title ?? '');
    _amountController = TextEditingController(
      text: edit != null
          ? edit.amount.toStringAsFixed(
              edit.amount.truncateToDouble() == edit.amount ? 0 : 2,
            )
          : '',
    );
    _tagController = TextEditingController(text: edit?.tag ?? '');
    _noteController = TextEditingController(text: edit?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final rawData = {
      'amount': _amountController.text.trim(),
      'title': _titleController.text.trim(),
    };

    final result = _transactionSchema.validate(rawData);

    if (!result.isValid) {
      setState(() {
        _amountError = result.getError('amount');
        _titleError = result.getError('title');
      });
      return;
    }

    if (_amountError != null || _titleError != null) {
      setState(() {
        _amountError = null;
        _titleError = null;
      });
    }

    final title = _titleController.text.trim();
    final parsedAmount = double.parse(_amountController.text.trim());

    final tag = _selectedTag?.trim().isNotEmpty == true
        ? _selectedTag
        : _tagController.text.trim().isNotEmpty
        ? _tagController.text.trim()
        : null;

    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    final controller = TrackerController.to;

    if (isEditing) {
      final updated = widget.transactionToEdit!.copyWith(
        title: title,
        amount: parsedAmount,
        type: _selectedType,
        date: _selectedDate,
        tag: tag,
        note: note,
      );
      controller.updateTransaction(updated);
    } else {
      controller.addTransaction(
        title: title,
        amount: parsedAmount,
        type: _selectedType,
        date: _selectedDate,
        tag: tag,
        note: note,
      );
    }

    Navigator.pop(context);
  }

  void _delete() {
    if (widget.transactionToEdit != null) {
      TrackerController.to.deleteTransaction(widget.transactionToEdit!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final defaultTags = _selectedType == TransactionType.income
        ? AppConstants.defaultIncomeTags
        : AppConstants.defaultExpenseTags;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softInputFill = customColors.inputFill;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: customColors.bottomSheetHandle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            AppSizes.gapH16,

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Transaction' : 'Record Transaction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _delete,
                    tooltip: 'Delete transaction',
                  ),
              ],
            ),
            AppSizes.gapH16,

            // Type Toggle (Income / Expense)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Income',
                    prefixIcon: const Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                    ),
                    variant: _selectedType == TransactionType.income
                        ? ButtonVariant.primary
                        : ButtonVariant.outline,
                    backgroundColor: _selectedType == TransactionType.income
                        ? const Color(0xFF16A34A)
                        : null,
                    foregroundColor: _selectedType == TransactionType.income
                        ? Colors.white
                        : null,
                    onPressed: () {
                      setState(() {
                        _selectedType = TransactionType.income;
                        _selectedTag = null;
                      });
                    },
                  ),
                ),
                AppSizes.gapW12,
                Expanded(
                  child: AppButton(
                    text: 'Expense',
                    prefixIcon: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                    ),
                    variant: _selectedType == TransactionType.expense
                        ? ButtonVariant.primary
                        : ButtonVariant.outline,
                    backgroundColor: _selectedType == TransactionType.expense
                        ? const Color(0xFFDC2626)
                        : null,
                    foregroundColor: _selectedType == TransactionType.expense
                        ? Colors.white
                        : null,
                    onPressed: () {
                      setState(() {
                        _selectedType = TransactionType.expense;
                        _selectedTag = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            AppSizes.gapH16,

            // Amount Input
            AppTextField(
              controller: _amountController,
              label: 'Amount (${AppConstants.currencySymbol})',
              hint: '0.00',
              errorText: _amountError,
              onChanged: (_) {
                if (_amountError != null) {
                  setState(() => _amountError = null);
                }
              },
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    AppConstants.currencySymbol,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            AppSizes.gapH16,

            // Title Input
            AppTextField(
              controller: _titleController,
              label: 'Title',
              hint: _selectedType == TransactionType.income
                  ? 'e.g. Monthly Salary, Freelance Gig'
                  : 'e.g. Dinner, Grocery Shopping, Rent',
              errorText: _titleError,
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
              textInputAction: TextInputAction.next,
            ),
            AppSizes.gapH16,

            // Date Selector Button
            Text(
              'Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: customColors.subtleText,
              ),
            ),
            AppSizes.gapH6,
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: softInputFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: customColors.subtleText,
                    ),
                    AppSizes.gapW12,
                    Text(
                      CurrencyFormatter.formatDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: customColors.subtleText,
                    ),
                  ],
                ),
              ),
            ),
            AppSizes.gapH16,

            // Tags (Suggested Chips)
            Text(
              'Tag / Category (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: customColors.subtleText,
              ),
            ),
            AppSizes.gapH8,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: defaultTags.map((tag) {
                final isSelected = _selectedTag == tag;
                return AppFilterPill(
                  label: tag,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedTag = isSelected ? null : tag;
                      _tagController.text = _selectedTag ?? '';
                    });
                  },
                );
              }).toList(),
            ),
            AppSizes.gapH16,

            // Notes
            AppTextField(
              controller: _noteController,
              label: 'Notes (Optional)',
              hint: 'Additional details...',
              maxLines: 2,
            ),

            AppSizes.gapH24,

            // Submit Button
            AppButton(
              size: ButtonSize.lg,
              text: isEditing ? 'Save Changes' : 'Save Transaction',
              isFullWidth: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
