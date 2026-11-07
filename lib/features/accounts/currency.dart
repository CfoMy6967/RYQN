import 'package:intl/intl.dart';

enum Currency {
  thb,
  cny,
  usd,
}

extension CurrencyExtension on Currency {
  String get code {
    switch (this) {
      case Currency.thb:
        return 'THB';
      case Currency.cny:
        return 'CNY';
      case Currency.usd:
        return 'USD';
    }
  }

  String get symbol {
    switch (this) {
      case Currency.thb:
        return '฿';
      case Currency.cny:
        return '¥';
      case Currency.usd:
        return r'$';
    }
  }

  String get name {
    switch (this) {
      case Currency.thb:
        return 'Thai Baht';
      case Currency.cny:
        return 'Chinese Yuan';
      case Currency.usd:
        return 'US Dollar';
    }
  }

  static Currency fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'CNY':
        return Currency.cny;
      case 'USD':
        return Currency.usd;
      case 'THB':
      default:
        return Currency.thb;
    }
  }
}

/// จัดรูปแบบจำนวนเงินตาม "สกุลเงินของบัญชีนั้นๆ" เสมอ
/// เช่น บัญชีเงินหยวน -> แสดงเป็น ¥ ไม่ใช่ ฿
///
/// ทศนิยม 2 ตำแหน่งเสมอ เพื่อความแม่นยำของยอดเงิน
String formatCurrencyAmount(double value, Currency currency) {
  return NumberFormat.currency(
    locale: 'th_TH',
    symbol: currency.symbol,
    decimalDigits: 2,
  ).format(value);
}
