import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/services/app_data.dart';
import '../accounts/transaction_entry.dart';

class EditTransactionDialog extends StatefulWidget {
  final MoneyTransaction transaction;

  const EditTransactionDialog({super.key, required this.transaction});

  static Future<void> show(BuildContext context, MoneyTransaction transaction) {
    return showDialog(
      context: context,
      builder: (_) => EditTransactionDialog(transaction: transaction),
    );
  }

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _categoryCtrl;
  late DateTime _date;
  String? _satisfaction;

  static const _satisfactionLevels = ['😩', '😕', '😐', '🙂', '🤩'];

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.transaction.amount.toString());
    _noteCtrl = TextEditingController(text: widget.transaction.note ?? '');
    _categoryCtrl =
        TextEditingController(text: widget.transaction.category);
    _date = widget.transaction.date;
    _satisfaction = widget.transaction.satisfaction;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;

    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text);
    final category = _categoryCtrl.text.trim();

    if (amount == null || amount <= 0 || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ถูกต้อง')),
      );
      return;
    }

    context.read<AppData>().updateTransaction(
          widget.transaction.id,
          amount: amount,
          category: category,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          date: _date,
          satisfaction: widget.transaction.type == TransactionType.expense
              ? _satisfaction
              : null,
        );

    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายการ?'),
        content: const Text('รายการนี้จะถูกลบ และยอดบัญชีจะถูกปรับกลับอัตโนมัติ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<AppData>().deleteTransaction(widget.transaction.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.type == TransactionType.expense;

    return AlertDialog(
      title: Text(isExpense ? 'แก้ไขรายจ่าย' : 'แก้ไขรายรับ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน',
                prefixText: '฿ ',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'หมวดหมู่'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'บันทึกเพิ่มเติม'),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(DateFormat('d MMM y, HH:mm', 'th').format(_date)),
              subtitle: const Text('แตะเพื่อแก้วันและเวลา'),
              onTap: _pickDate,
            ),
            if (isExpense) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ความพึงพอใจ'),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _satisfactionLevels.map((emoji) {
                  final selected = _satisfaction == emoji;
                  return InkWell(
                    onTap: () => setState(
                      () => _satisfaction = selected ? null : emoji,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _delete,
          child: const Text('ลบ'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}