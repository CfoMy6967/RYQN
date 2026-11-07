import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/app_data.dart';
import '../accounts/investment_account.dart';
import '../accounts/currency.dart';
import '../../shared/widgets/balance_visibility_toggle.dart';
import '../../shared/widgets/period_selector.dart';

/// หน้าพอร์ตการลงทุน — เพิ่มบัญชีลงทุน, บันทึกกำไร/ขาดทุน, ดูกราฟตามช่วงเวลา
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Period _period = Period.month;

  String _fmtCurrency(double value, Currency currency) => NumberFormat.currency(
        locale: 'th_TH',
        symbol: currency.symbol,
        decimalDigits: 2,
      ).format(value);

  void _showAddAccountDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController(text: '0');
    Currency selectedCurrency = Currency.thb;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('เพิ่มบัญชีลงทุน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อกองทุน/บัญชีลงทุน'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<Currency>(
                key: ValueKey(selectedCurrency),
                initialValue: selectedCurrency,
                decoration: const InputDecoration(labelText: 'สกุลเงิน'),
                items: Currency.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.symbol} ${c.code} · ${c.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedCurrency = v);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'จำนวนเงินลงทุนเริ่มต้น',
                  prefixText: '${selectedCurrency.symbol} ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amt = double.tryParse(amtCtrl.text) ?? 0;
                if (name.isNotEmpty) {
                  context.read<AppData>().addInvestmentAccount(
                        name,
                        amt,
                        selectedCurrency,
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(BuildContext context, InvestmentAccount inv) {
    final nameCtrl = TextEditingController(text: inv.name);
    Currency selectedCurrency = inv.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('แก้ไขบัญชีลงทุน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อกองทุน/บัญชีลงทุน'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<Currency>(
                key: ValueKey(selectedCurrency),
                initialValue: selectedCurrency,
                decoration: const InputDecoration(labelText: 'สกุลเงิน'),
                items: Currency.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.symbol} ${c.code} · ${c.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedCurrency = v);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                context.read<AppData>().updateInvestmentAccount(
                      inv.id,
                      name: name,
                      currency: selectedCurrency,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, InvestmentAccount inv) {
    final data = context.read<AppData>();

    if (data.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มบัญชีเงินก่อนถึงจะถอนเงินได้')),
      );
      return;
    }

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String targetAccountId = data.accounts.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final targetAccount = data.accountById(targetAccountId);
          final typedAmount = double.tryParse(amountCtrl.text);
          String? previewText;
          if (inv.currency != targetAccount.currency &&
              typedAmount != null &&
              typedAmount > 0) {
            final converted = data.convert(
              typedAmount,
              inv.currency,
              targetAccount.currency,
            );
            previewText =
                'เข้าบัญชีปลายทางประมาณ ${_fmtCurrency(converted, targetAccount.currency)}';
          }

          return AlertDialog(
            title: Text('ถอนเงินจาก ${inv.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'มูลค่าปัจจุบัน ${_fmtCurrency(inv.currentValue, inv.currency)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'จำนวนที่ถอน',
                      prefixText: '${inv.currency.symbol} ',
                      helperText: previewText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey(targetAccountId),
                    initialValue: targetAccountId,
                    decoration: const InputDecoration(labelText: 'เข้าบัญชี'),
                    items: data.accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${a.currency.code})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => targetAccountId = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'หมายเหตุ (ไม่บังคับ)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
              FilledButton.icon(
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('กรุณาใส่จำนวนเงินที่ถูกต้อง')),
                    );
                    return;
                  }

                  try {
                    data.withdrawFromInvestment(
                      inv.id,
                      targetAccountId,
                      amount,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ถอนเงินเรียบร้อยแล้ว')),
                    );
                  } on StateError catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                },
                icon: const Icon(Icons.call_made),
                label: const Text('ถอนเงิน'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, InvestmentAccount inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบบัญชีลงทุน?'),
        content: Text('บัญชีลงทุน "${inv.name}" และประวัติกำไร/ขาดทุนทั้งหมดจะถูกลบอย่างถาวร'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<AppData>().deleteInvestmentAccount(inv.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบบัญชีลงทุน "${inv.name}" แล้ว')),
      );
    }
  }

  void _showProfitLossDialog(BuildContext context, InvestmentAccount inv) {
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('บันทึกกำไร/ขาดทุน: ${inv.name}'),
        content: TextField(
          controller: amtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: 'จำนวนเงิน (ใส่ - หน้าตัวเลขถ้าขาดทุน)',
            prefixText: '${inv.currency.symbol} ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(amtCtrl.text);
              if (v != null) {
                context.read<AppData>().addProfitLoss(inv.id, v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final fmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('พอร์ตการลงทุน')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('มูลค่าพอร์ตรวม',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const BalanceVisibilityToggle(),
                    ],
                  ),
                  Text(
                    data.balanceVisible
                        ? fmt.format(data.totalPortfolioValue)
                        : maskAmountText(fmt.format(data.totalPortfolioValue)),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PeriodSelector(value: _period, onChanged: (p) => setState(() => _period = p)),
          SizedBox(
            height: 180,
            child: _PortfolioChart(investmentAccounts: data.investmentAccounts),
          ),
          const SizedBox(height: 12),
          if (data.investmentAccounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('ยังไม่มีบัญชีลงทุน กด + เพื่อเพิ่ม')),
            )
          else
            ...data.investmentAccounts.map((inv) {
              final pl = inv.totalProfitLoss;
              final color = pl >= 0 ? Colors.green : Colors.redAccent;
              return Card(
                child: ListTile(
                  onTap: () => _showProfitLossDialog(context, inv),
                  leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(Icons.show_chart, color: color)),
                  title: Text(inv.name),
                  subtitle: Text(
                    'ลงทุนเริ่มต้น ${_fmtCurrency(inv.initialAmount, inv.currency)} '
                    '(${inv.currency.code})',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_fmtCurrency(inv.currentValue, inv.currency),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${pl >= 0 ? '+' : ''}${_fmtCurrency(pl, inv.currency)}',
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'add') {
                            _showProfitLossDialog(context, inv);
                          } else if (value == 'withdraw') {
                            _showWithdrawDialog(context, inv);
                          } else if (value == 'edit') {
                            _showEditAccountDialog(context, inv);
                          } else if (value == 'delete') {
                            _confirmDeleteAccount(context, inv);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'add', child: Text('บันทึกกำไร/ขาดทุน')),
                          PopupMenuItem(value: 'withdraw', child: Text('ถอนเงินไปบัญชีอื่น')),
                          PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                          PopupMenuItem(value: 'delete', child: Text('ลบบัญชี')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// กราฟเส้นแสดงมูลค่าพอร์ตสะสม (แตะที่รายการเพื่อบันทึกกำไร/ขาดทุนเพิ่ม)
class _PortfolioChart extends StatelessWidget {
  final List<InvestmentAccount> investmentAccounts;
  const _PortfolioChart({required this.investmentAccounts});

  @override
  Widget build(BuildContext context) {
    if (investmentAccounts.isEmpty) return const SizedBox.shrink();

    final data = context.read<AppData>();

    // รวมรายการจากทุกบัญชี โดยแปลงเป็น THB ก่อน
    // เพื่อให้เทียบ/รวมกันได้ถูกต้องแม้บัญชีจะคนละสกุลเงิน
    final allEntries = <MapEntry<DateTime, double>>[];
    for (final inv in investmentAccounts) {
      for (final e in inv.entries) {
        allEntries.add(
          MapEntry(e.date, data.toThb(e.amount, inv.currency)),
        );
      }
    }
    allEntries.sort((a, b) => a.key.compareTo(b.key));

    final baseValue = investmentAccounts.fold(
      0.0,
      (s, i) => s + data.toThb(i.initialAmount, i.currency),
    );

    double running = baseValue;
    final spots = <FlSpot>[FlSpot(0, running)];
    for (int i = 0; i < allEntries.length; i++) {
      running += allEntries[i].value;
      spots.add(FlSpot((i + 1).toDouble(), running));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
