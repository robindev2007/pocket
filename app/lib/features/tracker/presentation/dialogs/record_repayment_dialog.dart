import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/debt_model.dart';
import '../../controllers/tracker_controller.dart';

class RecordRepaymentDialog extends StatefulWidget {
  const RecordRepaymentDialog({
    super.key,
    required this.debt,
  });

  final DebtModel debt;

  static Future<void> show(BuildContext context, DebtModel debt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordRepaymentDialog(debt: debt),
    );
  }

  @override
  State<RecordRepaymentDialog> createState() => _RecordRepaymentDialogState();
}

class _RecordRepaymentDialogState extends State<RecordRepaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _fillFullAmount() {
    setState(() {
      _amountController.text = widget.debt.remainingAmount.toStringAsFixed(
        widget.debt.remainingAmount.truncateToDouble() == widget.debt.remainingAmount ? 0 : 2,
      );
    });
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final parsed = double.tryParse(amountText);

    if (parsed == null || parsed <= 0) {
      setState(() => _errorMessage = 'Please enter a valid repayment amount');
      return;
    }

    if (parsed > widget.debt.remainingAmount + 0.001) {
      setState(() => _errorMessage =
          'Repayment cannot exceed remaining amount (${CurrencyFormatter.format(widget.debt.remainingAmount)})');
      return;
    }

    TrackerController.to.recordRepayment(
      debtId: widget.debt.id,
      amount: parsed,
      date: _selectedDate,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              'Record Repayment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            AppSizes.gapH8,
            Text(
              'Debt: ${widget.debt.title} (${widget.debt.personName})',
              style: TextStyle(fontSize: 13, color: customColors.subtleText),
            ),
            AppSizes.gapH16,

            // Remaining Amount Highlight Card
            BorderlessCard(
              backgroundColor: customColors.surfaceHover,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining Balance',
                        style: TextStyle(fontSize: 12, color: customColors.subtleText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(widget.debt.remainingAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: widget.debt.isTheyOweMe
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  AppButton.outline(
                    text: 'Pay Full',
                    size: ButtonSize.sm,
                    onPressed: _fillFullAmount,
                  ),
                ],
              ),
            ),
            AppSizes.gapH16,

            // Amount to repay
            AppTextField(
              controller: _amountController,
              label: 'Repayment Amount (${AppConstants.currencySymbol})',
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

            // Note
            AppTextField(
              controller: _noteController,
              label: 'Note (Optional)',
              hint: 'e.g. Bkash, cash in hand, partial return',
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
              text: 'Confirm Repayment',
              isFullWidth: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

