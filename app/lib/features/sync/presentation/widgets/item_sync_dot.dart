import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/sync_controller.dart';

class ItemSyncDot extends StatelessWidget {
  const ItemSyncDot({
    super.key,
    required this.isSynced,
  });

  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
