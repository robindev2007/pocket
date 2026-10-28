import 'package:flutter/material.dart';
import '../screens/ai_chat_screen.dart';

/// Backward-compatible bridge to the full-screen [AiChatScreen].
class AiAssistantSheet extends StatelessWidget {
  const AiAssistantSheet({super.key});

  static void show(BuildContext context) {
    AiChatScreen.navigate(context);
  }

  @override
  Widget build(BuildContext context) {
    return const AiChatScreen();
  }
}
