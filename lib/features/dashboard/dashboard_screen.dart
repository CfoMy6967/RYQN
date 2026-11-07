import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/services/app_data.dart';
import '../../shared/widgets/recent_transactions_section.dart';
import '../accounts/account_screen.dart';
import '../transactions/income_screen.dart';
import '../transactions/expense_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../analysis/analysis_screen.dart';
import '../transactions/history_screen.dart';

/// หน้าหลัก — ศูนย์กลางนำทางไปยัง บัญชี / รายรับ / รายจ่าย / การลงทุน / บทวิเคราะห์ / ประวัติทั้งหมด
///
/// เข้าถึงได้โดยปัดซ้าย-ขวาต่อจากหน้าแนะนำตัว (IntroScreen)
/// ครึ่งบน: ไอคอนวงกลมนำทาง 6 รายการ
/// ครึ่งล่าง: รายการล่าสุดแบบกระดาษซ้อนกัน (เหมือนหน้าแนะนำตัว)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Future<void> _confirmExit(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากแอป'),
        content: const Text('คุณต้องการออกจากแอปใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ออก')),
        ],
      ),
    );
    if (ok == true) {
      SystemNavigator.pop();
    }
  }

  Future<void> _openIncome(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const IncomeScreen()),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกรายรับแล้ว')),
      );
    }
  }

  Future<void> _openExpense(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกรายจ่ายแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        actions: [
          IconButton(
            tooltip: 'ออกจากแอป',
            icon: const Icon(Icons.power_settings_new),
            onPressed: () => _confirmExit(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _CircleMenuButton(
                icon: Icons.account_balance_wallet,
                label: 'บัญชี',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AccountScreen())),
              ),
              _CircleMenuButton(
                customImage: Image.asset('assets/images/income_icon.jpg', fit: BoxFit.cover),
                label: 'รายรับ',
                color: Colors.green,
                onTap: () => _openIncome(context),
              ),
              _CircleMenuButton(
                icon: Icons.arrow_upward,
                label: 'รายจ่าย',
                color: Colors.redAccent,
                onTap: () => _openExpense(context),
              ),
              _CircleMenuButton(
                icon: Icons.show_chart,
                label: 'การลงทุน',
                color: Colors.indigo,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PortfolioScreen())),
              ),
              _CircleMenuButton(
                icon: Icons.pie_chart,
                label: 'บทวิเคราะห์',
                color: Colors.orange,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AnalysisScreen())),
              ),
              _CircleMenuButton(
                icon: Icons.history,
                label: 'ประวัติทั้งหมด',
                color: Colors.teal,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
            ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: RecentTransactionsSection(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleMenuButton extends StatelessWidget {
  /// ใช้เมื่อเป็นไอคอนสำเร็จรูปของ Material (จะย้อมสีตาม [color] ให้อัตโนมัติ)
  final IconData? icon;
  /// ใช้เมื่อเป็นรูปกำหนดเอง (เช่น Image.asset) ที่มีพื้นหลัง/วงกลมของตัวเองอยู่แล้ว
  final Widget? customImage;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _CircleMenuButton({
    this.icon,
    this.customImage,
    required this.label,
    required this.onTap,
    this.color,
  }) : assert(icon != null || customImage != null);

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          customImage != null
              ? ClipOval(
                  child: SizedBox(width: 56, height: 56, child: customImage),
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: c, size: 26),
                ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
