import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/accounts/transaction_entry.dart';
import '../../features/accounts/currency.dart';
import '../../features/transactions/edit_transaction_dialog.dart';

class TransactionTile extends StatelessWidget {
  final MoneyTransaction tx;
  final String accountName;

  /// สกุลเงินของบัญชีที่ผูกกับรายการนี้ (ใช้จัดรูปแบบยอดเงินให้ตรงกับบัญชีจริง)
  /// ถ้าไม่ระบุ (รายการยังไม่ผูกบัญชี) ค่าเริ่มต้นคือ THB
  final Currency currency;
  final VoidCallback? onRepeat;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.accountName,
    this.currency = Currency.thb,
    this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.redAccent;
    final amountText = formatCurrencyAmount(tx.amount, currency);

    return GestureDetector(
      onDoubleTap: onRepeat,
      onLongPress: () => EditTransactionDialog.show(context, tx),
      child: ListTile(
        // ไม่มีวงกลมไอคอนนำหน้าแล้ว — ดูชนิดรายการจากสี/เครื่องหมายของยอดเงินแทน
        // (ตามที่ผู้ใช้กำหนดในหน้า "รายการล่าสุด")
        title: Row(
          children: [
            Flexible(child: Text(tx.category)),
            if (tx.satisfaction != null) ...[
              const SizedBox(width: 6),
              Text(
                tx.satisfaction!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '$accountName · ${DateFormat('d MMM y, HH:mm', 'th').format(tx.date)}',
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}$amountText',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}