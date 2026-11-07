import 'currency.dart';

/// รายการกำไร/ขาดทุนของบัญชีลงทุน หนึ่งครั้ง (ค่าบวก = กำไร, ค่าลบ = ขาดทุน)
class ProfitLossEntry {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  ProfitLossEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory ProfitLossEntry.fromJson(Map<String, dynamic> json) => ProfitLossEntry(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}

/// บัญชี/พอร์ตการลงทุน หนึ่งกอง
/// อ้างอิงจากหน้า "พอร์ตการลงทุน" ในโน้ต: กด (+) เพิ่มบัญชี, มีกำไร/ขาดทุน, มีกราฟ
class InvestmentAccount {
  final String id;
  String name;
  double initialAmount;

  /// สกุลเงินของกองทุนนี้
  /// initialAmount และ entries ทั้งหมดเป็นหน่วยของสกุลเงินนี้
  Currency currency;

  final List<ProfitLossEntry> entries;

  InvestmentAccount({
    required this.id,
    required this.name,
    required this.initialAmount,
    this.currency = Currency.thb,
    List<ProfitLossEntry>? entries,
  }) : entries = entries ?? [];

  double get currentValue =>
      initialAmount + entries.fold(0.0, (s, e) => s + e.amount);

  double get totalProfitLoss => entries.fold(0.0, (s, e) => s + e.amount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initialAmount': initialAmount,
        'currency': currency.code,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory InvestmentAccount.fromJson(Map<String, dynamic> json) => InvestmentAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        initialAmount: (json['initialAmount'] as num).toDouble(),
        currency: CurrencyExtension.fromCode(json['currency'] as String?),
        entries: ((json['entries'] as List?) ?? const [])
            .map((e) => ProfitLossEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
