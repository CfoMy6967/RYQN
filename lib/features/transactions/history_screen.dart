import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_data.dart';
import '../accounts/transaction_entry.dart';
import '../accounts/currency.dart';
import 'edit_transaction_dialog.dart';

enum HistoryFilter { all, income, expense, transfer }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      DateFormat('d MMM y, HH:mm', 'th').format(value);

  bool _matches(String text, String query) =>
      query.isEmpty || text.toLowerCase().contains(query.toLowerCase());

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildEntryCard(_HistoryEntry entry, AppData data) {
    if (entry.transaction != null) {
      return _TransactionHistoryCard(
        transaction: entry.transaction!,
        appData: data,
        date: _date,
      );
    }
    return _TransferHistoryCard(
      transfer: entry.transfer!,
      appData: data,
      date: _date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final query = _searchController.text.trim();

    final transactions = data.transactions.where((t) {
      if (_filter == HistoryFilter.income &&
          t.type != TransactionType.income) {
        return false;
      }
      if (_filter == HistoryFilter.expense &&
          t.type != TransactionType.expense) {
        return false;
      }

      final accountName = t.accountId == null
          ? 'ไม่ระบุบัญชี'
          : data.accountById(t.accountId!).name;

      return _matches(
        '${t.category} ${t.note ?? ''} $accountName',
        query,
      );
    }).toList();

    final transfers = data.transfers.where((t) {
      if (_filter != HistoryFilter.all &&
          _filter != HistoryFilter.transfer) {
        return false;
      }

      final from = t.accountId == null
          ? 'ไม่ระบุบัญชี'
          : data.accountById(t.accountId!).name;
      final to = t.toAccountId == null
          ? 'ไม่ระบุบัญชี'
          : data.accountById(t.toAccountId!).name;

      return _matches(
        '$from $to ${t.note ?? ''}',
        query,
      );
    }).toList();

    final entries = <_HistoryEntry>[
      if (_filter == HistoryFilter.all ||
          _filter == HistoryFilter.income ||
          _filter == HistoryFilter.expense)
        ...transactions.map(_HistoryEntry.transaction),
      if (_filter == HistoryFilter.all ||
          _filter == HistoryFilter.transfer)
        ...transfers.map(_HistoryEntry.transfer),
    ];

    entries.sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final todayEntries =
        entries.where((e) => _isSameDay(e.date, now)).toList();

    const collapsedSheetHeight = 96.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติทั้งหมด'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาหมวดหมู่ บัญชี หรือหมายเหตุ',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('ทั้งหมด', HistoryFilter.all),
                    _filterChip('รายรับ', HistoryFilter.income),
                    _filterChip('รายจ่าย', HistoryFilter.expense),
                    _filterChip('โอนเงิน', HistoryFilter.transfer),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'วันนี้',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: todayEntries.isEmpty
                    ? const Center(
                        child: Text('ยังไม่มีรายการของวันนี้'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          collapsedSheetHeight + 16,
                        ),
                        itemCount: todayEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) =>
                            _buildEntryCard(todayEntries[index], data),
                      ),
              ),
            ],
          ),
          // ปัดขึ้นเพื่อดูประวัติทั้งหมด — แสดงเป็นลิสต์เรียงต่อกันตามปกติ ไม่ซ้อนทับกัน
          DraggableScrollableSheet(
            initialChildSize: 0.14,
            minChildSize: 0.14,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ปัดขึ้นเพื่อดูทั้งหมด (${entries.length} รายการ)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: entries.isEmpty
                          ? const Center(
                              child: Text('ยังไม่มีประวัติที่ตรงกับการค้นหา'),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) =>
                                  _buildEntryCard(entries[index], data),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, HistoryFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == filter,
        onSelected: (_) => setState(() => _filter = filter),
      ),
    );
  }
}

class _HistoryEntry {
  final DateTime date;
  final MoneyTransaction? transaction;
  final MoneyTransaction? transfer;

  const _HistoryEntry._({
    required this.date,
    this.transaction,
    this.transfer,
  });

  factory _HistoryEntry.transaction(MoneyTransaction value) =>
      _HistoryEntry._(date: value.date, transaction: value);

  factory _HistoryEntry.transfer(MoneyTransaction value) =>
      _HistoryEntry._(date: value.date, transfer: value);
}

class _TransactionHistoryCard extends StatelessWidget {
  final MoneyTransaction transaction;
  final AppData appData;
  final String Function(DateTime) date;

  const _TransactionHistoryCard({
    required this.transaction,
    required this.appData,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.redAccent;
    final account = appData.accountByIdOrNull(transaction.accountId);
    final accountName = account?.name ?? 'ยังไม่ผูกบัญชี';
    // ประวัติต้องเขียนด้วยสกุลเงินตามบัญชีนั้นจริงๆ
    // เช่น บัญชีเงินหยวน (CNY) ต้องแสดงเป็น ¥ ไม่ใช่ ฿
    final currency = account?.currency ?? Currency.thb;
    final amountText = formatCurrencyAmount(transaction.amount, currency);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () =>
            EditTransactionDialog.show(context, transaction),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            transaction.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (transaction.satisfaction != null) ...[
                          const SizedBox(width: 6),
                          Text(transaction.satisfaction!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${date(transaction.date)} · $accountName',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty)
                      Text(
                        transaction.note!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isIncome ? '+' : '-'}$amountText',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferHistoryCard extends StatelessWidget {
  final MoneyTransaction transfer;
  final AppData appData;
  final String Function(DateTime) date;

  const _TransferHistoryCard({
    required this.transfer,
    required this.appData,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final fromAccount = appData.accountByIdOrNull(transfer.accountId);
    final toAccount = appData.accountByIdOrNull(transfer.toAccountId);
    final fromName = fromAccount?.name ?? 'ไม่ระบุบัญชี';
    final toName = toAccount?.name ?? 'ไม่ระบุบัญชี';

    // ประวัติต้องเขียนด้วยสกุลเงินตามบัญชีนั้นจริงๆ
    // ต้นทาง/ปลายทางอาจเป็นคนละสกุลเงินกัน จึงต้องแยกแสดงทีละฝั่ง
    final fromCurrency = fromAccount?.currency ?? Currency.thb;
    final toCurrency = toAccount?.currency ?? Currency.thb;
    final received = transfer.destAmount ?? transfer.amount;

    final amountWidget = fromCurrency == toCurrency
        ? Text(
            formatCurrencyAmount(transfer.amount, fromCurrency),
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${formatCurrencyAmount(transfer.amount, fromCurrency)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
              Text(
                '+${formatCurrencyAmount(received, toCurrency)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
            ],
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.swap_horiz,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'โอนเงินระหว่างบัญชี',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$fromName → $toName',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${date(transfer.date)}'
                    '${transfer.note == null ? '' : ' · ${transfer.note}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            amountWidget,
          ],
        ),
      ),
    );
  }
}