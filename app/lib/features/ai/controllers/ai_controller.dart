import 'package:get/get.dart';

import '../../../data/models/debt_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/ai_api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../sync/controllers/sync_controller.dart';
import '../../tracker/controllers/tracker_controller.dart';
import '../models/ai_message_model.dart';

class AiController extends GetxController {
  static AiController get to => Get.find<AiController>();

  final AiApiService _apiService;
  final StorageService _storageService = StorageService();

  AiController({AiApiService? apiService})
    : _apiService = apiService ?? AiApiService();

  final RxList<AiMessageModel> messages = <AiMessageModel>[].obs;
  final RxList<AiChatSessionModel> chatSessions = <AiChatSessionModel>[].obs;
  final RxnString activeSessionId = RxnString();
  final RxInt selectedTabIndex = 0.obs; // 0: Chat, 1: History
  final RxBool isLoading = false.obs;
  final RxString selectedProvider = 'gemini'.obs; // 'gemini' or 'openrouter'

  AiMessageModel _initialWelcomeMessage() {
    return AiMessageModel(
      id: 'welcome',
      role: AiMessageRole.assistant,
      text: 'Hi! I am your AI money assistant. Tell me to log an expense, add income, record debts, or check your spending summaries.',
    );
  }

  @override
  void onInit() {
    super.onInit();
    if (messages.isEmpty) {
      messages.add(_initialWelcomeMessage());
    }
    loadChatSessions();
  }

  Future<void> loadChatSessions() async {
    final loaded = await _storageService.loadChatSessions();
    chatSessions.assignAll(loaded);
  }

