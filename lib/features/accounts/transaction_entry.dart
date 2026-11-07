enum TransactionType { income, expense, transfer }

class MoneyTransaction {
  final String id;

  String? accountId;
  String? toAccountId;

  double amount;

  /// จำนวนเงินที่เข้าบัญชีปลายทางสำหรับ transfer
  /// รายการเก่าจะเป็น null และใช้ amount แทน
  double? destAmount;

  String category;
  TransactionType type;
  String? note;
  DateTime date;
  String? satisfaction;

  MoneyTransaction({
    required this.id,
    this.accountId,
    this.toAccountId,
    required this.amount,
    this.destAmount,
    required this.category,
    required this.type,
    this.note,
    required this.date,
    this.satisfaction,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'destAmount': destAmount,
        'category': category,
        'type': type.name,
        'note': note,
        'date': date.toIso8601String(),
        'satisfaction': satisfaction,
      };

  factory MoneyTransaction.fromJson(
    Map<String, dynamic> json,
  ) {
    final typeName = json['type'] as String?;

    return MoneyTransaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      destAmount: (json['destAmount'] as num?)?.toDouble(),
      category: json['category'] as String? ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => TransactionType.expense,
      ),
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      satisfaction: json['satisfaction'] as String?,
    );
  }
}
