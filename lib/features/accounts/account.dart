// บัญชี (Account)
// รองรับหลายสกุลเงิน โดยข้อมูลเก่าที่ไม่มี currency จะถือเป็น THB
import 'currency.dart';

class Account {
  final String id;
  String name;
  double balance;
  Currency currency;

  Account({
    required this.id,
    required this.name,
    this.balance = 0,
    this.currency = Currency.thb,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'currency': currency.code,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        currency: CurrencyExtension.fromCode(
          json['currency'] as String?,
        ),
      );
}
