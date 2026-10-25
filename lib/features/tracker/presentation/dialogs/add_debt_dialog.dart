import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/debt_model.dart';
import '../../controllers/tracker_controller.dart';

class AddDebtDialog extends StatefulWidget {
  const AddDebtDialog({
    super.key,
    this.initialDirection = DebtDirection.theyOweMe,
  });

  final DebtDirection initialDirection;

  static Future<void> show(
    BuildContext context, {
    DebtDirection initialDirection = DebtDirection.theyOweMe,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDebtDialog(initialDirection: initialDirection),
    );
  }

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  late final TextEditingController _personController;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late DebtDirection _selectedDirection;
  late DateTime _selectedDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDirection = widget.initialDirection;
    _selectedDate = DateTime.now();

    _personController = TextEditingController();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _personController.dispose();
    _titleController.dispose();
    _amountController.dispose();
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
    final person = _personController.text.trim();
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final parsedAmount = double.tryParse(amountText);

    if (person.isEmpty) {
      setState(() => _errorMessage = 'Please enter or select a person');
      return;
    }
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a title');
      return;
    }
    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    TrackerController.to.addDebt(
      personName: person,
      title: title,
      amount: parsedAmount,
      date: _selectedDate,
      direction: _selectedDirection,
      note: note,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final controller = TrackerController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softInputFill = isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF1F5F9);

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

            Text(
              'Record Debt Entry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            AppSizes.gapH16,

            // Direction Selection
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'They owe me (+)',
                    variant: _selectedDirection == DebtDirection.theyOweMe
                        ? ButtonVariant.primary
                        : ButtonVariant.outline,
                    backgroundColor: _selectedDirection == DebtDirection.theyOweMe
                        ? const Color(0xFF059669)
                        : null,
                    foregroundColor: _selectedDirection == DebtDirection.theyOweMe
                        ? Colors.white
                        : null,
                    onPressed: () {
                      setState(() => _selectedDirection = DebtDirection.theyOweMe);
                    },
                  ),
                ),
                AppSizes.gapW12,
                Expanded(
                  child: AppButton(
                    text: 'I owe them (-)',
                    variant: _selectedDirection == DebtDirection.iOweThem
                        ? ButtonVariant.primary
                        : ButtonVariant.outline,
                    backgroundColor: _selectedDirection == DebtDirection.iOweThem
                        ? const Color(0xFFD97706)
                        : null,
                    foregroundColor: _selectedDirection == DebtDirection.iOweThem
                        ? Colors.white
                        : null,
                    onPressed: () {
                      setState(() => _selectedDirection = DebtDirection.iOweThem);
                    },
                  ),
                ),
              ],
            ),
            AppSizes.gapH16,

            // Person Selector / Input
            AppTextField(
              controller: _personController,
              label: 'Person Name',
              hint: 'e.g. John, Sarah, Brother',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
            ),

            // Quick select existing people
            if (controller.people.isNotEmpty) ...[
              AppSizes.gapH8,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: controller.people.map((p) {
                  final isSelected = _personController.text == p;
                  return AppFilterPill(
                    label: p,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _personController.text = p;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            AppSizes.gapH16,

            // Debt Title
            AppTextField(
              controller: _titleController,
              label: 'Title / Reason',
              hint: _selectedDirection == DebtDirection.theyOweMe
                  ? 'e.g. Lunch split, Lent cash'
                  : 'e.g. Borrowed for emergency, Rent share',
            ),
            AppSizes.gapH16,

            // Amount
            AppTextField(
              controller: _amountController,
              label: 'Amount (${AppConstants.currencySymbol})',
              hint: '0.00',
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AppSizes.gapH16,

            // Date
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: softInputFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: customColors.subtleText),
                    AppSizes.gapW12,
                    Text(
                      CurrencyFormatter.formatDate(_selectedDate),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: customColors.subtleText),
                  ],
                ),
              ),
            ),
            AppSizes.gapH16,

            // Note
            AppTextField(
              controller: _noteController,
              label: 'Notes (Optional)',
              hint: 'Additional terms or memo...',
              maxLines: 2,
            ),

            if (_errorMessage != null) ...[
              AppSizes.gapH12,
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            AppSizes.gapH24,

            AppButton(
              text: 'Save Debt Entry',
              isFullWidth: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

