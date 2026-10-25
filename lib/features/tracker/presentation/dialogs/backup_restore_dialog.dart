import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/tracker_controller.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BackupRestoreDialog(),
    );
  }

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  final _importController = TextEditingController();
  String _exportedJson = '';
  bool _isLoading = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadExport();
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _loadExport() async {
    final jsonStr = await TrackerController.to.exportBackup();
    if (mounted) {
      setState(() {
        _exportedJson = jsonStr;
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _exportedJson));
    Get.snackbar(
      'Backup Copied',
      'Data JSON copied to clipboard successfully.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _importData() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      setState(() => _statusMessage = 'Please paste backup JSON first');
      return;
    }

    final success = await TrackerController.to.importBackup(text);
    if (success) {
      Get.snackbar(
        'Restore Successful',
        'Your transactions and debts have been restored.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      setState(() => _statusMessage = 'Invalid JSON backup format');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
              'Local Data Backup & Restore',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            AppSizes.gapH6,
            Text(
              'All data stays entirely local on your device. You can copy the backup JSON anytime.',
              style: TextStyle(fontSize: 12.5, color: customColors.subtleText),
            ),
            AppSizes.gapH16,

            // EXPORT SECTION
            Text(
              'Export Current Data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            AppSizes.gapH8,
            Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softInputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : SingleChildScrollView(
                      child: Text(
                        _exportedJson,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: customColors.subtleText,
                        ),
                      ),
                    ),
            ),
            AppSizes.gapH10,
            AppButton.outline(
              text: 'Copy Backup JSON to Clipboard',
              prefixIcon: const Icon(Icons.copy_rounded, size: 16),
              isFullWidth: true,
              onPressed: _exportedJson.isNotEmpty ? _copyToClipboard : null,
            ),
            AppSizes.gapH24,

            // RESTORE SECTION
            Text(
              'Restore from Backup',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            AppSizes.gapH8,
            AppTextField(
              controller: _importController,
              hint: 'Paste your backup JSON here...',
              maxLines: 4,
            ),
            if (_statusMessage != null) ...[
              AppSizes.gapH8,
              Text(
                _statusMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            AppSizes.gapH12,
            AppButton(
              text: 'Restore Data',
              prefixIcon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
              isFullWidth: true,
              onPressed: _importData,
            ),
          ],
        ),
      ),
    );
  }
}
