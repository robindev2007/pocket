import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/ai_controller.dart';
import '../../models/ai_message_model.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  static Future<void> navigate(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiChatScreen()),
    );
  }

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _quickStarters = [
    {
      'title': 'Current Balance',
      'query': 'What is my current balance?',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'title': 'Last Expense',
      'query': 'What was my last expense?',
      'icon': Icons.receipt_long_outlined,
    },
    {
      'title': 'Monthly Spending',
      'query': 'How much did I spend this month?',
      'icon': Icons.pie_chart_outline_rounded,
    },
    {
      'title': 'Debt Tracker',
      'query': 'Who owes me money?',
      'icon': Icons.people_outline_rounded,
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showModelPicker(BuildContext context, AiController aiController,
      ColorScheme colorScheme, AppCustomColors customColors, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: customColors.cardBorder, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Text(
                  'Select AI Model',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Obx(() {
                  final current = aiController.selectedProvider.value;
                  return Column(
                    children: [
                      _buildModelCard(
                        id: 'gemini',
                        name: 'Google Gemini',
                        badge: 'Flash Lite',
                        desc: 'Fast, multimodal & structured tool execution',
                        isSelected: current == 'gemini',
                        onTap: () {
                          aiController.setProvider('gemini');
                          Navigator.pop(ctx);
                        },
                        colorScheme: colorScheme,
                        customColors: customColors,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildModelCard(
                        id: 'openrouter',
                        name: 'OpenRouter',
                        badge: 'Nemotron',
                        desc: 'Free open model for smart financial reasoning',
                        isSelected: current == 'openrouter',
                        onTap: () {
                          aiController.setProvider('openrouter');
                          Navigator.pop(ctx);
                        },
                        colorScheme: colorScheme,
                        customColors: customColors,
                        isDark: isDark,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelCard({
    required String id,
    required String name,
    required String badge,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required AppCustomColors customColors,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF1E293B) : customColors.surfaceHover),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : customColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : customColors.subtleText.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                id == 'gemini' ? Icons.auto_awesome_rounded : Icons.hub_rounded,
                size: 18,
                color: isSelected ? Colors.white : customColors.subtleText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: customColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiController = Get.put(AiController());
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final isDark = context.isDarkMode;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: _buildHistoryDrawer(aiController, colorScheme, customColors, isDark),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: InkWell(
          onTap: () => _showModelPicker(context, aiController, colorScheme, customColors, isDark),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                // Visible, clean Model Select Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Obx(() {
                    final provider = aiController.selectedProvider.value;
                    final label = provider == 'openrouter' ? 'OpenRouter' : 'Gemini';
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: customColors.subtleText,
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // New Chat Button
          IconButton(
            tooltip: 'New Chat',
            icon: const Icon(Icons.edit_note_rounded, size: 22),
            onPressed: () => aiController.startNewChat(),
          ),
          // History Drawer Button
          IconButton(
            tooltip: 'Chat History',
            icon: const Icon(Icons.history_rounded, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Divider(height: 1, thickness: 1, color: customColors.cardBorder),

          // Message list & Empty Welcome Hero
          Expanded(
            child: Obx(() {
              final list = aiController.messages;
              final userMessages = list.where((m) => m.isUser).toList();

              // When fresh conversation, show elegant quick-start hero
              if (userMessages.isEmpty && list.length <= 1) {
                return _buildEmptyStateHero(aiController, colorScheme, customColors, isDark);
              }

              _scrollToBottom();
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final msg = list[index];
                  return _buildMessageBubble(
                    msg: msg,
                    colorScheme: colorScheme,
                    customColors: customColors,
                    isDark: isDark,
                  );
                },
              );
            }),
          ),

          // Bottom Input Bar
          _buildInputBar(aiController, colorScheme, customColors),
        ],
      ),
    );
  }

  Widget _buildEmptyStateHero(
    AiController aiController,
    ColorScheme colorScheme,
    AppCustomColors customColors,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'How can I help with your money?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Ask about balances, log spending, track debts, or compare reports.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: customColors.subtleText,
            ),
          ),
          const SizedBox(height: 28),

          // Quick Starter Cards Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickStarters.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final item = _quickStarters[index];
              return InkWell(
                onTap: () {
                  aiController.sendMessage(item['query'] as String);
                  _scrollToBottom();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 17,
                        color: customColors.subtleText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
    AiController aiController,
    ColorScheme colorScheme,
    AppCustomColors customColors,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: customColors.cardBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _textController,
                hint: 'Ask or log expenses, debts...',
                prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                onSubmitted: (val) {
                  aiController.sendMessage(val);
                  _textController.clear();
                  _scrollToBottom();
                },
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final isBusy = aiController.isLoading.value;
              return IconButton.filled(
                onPressed: isBusy
                    ? null
                    : () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          aiController.sendMessage(text);
                          _textController.clear();
                          _scrollToBottom();
                        }
                      },
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 20),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDrawer(
    AiController aiController,
    ColorScheme colorScheme,
    AppCustomColors customColors,
    bool isDark,
  ) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: customColors.cardBorder),

            // New Chat Action
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: InkWell(
                onTap: () {
                  aiController.startNewChat();
                  Navigator.of(context).maybePop();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Start New Chat',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sessions List
            Expanded(
              child: Obx(() {
                final sessions = aiController.chatSessions;
                if (sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No saved chats yet.\nConversations will be stored here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: customColors.subtleText,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isActive = aiController.activeSessionId.value == session.id;

                    return InkWell(
                      onTap: () {
                        aiController.resumeSession(session);
                        Navigator.of(context).maybePop();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive ? colorScheme.primary : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: isActive ? colorScheme.primary : customColors.subtleText,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${session.messages.length} msgs • ${_formatDate(session.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: customColors.subtleText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: customColors.subtleText,
                              ),
                              onPressed: () => aiController.deleteSession(session.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // Clear All Footer
            Obx(() {
              if (aiController.chatSessions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () {
                    aiController.clearAllSessions();
                    Navigator.of(context).maybePop();
                  },
                  icon: Icon(Icons.delete_sweep_rounded, size: 16, color: colorScheme.error),
                  label: Text('Clear All History', style: TextStyle(fontSize: 12, color: colorScheme.error)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $ampm';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _buildMessageBubble({
    required AiMessageModel msg,
    required ColorScheme colorScheme,
    required AppCustomColors customColors,
    required bool isDark,
  }) {
    final isUser = msg.isUser;
    final bg = isUser
        ? colorScheme.primary
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final textColor = isUser ? Colors.white : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bg,
                    border: isUser
                        ? null
                        : Border.all(
                            color: customColors.cardBorder,
                            width: 1,
                          ),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          isUser ? const Radius.circular(2) : const Radius.circular(16),
                      bottomLeft:
                          !isUser ? const Radius.circular(2) : const Radius.circular(16),
                    ),
                  ),
                  child: isUser
                      ? Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: textColor,
                          ),
                        )
                      : msg.text.trim().isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: TypingDotsIndicator(color: colorScheme.primary),
                            )
                          : MarkdownBody(
                              data: msg.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: textColor,
                                ),
                                listBullet: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                ),
                                code: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                  backgroundColor: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFE2E8F0),
                                  fontFamily: 'monospace',
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                ),
              ),
            ],
          ),
          if (msg.toolExecuted != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 11, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Tool executed: ${msg.toolExecuted}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: customColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TypingDotsIndicator extends StatefulWidget {
  final Color color;
  const TypingDotsIndicator({super.key, required this.color});

  @override
  State<TypingDotsIndicator> createState() => _TypingDotsIndicatorState();
}

class _TypingDotsIndicatorState extends State<TypingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final val = (_controller.value - delay) % 1.0;
            final opacity = (0.25 + 0.75 * (0.5 + 0.5 * math.sin(val * 2 * math.pi))).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 6.5,
              height: 6.5,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
