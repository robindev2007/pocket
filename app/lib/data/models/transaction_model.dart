enum TransactionType {
  income,
  expense;

  String get displayName => this == TransactionType.income ? 'Income' : 'Expense';
}

class TransactionModel {
  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.tag,
    this.note,
    this.isSynced = false,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? tag;
  final String? note;
  final bool isSynced;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? tag,
    String? note,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      tag: tag ?? this.tag,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'tag': tag,
      'note': note,
      'isSynced': isSynced,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: (json['type']?.toString().toUpperCase() == 'INCOME')
          ? TransactionType.income
          : TransactionType.expense,
      date: DateTime.parse(json['date'] as String),
      tag: json['tag'] as String?,
      note: json['note'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }
}
