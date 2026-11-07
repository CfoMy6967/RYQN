import 'package:flutter/material.dart';
import '../accounts/transaction_entry.dart';
import 'transaction_form_screen.dart';

class ExpenseScreen extends StatelessWidget {
  final VoidCallback? onSaved;
  const ExpenseScreen({super.key, this.onSaved});
  @override
  Widget build(BuildContext context) =>
      TransactionFormScreen(type: TransactionType.expense, onSaved: onSaved);
}
