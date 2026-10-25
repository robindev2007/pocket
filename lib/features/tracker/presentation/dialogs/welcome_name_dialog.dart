import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/tracker_controller.dart';

class WelcomeNameDialog extends StatefulWidget {
  const WelcomeNameDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const WelcomeNameDialog(),
    );
  }

  @override
  State<WelcomeNameDialog> createState() => _WelcomeNameDialogState();
}

class _WelcomeNameDialogState extends State<WelcomeNameDialog> {
  final _nameController = TextEditingController();
  String _selectedAvatar = '👤';
  String? _errorMessage;

  static const List<String> _avatarChoices = [
    '👤',
    '🧑‍💻',
    '💼',
    '💰',
    '🚀',
    '🐱',
    '🌟',
    '👑',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name to continue');
      return;
    }

    TrackerController.to.updateProfile(
      name: name,
      avatar: _selectedAvatar,
      hasCompletedOnboarding: true,
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            AppSizes.gapH12,

            Center(
              child: CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  _selectedAvatar,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            AppSizes.gapH8,

            Center(
              child: Text(
                'Welcome to Pocket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Center(
              child: Text(
                'What should we call you?',
                style: TextStyle(
                  fontSize: 13,
                  color: customColors.subtleText,
                ),
              ),
            ),
            AppSizes.gapH16,

            // Avatar picker
            Text(
              'Choose your avatar icon',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: customColors.subtleText,
              ),
            ),
            AppSizes.gapH8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _avatarChoices.map((emoji) {
                final isSelected = emoji == _selectedAvatar;
                return InkWell(
                  onTap: () => setState(() => _selectedAvatar = emoji),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : customColors.surfaceHover,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                );
              }).toList(),
            ),
            AppSizes.gapH16,

            // Name field
            AppTextField(
              controller: _nameController,
              label: 'Your Name',
              hint: 'e.g. Robin, Alex, Sarah',
              autofocus: true,
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),

            if (_errorMessage != null) ...[
              AppSizes.gapH8,
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            AppSizes.gapH16,

            AppButton(
              text: 'Get Started',
              isFullWidth: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

