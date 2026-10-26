enum DebtDirection {
  theyOweMe,
  iOweThem;

  String get displayName =>
      this == DebtDirection.theyOweMe ? 'They owe me' : 'I owe them';
}

class DebtRepaymentModel {
  DebtRepaymentModel({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.affectsCashBalance = true,
    this.isSynced = false,
  });

  final String id;
  final double amount;
  final DateTime date;
  final String? note;
  final bool affectsCashBalance;
  final bool isSynced;

  DebtRepaymentModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? note,
    bool? affectsCashBalance,
    bool? isSynced,
  }) {
    return DebtRepaymentModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      affectsCashBalance: affectsCashBalance ?? this.affectsCashBalance,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'affectsCashBalance': affectsCashBalance,
      'isSynced': isSynced,
    };
  }

  factory DebtRepaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtRepaymentModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      affectsCashBalance: json['affectsCashBalance'] as bool? ?? true,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }
}

class DebtModel {
  DebtModel({
    required this.id,
    required this.personName,
    required this.title,
    required this.amount,
    required this.date,
    required this.direction,
    List<DebtRepaymentModel>? repayments,
    this.note,
    this.isSynced = false,
  }) : repayments = repayments ?? [];

  final String id;
  final String personName;
  final String title;
  final double amount;
  final DateTime date;
  final DebtDirection direction;
  final List<DebtRepaymentModel> repayments;
  final String? note;
  final bool isSynced;

  bool get isTheyOweMe => direction == DebtDirection.theyOweMe;
  bool get isIOweThem => direction == DebtDirection.iOweThem;

  double get totalRepaid =>
      repayments.fold(0.0, (sum, item) => sum + item.amount);

  double get remainingAmount => (amount - totalRepaid).clamp(0.0, double.infinity);

  bool get isSettled => remainingAmount <= 0.001;

  DebtModel copyWith({
    String? id,
    String? personName,
    String? title,
    double? amount,
    DateTime? date,
    DebtDirection? direction,
    List<DebtRepaymentModel>? repayments,
    String? note,
    bool? isSynced,
  }) {
    return DebtModel(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      direction: direction ?? this.direction,
      repayments: repayments ?? List.from(this.repayments),
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'direction': direction.name,
      'repayments': repayments.map((r) => r.toJson()).toList(),
      'note': note,
      'isSynced': isSynced,
    };
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      personName: json['personName'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      direction: (json['direction'] == 'theyOweMe' ||
              json['direction'] == 'LENT')
          ? DebtDirection.theyOweMe
          : DebtDirection.iOweThem,
      repayments: (json['repayments'] as List<dynamic>?)
              ?.map((item) =>
                  DebtRepaymentModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      note: json['note'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }
}
