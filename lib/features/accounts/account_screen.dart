import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/services/app_data.dart';
import '../../shared/widgets/balance_visibility_toggle.dart';
import 'transaction_entry.dart';
import 'currency.dart';
import 'account.dart';

class AccountScreen extends StatefulWidget {
  final String? highlightTransactionId;

  const AccountScreen({super.key, this.highlightTransactionId});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _hoveredAccountId;

  // ควบคุมการเลื่อนลิสต์บัญชีอัตโนมัติ ตอนลากไอคอนรายการเข้าใกล้ขอบบน/ล่าง
  // (สำหรับกรณีมีบัญชีเยอะจนต้องเลื่อนจอเพื่อลากไปวางบัญชีที่อยู่ล่างสุด)
  final _accountsScrollController = ScrollController();
  Timer? _autoScrollTimer;

  void _startAutoScroll(bool toBottom) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_accountsScrollController.hasClients) return;
      final position = _accountsScrollController.position;
      final next = (position.pixels + (toBottom ? 8 : -8))
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      _accountsScrollController.jumpTo(next);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _accountsScrollController.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');
    Currency selectedCurrency = Currency.thb;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('เพิ่มบัญชี'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อบัญชี'),
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
                controller: balCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'ยอดเงินเริ่มต้น',
                  prefixText: '${selectedCurrency.symbol} ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final bal = double.tryParse(balCtrl.text) ?? 0;
                if (name.isNotEmpty && bal >= 0) {
                  context
                      .read<AppData>()
                      .addAccount(name, bal, selectedCurrency);
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

  void _showEditAccountDialog(BuildContext context, Account account) {
    final nameCtrl = TextEditingController(text: account.name);
    Currency selectedCurrency = account.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('แก้ไขบัญชี'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อบัญชี'),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                context.read<AppData>().updateAccount(
                      account.id,
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

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    Account account,
  ) async {
    final data = context.read<AppData>();
    final hasTransactions = data.transactions.any(
      (t) => t.accountId == account.id || t.toAccountId == account.id,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบบัญชี?'),
        content: Text(
          hasTransactions
              ? 'บัญชี "${account.name}" มีประวัติรายการอยู่ '
                  'รายการเหล่านั้นจะถูกเปลี่ยนเป็น "ไม่ระบุบัญชี" '
                  'แต่จะไม่ถูกลบ ต้องการดำเนินการต่อหรือไม่?'
              : 'บัญชี "${account.name}" จะถูกลบอย่างถาวร',
        ),
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

    if (ok == true) {
      data.deleteAccount(account.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบบัญชี "${account.name}" แล้ว')),
        );
      }
    }
  }

  /// เมนู "แก้ไขบัญชี / ลบบัญชี" — เปิดด้วยการกดค้างที่การ์ดบัญชี
  void _showAccountActions(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('แก้ไขบัญชี'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditAccountDialog(context, account);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('ลบบัญชี', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(context, account);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showTransferDialog(BuildContext context) async {
    final data = context.read<AppData>();
    if (data.accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ต้องมีอย่างน้อย 2 บัญชีก่อนจึงจะโอนเงินได้')),
      );
      return;
    }

    String fromId = data.accounts.first.id;
    String toId = data.accounts[1].id;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final from = data.accountById(fromId);
          final to = data.accountById(toId);
          final sameCurrency = from.currency == to.currency;

          final typedAmount = double.tryParse(amountCtrl.text);
          String? previewText;
          if (!sameCurrency && typedAmount != null && typedAmount > 0) {
            final sourceAmount = data.convert(
              typedAmount,
              to.currency,
              from.currency,
            );
            previewText =
                'หักจากบัญชีต้นทางประมาณ ${_fmtCurrency(sourceAmount, from.currency)}';
          }

          return AlertDialog(
            title: const Text('โอนเงินระหว่างบัญชี'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(fromId),
                    initialValue: fromId,
                    decoration: const InputDecoration(labelText: 'จากบัญชี'),
                    items: data.accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} (${_fmtCurrency(a.balance, a.currency)})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        fromId = v;
                        if (toId == fromId) {
                          toId = data.accounts.firstWhere((a) => a.id != fromId).id;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey(toId),
                    initialValue: toId,
                    decoration: const InputDecoration(labelText: 'ไปบัญชี'),
                    items: data.accounts
                        .where((a) => a.id != fromId)
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${a.currency.code})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => toId = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: sameCurrency
                          ? 'จำนวนเงิน'
                          : 'จำนวนที่บัญชีปลายทางจะได้รับ',
                      prefixText: '${to.currency.symbol} ',
                      helperText: previewText ??
                          'ยอดต้นทางคงเหลือ ${_fmtCurrency(from.balance, from.currency)}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'หมายเหตุ'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
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
                    data.addTransfer(
                      fromAccountId: fromId,
                      toAccountId: toId,
                      destAmount: amount,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('โอนเงินเรียบร้อยแล้ว')),
                    );
                  } on StateError catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text('โอนเงิน'),
              ),
            ],
          );
        },
      ),
    );

    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  /// แถบบางๆ ที่ขอบบน/ล่างของลิสต์บัญชี ใช้ตรวจจับการลากไอคอนเข้าใกล้ขอบ
  /// เพื่อเลื่อนลิสต์อัตโนมัติ (จำเป็นเมื่อมีบัญชีเยอะจนต้องเลื่อนจอ)
  /// โซนนี้ไม่รับการวางไอคอนโดยตรง (onWillAcceptWithDetails คืนค่า false เสมอ)
  /// มีหน้าที่แค่กระตุ้นให้ลิสต์เลื่อนเท่านั้น
  Widget _buildAutoScrollZone({required bool toBottom}) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        _startAutoScroll(toBottom);
        return false;
      },
      onLeave: (_) => _stopAutoScroll(),
      builder: (ctx, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return Container(
          height: 56,
          decoration: active
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: toBottom ? Alignment.bottomCenter : Alignment.topCenter,
                    end: toBottom ? Alignment.topCenter : Alignment.bottomCenter,
                    colors: [
                      Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  /// จัดรูปแบบยอดเงินตามสกุลเงินจริงของบัญชี (ไม่ใช้ ฿ ตายตัว)
  /// ทศนิยม 2 ตำแหน่งเสมอ เพื่อความแม่นยำของยอดเงิน
  String _fmtCurrency(double value, Currency currency) =>
      formatCurrencyAmount(value, currency);

  /// ชั้นไอคอนลอยกลางจอ — รายการที่บันทึกแล้วแต่ยังไม่ได้ผูกบัญชี
  ///
  /// ตามที่ผู้ใช้กำหนด:
  /// - ลอยอยู่กลางหน้าจอ ขนาดใหญ่ (4 เท่าของไอคอนปกติ) และโปร่งใส
  /// - ค้างอยู่จนกว่าผู้ใช้จะจัดการ (ไม่หายเอง)
  /// - ถ้าบันทึกหลายรายการติดกัน ไอคอนจะซ้อนกันได้
  /// - กดค้างที่ไอคอน = เปิดชีตเลือกบัญชีแบบอิสระ
  /// - ยังลากไปวางบนการ์ดบัญชีได้เหมือนเดิม
  Widget _buildFloatingUnassigned(
    BuildContext context,
    List<MoneyTransaction> list,
    NumberFormat fmt,
  ) {
    // ซ้อนกันแบบเหลื่อมทีละนิด ให้เห็นว่ามีหลายใบรออยู่
    const stepX = 26.0;
    const stepY = 18.0;
    const iconSize = 176.0;

    final count = list.length;
    final stackWidth = iconSize + stepX * (count - 1);
    final stackHeight = iconSize + stepY * (count - 1);

    return Center(
      child: SizedBox(
        width: stackWidth,
        height: stackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              Positioned(
                left: i * stepX,
                top: i * stepY,
                child: _FloatingTxIcon(
                  tx: list[i],
                  fmt: fmt,
                  // ใบล่าสุด (บันทึกทีหลังสุด) อยู่บนสุดของกอง
                  isTop: i == count - 1,
                  onLongPress: () => _showAccountPickerSheet(context, list[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ชีตเลือกบัญชีแบบอิสระ — เลื่อนขึ้นได้เกือบเต็มจอเพื่อแสดงบัญชีให้ได้มากที่สุด
  Future<void> _showAccountPickerSheet(
    BuildContext context,
    MoneyTransaction tx,
  ) async {
    final data = context.read<AppData>();

    if (data.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีบัญชี กดปุ่ม "เพิ่มบัญชี" ก่อน')),
      );
      return;
    }

    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.redAccent;

    final pickedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        // เปิดมาสูงเกือบเต็มจอทันที เพื่อให้เห็นบัญชีได้มากที่สุดในครั้งเดียว
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'เลือกบัญชีสำหรับรายการนี้',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        Text(
                          '${tx.category} · ${fmtAmountForSheet(tx.amount)}',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: data.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final a = data.accounts[i];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.account_balance_wallet),
                      ),
                      title: Text(a.name),
                      subtitle: Text(a.currency.code),
                      trailing: Text(
                        formatCurrencyAmount(a.balance, a.currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, a.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (pickedId == null || !mounted) return;

    final account = data.accountById(pickedId);
    data.moveTransactionToAccount(tx.id, pickedId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ผูก "${tx.category}" เข้าบัญชี "${account.name}" แล้ว'),
      ),
    );
  }

  /// จัดรูปแบบยอดเงินสำหรับหัวชีต (ยังไม่รู้บัญชี จึงแสดงเป็น THB ไปก่อน)
  String fmtAmountForSheet(double amount) =>
      formatCurrencyAmount(amount, Currency.thb);

  /// การ์ดบัญชีหนึ่งใบ (ใช้เป็นใบใน "กระดาษซ้อนกัน")
  /// รองรับการลาก-วางรายการที่ยังไม่ผูกบัญชีมาปล่อยใส่ได้เหมือนเดิม
  Widget _buildAccountCard(BuildContext context, AppData data, Account a) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _hoveredAccountId = a.id);
        return true;
      },
      onLeave: (_) {
        if (_hoveredAccountId == a.id) {
          setState(() => _hoveredAccountId = null);
        }
      },
      onAcceptWithDetails: (details) {
        final txId = details.data;
        final tx = data.transactions.firstWhere(
          (t) => t.id == txId,
        );

        data.moveTransactionToAccount(txId, a.id);
        setState(() => _hoveredAccountId = null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ย้าย "${tx.category}" ไปบัญชี "${a.name}" แล้ว',
            ),
          ),
        );

        // หมายเหตุ: ไม่ปิดหน้านี้อัตโนมัติอีกต่อไป
        // เพราะผู้ใช้อาจบันทึกหลายรายการติดกัน แล้วมีไอคอนซ้อนรออยู่หลายใบ
        // จึงปล่อยให้ผู้ใช้กดย้อนกลับเองเมื่อจัดการครบแล้ว
      },
      builder: (ctx, candidateData, rejectedData) {
        final isHovered =
            _hoveredAccountId == a.id && candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // เต็มความกว้างของจอ: ไม่มีขอบมน ใช้เส้นคั่นบน-ล่างแทนกรอบการ์ด
          width: double.infinity,
          decoration: BoxDecoration(
            color: isHovered
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: isHovered
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: isHovered ? 2 : 0.5,
              ),
              bottom: BorderSide(
                color: isHovered
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: isHovered ? 2 : 0.5,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const CircleAvatar(
                child: Icon(Icons.account_balance_wallet),
              ),
              title: Text(a.name),
              subtitle: Text(
                isHovered ? 'ปล่อยเพื่อผูกรายการนี้' : 'กดค้างเพื่อแก้ไข/ลบบัญชี',
              ),
              onLongPress: () => _showAccountActions(context, a),
              trailing: Text(
                _fmtCurrency(a.balance, a.currency),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final fmt =
        NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);
    final unassigned =
        data.transactions.where((t) => t.accountId == null).toList();
    final hasAccounts = data.accounts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.account_balance_wallet,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text('บัญชี'),
          ],
        ),
        actions: [
          // ปุ่มโอนเงิน — ย้ายมาไว้มุมบนขวาตามที่ผู้ใช้กำหนด
          IconButton(
            tooltip: 'โอนเงินระหว่างบัญชี',
            icon: ClipOval(
              child: Image.asset(
                'assets/images/transfer_icon.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            onPressed: () => _showTransferDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !hasAccounts
          // ยังไม่เคยมีบัญชี (ใช้ครั้งแรก): ปุ่มเพิ่มบัญชีอยู่กลางจอค่อนไปด้านบน
          ? _buildFirstTimeEmptyState(context)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'เงินในบัญชีทั้งหมด  '
                          '${data.balanceVisible ? fmt.format(data.totalBalance) : maskAmountText(fmt.format(data.totalBalance))}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      const BalanceVisibilityToggle(),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      ListView.separated(
                        controller: _accountsScrollController,
                        // เต็มความกว้าง: เหลือระยะขอบแนวนอนน้อยที่สุด
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        itemCount: data.accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) => _buildAccountCard(
                            context, data, data.accounts[index]),
                      ),
                      // โซนลากใกล้ขอบบน/ล่าง: ถ้ามีบัญชีเยอะจนล้นจอ
                      // ให้ลากไอคอนค้างไว้ตรงนี้เพื่อเลื่อนจอไปหาบัญชีล่างสุดได้
                      if (data.accounts.length > 3) ...[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildAutoScrollZone(toBottom: false),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildAutoScrollZone(toBottom: true),
                        ),
                      ],
                      // ไอคอนรายการที่ยังไม่ผูกบัญชี — ลอยกลางจอ ใหญ่ โปร่งใส
                      if (unassigned.isNotEmpty)
                        Positioned.fill(
                          child: _buildFloatingUnassigned(
                              context, unassigned, fmt),
                        ),
                    ],
                  ),
                ),
                // ปุ่มเพิ่มบัญชี — อยู่ด้านล่างตรงกลาง ใต้บัญชีที่บันทึกไว้แล้ว
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: () => _showAddDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('เพิ่มบัญชี'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// หน้าจอตอนยังไม่มีบัญชีเลย (ใช้งานครั้งแรก)
  /// ปุ่มเพิ่มบัญชีอยู่กลางหน้าจอค่อนไปด้านบน ตามที่ผู้ใช้กำหนด
  Widget _buildFirstTimeEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Spacer(flex: 2),
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 56,
          color: cs.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'ยังไม่มีบัญชี',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'เริ่มต้นด้วยการเพิ่มบัญชีแรกของคุณ เช่น เงินสด หรือบัญชีธนาคาร',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มบัญชี'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 48),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

/// ไอคอนรายการที่ยังไม่ผูกบัญชี — แบบลอยกลางจอ ขนาดใหญ่และโปร่งใส
///
/// ขนาด: วงกลมรัศมี 88 (ประมาณ 4 เท่าของไอคอนเดิมที่รัศมี 22)
/// โปร่งใส: opacity ~0.45 เพื่อให้ยังมองเห็นลิสต์บัญชีด้านหลังได้
/// กดค้าง: เปิดชีตเลือกบัญชี / ลาก: วางลงบนการ์ดบัญชีได้เหมือนเดิม
class _FloatingTxIcon extends StatelessWidget {
  final MoneyTransaction tx;
  final NumberFormat fmt;

  /// ใบบนสุดของกองจะทึบกว่าเล็กน้อย เพื่อให้รู้ว่าอันไหนจะถูกหยิบก่อน
  final bool isTop;
  final VoidCallback onLongPress;

  const _FloatingTxIcon({
    required this.tx,
    required this.fmt,
    required this.isTop,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.redAccent;

    final circle = Container(
      width: 176,
      height: 176,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 72,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              fmt.format(tx.amount),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              tx.category,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );

    // ใช้ Draggable (ไม่ใช่ LongPressDraggable) เพื่อไม่ให้ชนกับท่า "กดค้าง"
    // ที่ผู้ใช้กำหนดไว้ว่าต้องเปิดชีตเลือกบัญชี
    //   - ลากไอคอน  = วางลงบนการ์ดบัญชีได้เหมือนเดิม
    //   - กดค้าง    = เปิดชีตเลือกบัญชีแบบอิสระ
    return Opacity(
      opacity: isTop ? 0.55 : 0.35,
      child: Draggable<String>(
        data: tx.id,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.8, child: circle),
        ),
        childWhenDragging: Opacity(opacity: 0.15, child: circle),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: circle,
        ),
      ),
    );
  }
}
