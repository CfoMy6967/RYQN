class AccountTransfer {
  final String id;
  String fromAccountId;
  String toAccountId;
  double amount;
  String? note;
  DateTime date;

  AccountTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory AccountTransfer.fromJson(Map<String, dynamic> json) =>
      AccountTransfer(
        id: json['id'] as String,
        fromAccountId: json['fromAccountId'] as String,
        toAccountId: json['toAccountId'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String),
      );
}