  Future<void> saveCurrentSession() async {
    final userMsgs = messages.where((m) => m.isUser).toList();
    if (userMsgs.isEmpty) return;

    final firstQuery = userMsgs.first.text.trim();
    final title = firstQuery.length > 35
        ? '${firstQuery.substring(0, 35)}...'
        : firstQuery;

    final id =
        activeSessionId.value ??
        DateTime.now().millisecondsSinceEpoch.toString();
    activeSessionId.value = id;

    final session = AiChatSessionModel(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      messages: messages.toList(),
    );

    final idx = chatSessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      chatSessions[idx] = session;
    } else {
      chatSessions.insert(0, session);
    }
    await _storageService.saveChatSessions(chatSessions);
  }

  Future<void> startNewChat() async {
    await saveCurrentSession();
    activeSessionId.value = null;
    messages.assignAll([_initialWelcomeMessage()]);
    selectedTabIndex.value = 0;
  }

  void resumeSession(AiChatSessionModel session) {
    activeSessionId.value = session.id;
    messages.assignAll(session.messages);
    selectedTabIndex.value = 0;
  }

  Future<void> deleteSession(String sessionId) async {
    chatSessions.removeWhere((s) => s.id == sessionId);
    if (activeSessionId.value == sessionId) {
      activeSessionId.value = null;
      messages.assignAll([_initialWelcomeMessage()]);
    }
    await _storageService.saveChatSessions(chatSessions);
  }

  Future<void> clearAllSessions() async {
    chatSessions.clear();
    activeSessionId.value = null;
    messages.assignAll([_initialWelcomeMessage()]);
    await _storageService.saveChatSessions([]);
  }

  void setProvider(String provider) {
    selectedProvider.value = provider;
  }

  Future<Map<String, dynamic>> _getUserContext(String? token) async {
    final ctx = <String, dynamic>{
      'isLoggedIn': token != null && token.isNotEmpty,
      'autoSyncEnabled': token != null && token.isNotEmpty,
    };

    if (Get.isRegistered<TrackerController>()) {
      final profile = TrackerController.to.userProfile.value;
      if (profile.name.trim().isNotEmpty) {
        ctx['name'] = profile.name.trim();
      }
      if (profile.email != null && profile.email!.trim().isNotEmpty) {
        ctx['email'] = profile.email!.trim();
      }
      if (profile.currency.trim().isNotEmpty) {
        ctx['currency'] = profile.currency.trim();
      }
    }

    if (Get.isRegistered<SyncController>()) {
      final lastSync = SyncController.to.lastSyncedAt.value;
      if (lastSync != null) {
        ctx['lastSyncedAt'] = lastSync.toIso8601String();
      }
    } else {
      final lastSync = await _storageService.loadLastSyncedAt();
      if (lastSync != null) {
        ctx['lastSyncedAt'] = lastSync.toIso8601String();
      }
    }

    return ctx;
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || isLoading.value) return;

    messages.add(
      AiMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiMessageRole.user,
        text: query,
      ),
    );

    // Initial streaming assistant message placeholder
    final assistantMsg = AiMessageModel(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: AiMessageRole.assistant,
      text: '',
    );
    messages.add(assistantMsg);

    isLoading.value = true;
    try {
      final token = await _storageService.loadAuthToken();
      final userContext = await _getUserContext(token);
      final history = messages
          .where((m) => m.id != 'welcome' && m.id != assistantMsg.id)
          .map((m) => m.toHistoryMap())
          .toList();

      Map<String, dynamic>? toolCallToExecute;
      bool receivedStreamData = false;

      // Real-time SSE streaming from backend
      await for (final chunk in _apiService.sendChatStream(
        message: query,
        history: history,
        provider: selectedProvider.value,
        token: token,
        userContext: userContext,
      )) {
        receivedStreamData = true;
        final type = chunk['type'] as String?;

        if (type == 'delta') {
          final text = chunk['text'] as String? ?? '';
          assistantMsg.appendText(text);
          messages.refresh();
        } else if (type == 'tool_call') {
          toolCallToExecute = chunk['toolCall'] as Map<String, dynamic>?;
        }
      }

      // If streaming didn't produce data, try standard fallback
      if (!receivedStreamData && toolCallToExecute == null) {
        final res = await _apiService.sendChat(
          message: query,
          history: history,
          provider: selectedProvider.value,
          token: token,
          userContext: userContext,
        );

        if (res != null) {
          if (res['type'] == 'tool_call') {
            toolCallToExecute = res['toolCall'] as Map<String, dynamic>?;
          } else {
            assistantMsg.text = res['message'] as String? ?? 'Done.';
            messages.refresh();
          }
        }
      }

      // If a tool call was detected, execute it locally and stream the confirmation
      if (toolCallToExecute != null) {
        final toolName = toolCallToExecute['name'] as String;
        final args =
            toolCallToExecute['arguments'] as Map<String, dynamic>? ?? {};

        assistantMsg.setToolExecuted(toolName);
        messages.refresh();

        // 1. Execute tool locally on device
        final toolOutput = await _executeLocalTool(toolName, args);

        // 2. Stream confirmation from AI
        await for (final chunk in _apiService.sendChatStream(
          history: history,
          toolResult: {'name': toolName, 'result': toolOutput},
          provider: selectedProvider.value,
          token: token,
          userContext: userContext,
        )) {
          final type = chunk['type'] as String?;
          if (type == 'delta') {
            final text = chunk['text'] as String? ?? '';
            assistantMsg.appendText(text);
            messages.refresh();
          }
        }

        if (assistantMsg.text.isEmpty) {
          final finalRes = await _apiService.sendChat(
            history: history,
            toolResult: {'name': toolName, 'result': toolOutput},
            provider: selectedProvider.value,
            token: token,
            userContext: userContext,
          );
          if (finalRes != null && finalRes['message'] != null) {
            assistantMsg.appendText(finalRes['message'] as String);
            messages.refresh();
          }
        }

        if (assistantMsg.text.isEmpty) {
          if (toolName == 'query_spending') {
            final balance = toolOutput['currentBalance'] ?? 0.0;
            final inc = toolOutput['totalIncome'] ?? 0.0;
            final exp = toolOutput['totalExpenses'] ?? 0.0;
            assistantMsg.text =
                'Your current balance is **\$$balance**.\n* Total Income: \$$inc\n* Total Expenses: \$$exp';
          } else {
            assistantMsg.text = 'Completed ${toolName.replaceAll('_', ' ')}.';
          }
          messages.refresh();
        }
      } else if (assistantMsg.text.isEmpty) {
        assistantMsg.text = 'Sorry, could not reach the AI service right now. Please check server connection.';
        messages.refresh();
      }
    } catch (_) {
      if (assistantMsg.text.isEmpty) {
        assistantMsg.text = 'Sorry, could not process your request right now.';
        messages.refresh();
      }
    } finally {
      isLoading.value = false;
      await saveCurrentSession();
    }
  }

  bool _isWithinPeriod(DateTime date, String period, DateTime now) {
    switch (period.toLowerCase()) {
      case 'today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        return date.year == y.year &&
            date.month == y.month &&
            date.day == y.day;
      case 'this_week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        return date.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      case 'this_month':
        return date.year == now.year && date.month == now.month;
      case 'last_month':
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        return date.year == prevYear && date.month == prevMonth;
      case 'all':
      default:
        return true;
    }
  }

  Future<Map<String, dynamic>> _executeLocalTool(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    final controller = TrackerController.to;
    final now = DateTime.now();

    switch (toolName) {
      case 'add_transaction':
        final title = args['title'] as String? ?? 'Expense';
        final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
        final typeStr = args['type'] as String? ?? 'expense';
        final type = typeStr.toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        final tag = args['tag'] as String?;
        final note = args['note'] as String?;

        DateTime date = DateTime.now();
        if (args['date'] != null) {
          try {
            date = DateTime.parse(args['date'] as String);
          } catch (_) {}
        }

        await controller.addTransaction(
          title: title,
          amount: amount,
          type: type,
          date: date,
          tag: tag,
          note: note,
        );
        return {
          'success': true,
          'message': 'Transaction recorded locally',
          'title': title,
          'amount': amount,
          'type': typeStr,
          'tag': tag ?? 'General',
          'date': date.toIso8601String().split('T')[0],
          'currency': controller.userProfile.value.currency,
        };

      case 'update_transaction':
        final id = args['id'] as String?;
        final searchQuery = (args['searchQuery'] as String?)?.toLowerCase();

        TransactionModel? target;
        if (id != null) {
          target = controller.transactions.firstWhereOrNull((t) => t.id == id);
        } else if (searchQuery != null && searchQuery.isNotEmpty) {
          target = controller.transactions.firstWhereOrNull(
            (t) =>
                t.title.toLowerCase().contains(searchQuery) ||
                (t.tag?.toLowerCase().contains(searchQuery) ?? false),
          );
        }

        if (target == null) {
          return {
            'success': false,
            'message': 'No transaction found matching "${searchQuery ?? id}"',
          };
        }

        final newTitle = args['title'] as String? ?? target.title;
        final newAmount = (args['amount'] as num?)?.toDouble() ?? target.amount;
        final newTypeStr = args['type'] as String?;
        final newType = newTypeStr != null
            ? (newTypeStr.toLowerCase() == 'income'
                  ? TransactionType.income
                  : TransactionType.expense)
            : target.type;
        final newTag = args['tag'] as String? ?? target.tag;
        final newNote = args['note'] as String? ?? target.note;

        DateTime newDate = target.date;
        if (args['date'] != null) {
          try {
            newDate = DateTime.parse(args['date'] as String);
          } catch (_) {}
        }

        final updated = target.copyWith(
          title: newTitle,
          amount: newAmount,
          type: newType,
          tag: newTag,
          note: newNote,
          date: newDate,
        );

        await controller.updateTransaction(updated);

        return {
          'success': true,
          'message': 'Updated "${target.title}" to "$newTitle" ($newAmount)',
          'transaction': {
            'id': updated.id,
            'title': updated.title,
            'amount': updated.amount,
            'type': updated.isIncome ? 'income' : 'expense',
            'tag': updated.tag,
            'date': updated.date.toIso8601String().split('T')[0],
          },
          'currency': controller.userProfile.value.currency,
        };

      case 'delete_transaction':
        final query = (args['query'] as String?)?.toLowerCase();
        final id = args['id'] as String?;
        final isAll =
            args['all'] == true ||
            args['all'] == 'true' ||
            query == 'all' ||
            query == 'everything';
        final typeStr = (args['type'] as String?)?.toLowerCase();

        if (isAll) {
          final countBefore = controller.transactions.length;
          if (typeStr == 'expense') {
            controller.transactions.removeWhere((t) => t.isExpense);
          } else if (typeStr == 'income') {
            controller.transactions.removeWhere((t) => t.isIncome);
          } else {
            controller.transactions.clear();
          }
          await StorageService().saveTransactions(controller.transactions);
          final deletedCount = countBefore - controller.transactions.length;
          return {
            'success': true,
            'message': 'Deleted $deletedCount transactions',
            'deletedCount': deletedCount,
          };
        }

        TransactionModel? match;
        if (id != null) {
          match = controller.transactions.firstWhereOrNull((t) => t.id == id);
        } else if (query != null && query.isNotEmpty) {
          match = controller.transactions.firstWhereOrNull(
            (t) =>
                t.title.toLowerCase().contains(query) ||
                (t.tag?.toLowerCase().contains(query) ?? false),
          );
        }

        if (match != null) {
          await controller.deleteTransaction(match.id);
          return {
            'success': true,
            'message':
                'Deleted transaction "${match.title}" of \$${match.amount}',
          };
        }
        return {
          'success': false,
          'message': 'No matching transaction found to delete',
        };

      case 'get_transactions':
        final typeStr = args['type'] as String? ?? 'all';
        final limit = (args['limit'] as num?)?.toInt() ?? 5;
        final sort = args['sort'] as String? ?? 'date_desc';
        final period = args['period'] as String? ?? 'all';
        final tag = args['tag'] as String?;
        final query = (args['query'] as String?)?.toLowerCase();
        final id = args['id'] as String?;

        var list = controller.transactions.toList();

        if (id != null) {
          list = list.where((t) => t.id == id).toList();
        }

        if (typeStr == 'expense') {
          list = list.where((t) => t.isExpense).toList();
        } else if (typeStr == 'income') {
          list = list.where((t) => t.isIncome).toList();
        }

        if (tag != null && tag.isNotEmpty) {
          list = list
              .where((t) => t.tag?.toLowerCase() == tag.toLowerCase())
              .toList();
        }

        if (query != null && query.isNotEmpty) {
          list = list
              .where(
                (t) =>
                    t.title.toLowerCase().contains(query) ||
                    (t.note?.toLowerCase().contains(query) ?? false),
              )
              .toList();
        }

        if (period != 'all') {
          list = list
              .where((t) => _isWithinPeriod(t.date, period, now))
              .toList();
        }

        switch (sort) {
          case 'date_asc':
            list.sort((a, b) => a.date.compareTo(b.date));
            break;
          case 'amount_desc':
            list.sort((a, b) => b.amount.compareTo(a.amount));
            break;
          case 'amount_asc':
            list.sort((a, b) => a.amount.compareTo(b.amount));
            break;
          case 'date_desc':
          default:
            list.sort((a, b) => b.date.compareTo(a.date));
            break;
        }

        final count = list.length;
        final clampedLimit = limit.clamp(1, 20);
        final paginated = list
            .take(clampedLimit)
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'amount': t.amount,
                'type': t.isIncome ? 'income' : 'expense',
                'tag': t.tag ?? 'General',
                'date': t.date.toIso8601String().split('T')[0],
                'note': t.note,
              },
            )
            .toList();

        return {
          'transactions': paginated,
          'count': count,
          'returned': paginated.length,
          'currency': controller.userProfile.value.currency,
        };

      case 'get_financial_summary':
      case 'query_spending':
        final period = args['period'] as String? ?? 'this_month';
        final tag = args['tag'] as String?;
        final compareWithPrev =
            args['compareWithPrevious'] == 'true' ||
            args['compareWithPrevious'] == true;

        var list = controller.transactions.toList();
        if (tag != null && tag.isNotEmpty) {
          list = list
              .where((t) => t.tag?.toLowerCase() == tag.toLowerCase())
              .toList();
        }

        final currentPeriodList = list
            .where((t) => _isWithinPeriod(t.date, period, now))
            .toList();

        final expenseList = currentPeriodList
            .where((t) => t.isExpense)
            .toList();
        final incomeList = currentPeriodList.where((t) => t.isIncome).toList();

        final totalExpenses = expenseList.fold(0.0, (sum, t) => sum + t.amount);
        final totalIncome = incomeList.fold(0.0, (sum, t) => sum + t.amount);
        final netSavings = totalIncome - totalExpenses;

        final categoryMap = <String, double>{};
        for (final t in expenseList) {
          final cat = t.tag ?? 'Uncategorized';
          categoryMap[cat] = (categoryMap[cat] ?? 0.0) + t.amount;
        }

        final categoryBreakdown =
            categoryMap.entries
                .map(
                  (e) => {
                    'category': e.key,
                    'total': e.value,
                    'percentage': totalExpenses > 0
                        ? '${(e.value / totalExpenses * 100).toStringAsFixed(1)}%'
                        : '0%',
                  },
                )
                .toList()
              ..sort(
                (a, b) =>
                    (b['total'] as double).compareTo(a['total'] as double),
              );

        TransactionModel? largestExp;
        if (expenseList.isNotEmpty) {
          largestExp = expenseList.reduce(
            (a, b) => a.amount > b.amount ? a : b,
          );
        }

        TransactionModel? largestInc;
        if (incomeList.isNotEmpty) {
          largestInc = incomeList.reduce((a, b) => a.amount > b.amount ? a : b);
        }

        Map<String, dynamic>? comparison;
        if (compareWithPrev) {
          final prevPeriodList = list
              .where((t) => _isWithinPeriod(t.date, 'last_month', now))
              .where((t) => t.isExpense)
              .toList();
          final prevExpenses = prevPeriodList.fold(
            0.0,
            (sum, t) => sum + t.amount,
          );
          final diff = totalExpenses - prevExpenses;
          final pctChange = prevExpenses > 0
              ? '${((diff / prevExpenses) * 100).toStringAsFixed(1)}%'
              : 'N/A';
          comparison = {
            'previousPeriodExpenses': prevExpenses,
            'difference': diff,
            'percentageChange': pctChange,
            'isSpendingMore': diff > 0,
          };
        }

        return {
          'currentBalance': controller.cashBalance,
          'totalIncome': totalIncome,
          'totalExpenses': totalExpenses,
          'netSavings': netSavings,
          'period': period,
          'categoryBreakdown': categoryBreakdown,
          'largestExpense': largestExp != null
              ? {
                  'title': largestExp.title,
                  'amount': largestExp.amount,
                  'tag': largestExp.tag,
                  'date': largestExp.date.toIso8601String().split('T')[0],
                }
              : null,
          'largestIncome': largestInc != null
              ? {
                  'title': largestInc.title,
                  'amount': largestInc.amount,
                  'tag': largestInc.tag,
                  'date': largestInc.date.toIso8601String().split('T')[0],
                }
              : null,
          'comparison': comparison,
          'transactionCount': currentPeriodList.length,
          'currency': controller.userProfile.value.currency,
        };

      case 'add_debt':
        final personName = args['personName'] as String? ?? 'Friend';
        final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
        final directionStr = args['direction'] as String? ?? 'theyOweMe';
        final direction = directionStr == 'iOweThem'
            ? DebtDirection.iOweThem
            : DebtDirection.theyOweMe;
        final title = args['title'] as String? ?? 'Loan';
        final note = args['note'] as String?;

        DateTime debtDate = DateTime.now();
        if (args['date'] != null) {
          try {
            debtDate = DateTime.parse(args['date'] as String);
          } catch (_) {}
        }

        await controller.addDebt(
          personName: personName,
          title: title,
          amount: amount,
          date: debtDate,
          direction: direction,
          note: note,
        );
        return {
          'success': true,
          'message': 'Debt recorded locally',
          'person': personName,
          'amount': amount,
          'direction': directionStr,
          'title': title,
          'currency': controller.userProfile.value.currency,
        };

      case 'record_debt_repayment':
        final personName = args['personName'] as String?;
        final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
        final debtId = args['debtId'] as String?;
        final note = args['note'] as String?;

        if (personName == null || personName.trim().isEmpty) {
          return {'success': false, 'message': 'Person name is required'};
        }

        final trimmedPerson = personName.trim().toLowerCase();
        DebtModel? targetDebt;

        if (debtId != null) {
          targetDebt = controller.debts.firstWhereOrNull((d) => d.id == debtId);
        } else {
          targetDebt = controller.debts.firstWhereOrNull(
            (d) =>
                d.personName.trim().toLowerCase() == trimmedPerson &&
                !d.isSettled,
          );
        }

        if (targetDebt != null) {
          await controller.recordRepayment(
            debtId: targetDebt.id,
            amount: amount,
            date: DateTime.now(),
            note: note,
          );
          final remaining = targetDebt.remainingAmount - amount;
          return {
            'success': true,
            'message':
                'Repayment of \$$amount recorded for ${targetDebt.personName}',
            'person': targetDebt.personName,
            'amount': amount,
            'remainingDebt': remaining > 0 ? remaining : 0.0,
            'isSettled': remaining <= 0,
            'currency': controller.userProfile.value.currency,
          };
        }

        return {
          'success': false,
          'message': 'No active unsettled debt found for $personName',
        };

      case 'get_debts_summary':
        final personName = args['personName'] as String?;
        final direction = args['direction'] as String? ?? 'all';
        final limit = (args['limit'] as num?)?.toInt() ?? 10;

        if (personName != null && personName.trim().isNotEmpty) {
          final summary = controller.getPersonSummary(personName);
          final ledger = controller.getPersonLedger(personName);

          return {
            'person': summary.name,
            'theyOweMe': summary.theyOweMe,
            'iOweThem': summary.iOweThem,
            'netBalance': summary.netBalance,
            'activeDebtsCount': summary.activeDebtsCount,
            'settledDebtsCount': summary.settledDebtsCount,
            'recentActivity': ledger
                .take(5)
                .map(
                  (item) => {
                    'title': item.title,
                    'amount': item.amount,
                    'date': item.date.toIso8601String().split('T')[0],
                    'type': item.type.name,
                  },
                )
                .toList(),
            'currency': controller.userProfile.value.currency,
          };
        }

        var debtsList = controller.debts.toList();
        if (direction == 'theyOweMe') {
          debtsList = debtsList.where((d) => d.isTheyOweMe).toList();
        } else if (direction == 'iOweThem') {
          debtsList = debtsList.where((d) => !d.isTheyOweMe).toList();
        }

        final peopleList = controller.peopleSummaries
            .map(
              (p) => {
                'name': p.name,
                'netBalance': p.netBalance,
                'theyOweMe': p.theyOweMe,
                'iOweThem': p.iOweThem,
                'activeDebts': p.activeDebtsCount,
              },
            )
            .toList();

        final recentDebts = debtsList
            .take(limit)
            .map(
              (d) => {
                'id': d.id,
                'personName': d.personName,
                'amount': d.amount,
                'remainingAmount': d.remainingAmount,
                'direction': d.isTheyOweMe ? 'theyOweMe' : 'iOweThem',
                'title': d.title,
                'isSettled': d.isSettled,
                'date': d.date.toIso8601String().split('T')[0],
              },
            )
            .toList();

        return {
          'totalReceivables': controller.totalOwedToMe,
          'totalPayables': controller.totalIOwe,
          'netDebt': controller.totalOwedToMe - controller.totalIOwe,
          'people': peopleList,
          'recentDebts': recentDebts,
          'currency': controller.userProfile.value.currency,
        };

      case 'delete_debt':
        final id = args['id'] as String?;
        final personName = (args['personName'] as String?)?.toLowerCase();
        final title = (args['title'] as String?)?.toLowerCase();
        final isAll =
            args['all'] == true ||
            args['all'] == 'true' ||
            personName == 'all' ||
            personName == 'everything';

        if (isAll) {
          final count = controller.debts.length;
          controller.debts.clear();
          await StorageService().saveDebts(controller.debts);
          return {
            'success': true,
            'message': 'Deleted all $count debt records',
            'deletedCount': count,
          };
        }

        DebtModel? match;
        if (id != null) {
          match = controller.debts.firstWhereOrNull((d) => d.id == id);
        } else if (personName != null) {
          match = controller.debts.firstWhereOrNull(
            (d) =>
                d.personName.toLowerCase().contains(personName) &&
                (title == null || d.title.toLowerCase().contains(title)),
          );
        }

        if (match != null) {
          await controller.deleteDebt(match.id);
          return {
            'success': true,
            'message': 'Deleted debt "${match.title}" with ${match.personName}',
          };
        }
        return {
          'success': false,
          'message': 'No matching debt found to delete',
        };

      default:
        return {'success': false, 'error': 'Unknown tool: $toolName'};
    }
  }
}
