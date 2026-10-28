import 'package:flutter/material.dart';

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
