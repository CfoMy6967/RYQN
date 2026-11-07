import 'package:flutter/material.dart';
import '../accounts/transaction_entry.dart';
import 'transaction_form_screen.dart';

class IncomeScreen extends StatelessWidget {
  final VoidCallback? onSaved;
  const IncomeScreen({super.key, this.onSaved});
  @override
  Widget build(BuildContext context) =>
      TransactionFormScreen(type: TransactionType.income, onSaved: onSaved);
}
