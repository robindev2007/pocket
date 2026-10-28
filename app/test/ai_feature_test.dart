import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manage_money/core/theme/theme.dart';
import 'package:manage_money/data/models/debt_model.dart';
import 'package:manage_money/data/models/transaction_model.dart';
import 'package:manage_money/data/services/ai_api_service.dart';
import 'package:manage_money/data/services/storage_service.dart';
import 'package:manage_money/features/ai/controllers/ai_controller.dart';
import 'package:manage_money/features/ai/models/ai_message_model.dart';
import 'package:manage_money/features/ai/presentation/screens/ai_chat_screen.dart';
import 'package:manage_money/features/ai/presentation/widgets/ai_assistant_sheet.dart';
import 'package:manage_money/features/tracker/tracker.dart';

class MockAiApiService extends AiApiService {
  Map<String, dynamic>? mockResponse;
  List<Map<String, dynamic>>? mockStreamChunks;
  Map<String, dynamic>? lastSentToolResult;
  String? lastSentProvider;
  Map<String, dynamic>? lastSentUserContext;

  @override
  Stream<Map<String, dynamic>> sendChatStream({
    String? message,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? toolResult,
    String? provider,
    String? token,
    Map<String, dynamic>? userContext,
  }) async* {
    lastSentProvider = provider;
    lastSentToolResult = toolResult;
    lastSentUserContext = userContext;

    if (toolResult != null) {
      yield {
        'type': 'delta',
        'text': 'Successfully executed ${toolResult['name']}.',
      };
      yield {'type': 'done'};
      return;
    }

    if (mockStreamChunks != null) {
      for (final chunk in mockStreamChunks!) {
        yield chunk;
      }
    } else if (mockResponse != null) {
      yield mockResponse!;
    }
  }

