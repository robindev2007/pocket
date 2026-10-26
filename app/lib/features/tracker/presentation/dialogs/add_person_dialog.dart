import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/tracker_controller.dart';

class AddPersonDialog extends StatefulWidget {
  const AddPersonDialog({
    super.key,
    this.onPersonAdded,
  });

  final ValueChanged<String>? onPersonAdded;

  static Future<String?> show(
    BuildContext context, {
    ValueChanged<String>? onPersonAdded,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPersonDialog(onPersonAdded: onPersonAdded),
    );
  }

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a name');
      return;
    }

    final controller = TrackerController.to;
    final exists = controller.people.any(
      (p) => p.trim().toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      setState(() => _nameError = 'A person with this name already exists');
      return;
    }

    await controller.addPerson(name);
    if (!mounted) return;

    widget.onPersonAdded?.call(name);
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Title & Subtitle
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              AppSizes.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Person',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Create a profile to record debts and loans with them',
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
          AppSizes.gapH20,

          // Name Input
          AppTextField(
            controller: _nameController,
            label: 'Person Name',
            hint: 'e.g. Tanvir, Rahim, Landlord',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            errorText: _nameError,
            autofocus: true,
            onChanged: (val) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
            onSubmitted: (_) => _handleSave(),
          ),
          AppSizes.gapH24,

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  variant: ButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              AppSizes.gapW12,
              Expanded(
                child: AppButton(
                  text: 'Save Person',
                  variant: ButtonVariant.primary,
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
