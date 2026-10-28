enum AiMessageRole { user, assistant, system }

class AiMessageModel {
  final String id;
  String text;
  final AiMessageRole role;
  final DateTime timestamp;
  String? toolExecuted;

  AiMessageModel({
    required this.id,
    required this.text,
    required this.role,
    DateTime? timestamp,
    this.toolExecuted,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == AiMessageRole.user;
  bool get isAssistant => role == AiMessageRole.assistant;

  void appendText(String delta) {
    text += delta;
  }

  void setToolExecuted(String tool) {
    toolExecuted = tool;
  }

  Map<String, dynamic> toHistoryMap() {
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': text,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
        'toolExecuted': toolExecuted,
      };

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String? ?? '',
      role: AiMessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => AiMessageRole.assistant,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      toolExecuted: json['toolExecuted'] as String?,
    );
  }
}

class AiChatSessionModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<AiMessageModel> messages;

  AiChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory AiChatSessionModel.fromJson(Map<String, dynamic> json) {
    return AiChatSessionModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Chat Session',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => AiMessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

