import 'package:flutter/material.dart';

import '../../data/services/app_data.dart';
import '../../features/accounts/currency.dart';
import 'transaction_tile.dart';

/// ส่วน "รายการล่าสุด" — แสดงเป็นลิสต์เรียงต่อกันตามปกติ ไม่ซ้อนทับกันแบบกระดาษ
/// ใช้ร่วมกันทั้งหน้าแนะนำตัว (Intro) และหน้าหลัก (Dashboard)
/// ฟังก์ชันเหมือนเดิมทุกประการ: แตะ 2 ครั้ง = ทำรายการซ้ำ, กดค้าง = แก้ไข/ลบ
class RecentTransactionsSection extends StatelessWidget {
  final AppData data;
  static const int maxItems = 10;

  const RecentTransactionsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final recent = data.transactions.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'รายการล่าสุด',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: recent.isEmpty
              ? Center(
                  child: Text(
                    'ยังไม่มีรายการ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = recent[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: TransactionTile(
                        tx: tx,
                        accountName: tx.accountId != null
                            ? data.accountById(tx.accountId!).name
                            : 'ไม่ระบุบัญชี',
                        currency: tx.accountId != null
                            ? data.accountById(tx.accountId!).currency
                            : Currency.thb,
                        onRepeat: () {
                          data.repeatTransaction(tx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('บันทึกรายการซ้ำแล้ว')),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