  @override
  Future<Map<String, dynamic>?> sendChat({
    String? message,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? toolResult,
    String? provider,
    String? token,
    Map<String, dynamic>? userContext,
  }) async {
    lastSentProvider = provider;
    lastSentToolResult = toolResult;
    lastSentUserContext = userContext;

    if (toolResult != null) {
      return {
        'type': 'text',
        'message': 'Successfully executed ${toolResult['name']}.',
        'provider': provider ?? 'gemini',
      };
    }
    return mockResponse;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
    Get.put(ThemeController());
    Get.put(TrackerController());
  });

  test('AiController executes add_transaction tool locally and updates TrackerController', () async {
    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'add_transaction',
        'arguments': {
          'title': 'Dinner with Alex',
          'amount': 45.0,
          'type': 'expense',
          'tag': 'Food',
        },
      },
      'provider': 'gemini',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    final tracker = TrackerController.to;
    expect(tracker.transactions.isEmpty, true);

    await aiController.sendMessage('I spent 45 on dinner');

    // Verify local tool executed
    expect(tracker.transactions.length, 1);
    expect(tracker.transactions.first.title, 'Dinner with Alex');
    expect(tracker.transactions.first.amount, 45.0);
    expect(tracker.transactions.first.tag, 'Food');

    // Verify assistant responded
    expect(aiController.messages.last.text, 'Successfully executed add_transaction.');
  });

  test('AiController executes delete_transaction tool locally', () async {
    final tracker = TrackerController.to;
    await tracker.addTransaction(
      title: 'Gym membership',
      amount: 50.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      tag: 'Health',
    );
    expect(tracker.transactions.length, 1);

    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'delete_transaction',
        'arguments': {
          'query': 'Gym',
        },
      },
      'provider': 'openrouter',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    aiController.setProvider('openrouter');

    await aiController.sendMessage('Delete my gym transaction');

    // Verify deleted locally
    expect(tracker.transactions.isEmpty, true);
    expect(mockService.lastSentProvider, 'openrouter');
  });

  test('AiController executes add_debt tool locally', () async {
    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'add_debt',
        'arguments': {
          'personName': 'Sara',
          'amount': 30.0,
          'direction': 'theyOweMe',
          'title': 'Coffee and cake',
        },
      },
      'provider': 'gemini',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    final tracker = TrackerController.to;
    expect(tracker.debts.isEmpty, true);

    await aiController.sendMessage('I lent Sara 30 for coffee');

    expect(tracker.debts.length, 1);
    expect(tracker.debts.first.personName, 'Sara');
    expect(tracker.debts.first.amount, 30.0);
  });

  testWidgets('AiAssistantSheet renders UI and switches providers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'text',
      'message': 'Here is your financial advice.',
      'provider': 'gemini',
    };
    Get.put(AiController(apiService: mockService));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AiAssistantSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Gemini'), findsOneWidget);

    // Tap model header to open model selector bottom sheet
    await tester.tap(find.text('AI Assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Select AI Model'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);

    // Switch to OpenRouter
    await tester.tap(find.text('OpenRouter'));
    await tester.pumpAndSettle();
    expect(AiController.to.selectedProvider.value, 'openrouter');

    // Switch back to Gemini
    await tester.tap(find.text('AI Assistant'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Google Gemini'));
    await tester.pumpAndSettle();
    expect(AiController.to.selectedProvider.value, 'gemini');
  });

  test('AiController streams tokens progressively into message bubble', () async {
    final mockService = MockAiApiService();
    mockService.mockStreamChunks = [
      {'type': 'delta', 'text': 'Here '},
      {'type': 'delta', 'text': 'is '},
      {'type': 'delta', 'text': 'your '},
      {'type': 'delta', 'text': 'analysis.'},
      {'type': 'done'},
    ];

    final aiController = Get.put(AiController(apiService: mockService));
    await aiController.sendMessage('Analyze my budget');

    expect(aiController.messages.last.text, 'Here is your analysis.');
  });

  testWidgets('AiAssistantSheet renders markdown in assistant bubbles', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockService = MockAiApiService();
    final aiController = Get.put(AiController(apiService: mockService));
    aiController.messages.add(
      AiMessageModel(
        id: 'msg_1',
        text: '### Spending Summary\n* **Food**: \$45\n* `code block`',
        role: AiMessageRole.assistant,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AiAssistantSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify markdown widgets render
    expect(find.textContaining('Spending Summary'), findsWidgets);
  });

  test('AiController executes get_transactions tool to answer last expense queries', () async {
    final tracker = TrackerController.to;
    await tracker.addTransaction(
      title: 'Groceries store',
      amount: 62.50,
      type: TransactionType.expense,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      tag: 'Groceries',
    );
    await tracker.addTransaction(
      title: 'Coffee shop',
      amount: 4.75,
      type: TransactionType.expense,
      date: DateTime.now(),
      tag: 'Food',
    );

    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'get_transactions',
        'arguments': {
          'type': 'expense',
          'limit': 1,
          'sort': 'date_desc',
        },
      },
      'provider': 'gemini',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    await aiController.sendMessage('What was my last expense?');

    expect(mockService.lastSentToolResult, isNotNull);
    final result = mockService.lastSentToolResult!['result'] as Map<String, dynamic>;
    final list = result['transactions'] as List;
    expect(list.length, 1);
    expect(list.first['title'], 'Coffee shop');
    expect(list.first['amount'], 4.75);
  });

  test('AiController executes get_financial_summary tool and calculates net cash flow', () async {
    final tracker = TrackerController.to;
    await tracker.addTransaction(
      title: 'Client Payment',
      amount: 1500.0,
      type: TransactionType.income,
      date: DateTime.now(),
      tag: 'Freelance',
    );
    await tracker.addTransaction(
      title: 'Electricity Bill',
      amount: 200.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      tag: 'Bills',
    );

    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'get_financial_summary',
        'arguments': {
          'period': 'this_month',
        },
      },
      'provider': 'gemini',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    await aiController.sendMessage('Give me a financial summary for this month');

    final result = mockService.lastSentToolResult!['result'] as Map<String, dynamic>;
    expect(result['totalIncome'], 1500.0);
    expect(result['totalExpenses'], 200.0);
    expect(result['netSavings'], 1300.0);
    expect(result['currentBalance'], 1300.0);
  });

  test('AiController executes record_debt_repayment tool and updates loan remaining balance', () async {
    final tracker = TrackerController.to;
    await tracker.addDebt(
      personName: 'Rahim',
      title: 'Dinner loan',
      amount: 1000.0,
      date: DateTime.now(),
      direction: DebtDirection.theyOweMe,
    );

    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'record_debt_repayment',
        'arguments': {
          'personName': 'Rahim',
          'amount': 400.0,
        },
      },
      'provider': 'gemini',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    await aiController.sendMessage('Rahim paid me 400');

    expect(tracker.debts.first.repayments.length, 1);
    expect(tracker.debts.first.remainingAmount, 600.0);
    final result = mockService.lastSentToolResult!['result'] as Map<String, dynamic>;
    expect(result['success'], true);
    expect(result['remainingDebt'], 600.0);
  });

  test('AiController executes update_transaction tool to edit existing transaction', () async {
    final tracker = TrackerController.to;
    await tracker.addTransaction(
      title: 'Quick snack',
      amount: 10.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      tag: 'Food',
    );

    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'update_transaction',
        'arguments': {
          'searchQuery': 'Quick snack',
          'amount': 15.0,
          'title': 'Lunch combo',
        },
      },
      'provider': 'gemini',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    await aiController.sendMessage('Change quick snack to Lunch combo of 15');

    expect(tracker.transactions.first.title, 'Lunch combo');
    expect(tracker.transactions.first.amount, 15.0);
  });

  test('AiController executes delete_transaction with all: true to clear all transactions', () async {
    final tracker = TrackerController.to;
    await tracker.addTransaction(
      title: 'T1',
      amount: 10.0,
      type: TransactionType.expense,
      date: DateTime.now(),
    );
    await tracker.addTransaction(
      title: 'T2',
      amount: 20.0,
      type: TransactionType.expense,
      date: DateTime.now(),
    );
    expect(tracker.transactions.length, 2);

    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'tool_call',
      'toolCall': {
        'name': 'delete_transaction',
        'arguments': {
          'all': 'true',
        },
      },
      'provider': 'gemini',
    };

    final aiController = Get.put(AiController(apiService: mockService));
    await aiController.sendMessage('Delete all transactions');

    expect(tracker.transactions.isEmpty, true);
    final result = mockService.lastSentToolResult!['result'] as Map<String, dynamic>;
    expect(result['success'], true);
    expect(result['deletedCount'], 2);
  });

  testWidgets('AiChatScreen displays Chat and History tabs and resumes session', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockService = MockAiApiService();
    final aiController = Get.put(AiController(apiService: mockService));

    final session = AiChatSessionModel(
      id: 'session_1',
      title: 'Lunch query',
      createdAt: DateTime.now(),
      messages: [
        AiMessageModel(id: 'm1', text: 'How much was lunch?', role: AiMessageRole.user),
        AiMessageModel(id: 'm2', text: 'Lunch was \$15.', role: AiMessageRole.assistant),
      ],
    );
    await StorageService().saveChatSessions([session]);
    await aiController.loadChatSessions();

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const AiChatScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.history_rounded), findsOneWidget);

    // Open History drawer
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Chat History'), findsOneWidget);
    expect(find.text('Lunch query'), findsOneWidget);
    expect(find.textContaining('2 msgs'), findsOneWidget);

    // Tap session to resume it
    await tester.tap(find.text('Lunch query'));
    await tester.pumpAndSettle();

    // Verify resumed messages in conversation
    expect(find.text('How much was lunch?'), findsOneWidget);
    expect(find.text('Lunch was \$15.'), findsOneWidget);
  });

  testWidgets('AiChatScreen renders TypingDotsIndicator when assistant message text is empty', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockService = MockAiApiService();
    final aiController = Get.put(AiController(apiService: mockService));
    aiController.messages.add(
      AiMessageModel(id: 'waiting_msg', text: '', role: AiMessageRole.assistant),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const AiChatScreen(),
      ),
    );
    await tester.pump();

    expect(find.byType(TypingDotsIndicator), findsOneWidget);
  });

  test('AiController passes user context (name, email, currency, login/sync) to AiApiService', () async {
    final mockService = MockAiApiService();
    mockService.mockResponse = {
      'type': 'text',
      'message': 'Hello Alice! I see you are using USD.',
      'provider': 'gemini',
    };

    final trackerController = TrackerController.to;
    trackerController.userProfile.value = trackerController.userProfile.value.copyWith(
      name: 'Alice',
      email: 'alice@example.com',
      currency: 'USD',
    );

    final aiController = Get.put(AiController(apiService: mockService));
    await aiController.sendMessage('Hello');

    expect(mockService.lastSentUserContext, isNotNull);
    expect(mockService.lastSentUserContext!['name'], 'Alice');
    expect(mockService.lastSentUserContext!['email'], 'alice@example.com');
    expect(mockService.lastSentUserContext!['currency'], 'USD');
    expect(mockService.lastSentUserContext!.containsKey('isLoggedIn'), isTrue);
    expect(mockService.lastSentUserContext!.containsKey('autoSyncEnabled'), isTrue);
  });
}

