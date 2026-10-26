import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/tracker_controller.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileDialog(),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late String _selectedAvatar;
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
    '🎯',
    '🔥',
  ];

  @override
  void initState() {
    super.initState();
    final profile = TrackerController.to.userProfile.value;
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email ?? '');
    _bioController = TextEditingController(text: profile.bio ?? '');
    _selectedAvatar = profile.avatar.isNotEmpty ? profile.avatar : '👤';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Name cannot be empty');
      return;
    }

    TrackerController.to.updateProfile(
      name: name,
      email: _emailController.text.trim(),
      avatar: _selectedAvatar,
      bio: _bioController.text.trim(),
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
              'Edit Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            AppSizes.gapH16,

            // Avatar Choices
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  _selectedAvatar,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ),
            AppSizes.gapH12,
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _avatarChoices.map((emoji) {
                  final isSelected = emoji == _selectedAvatar;
                  return InkWell(
                    onTap: () => setState(() => _selectedAvatar = emoji),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : customColors.surfaceHover,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ),
            ),
            AppSizes.gapH20,

            // Name
            AppTextField(
              controller: _nameController,
              label: 'Display Name',
              hint: 'Your name',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
            ),
            AppSizes.gapH16,

            // Email (Optional)
            AppTextField(
              controller: _emailController,
              label: 'Email (Optional)',
              hint: 'email@example.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              keyboardType: TextInputType.emailAddress,
            ),
            AppSizes.gapH16,

            // Bio (Optional)
            AppTextField(
              controller: _bioController,
              label: 'Bio / Note (Optional)',
              hint: 'e.g. Saving for my dream goal...',
              maxLines: 2,
            ),

            if (_errorMessage != null) ...[
              AppSizes.gapH10,
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            AppSizes.gapH24,

            AppButton(
              text: 'Save Changes',
              isFullWidth: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

