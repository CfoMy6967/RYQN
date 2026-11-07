import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_data.dart';
import '../../shared/widgets/balance_visibility_toggle.dart';
import '../../shared/widgets/recent_transactions_section.dart';
import '../accounts/account_screen.dart';
import '../accounts/currency.dart';
import '../transactions/income_screen.dart';
import '../transactions/expense_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../analysis/analysis_screen.dart';
import '../transactions/history_screen.dart';

/// หน้าแรกที่เปิดเจอตอนเข้าแอป
///
/// ครึ่งบน: ปัดซ้าย-ขวาสลับดู "โลโก้" <-> "หน้ารวม (ยอดเงินรวม + ไอคอนนำทาง)"
///          หน้ารวมนี้รวมของเดิม 2 หน้าเข้าด้วยกัน (ข้อมูลผู้ใช้/ยอดรวม + เมนูไอคอนของหน้าหลัก)
///          โดยยอดรวมอยู่มุมซ้ายบน (ชื่อ -> ยอดรวม) ส่วนไอคอนนำทางอยู่ถัดลงมา
/// ครึ่งล่าง: รายการล่าสุดแบบกระดาษซ้อนกัน (เหมือนเดิม)
/// มุมขวาล่าง: ปุ่มออกจากแอปขนาดเล็ก
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // เดิมหน้ายอดรวม (_UserInfoPage) กับหน้าไอคอนของหน้าหลัก (MainScreen)
                // แยกกันเป็นคนละหน้า ตอนนี้รวมเป็นหน้าเดียว (_HomePage) แล้ว
                // จึงให้พื้นที่ครึ่งบนมากขึ้น (flex: 3) เทียบกับรายการล่าสุดด้านล่าง (flex: 2)
                Expanded(
                  flex: 3,
                  child: PageView(
                    controller: _pageController,
                    children: [
                      const _LogoPage(),
                      _HomePage(data: data),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 48),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: RecentTransactionsSection(data: data),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                tooltip: 'ออกจากแอป',
                iconSize: 20,
                icon: const Icon(Icons.power_settings_new),
                color: Theme.of(context).colorScheme.outline,
                onPressed: () => _confirmExit(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPage extends StatelessWidget {
  const _LogoPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // โลโก้แอป (นกกลอสสีดำ-เทา-เงิน) แทนไอคอนเดิม
          SizedBox(
            height: 140,
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'บัญชีรายรับรายจ่าย',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'ปัดซ้าย-ขวาเพื่อดูข้อมูลของคุณ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

/// หน้ารวม (เดิมคือ _UserInfoPage + เมนูไอคอนของ MainScreen)
///
/// ตามคำขอ: ยอดรวมอยู่มุมซ้ายบน โดยมีชื่อผู้ใช้ก่อน ลงมาคือยอดรวม
/// ส่วนไอคอนนำทางไปหน้าต่างๆ อยู่ถัดลงมาเต็มพื้นที่ที่เหลือ
class _HomePage extends StatefulWidget {
  final AppData data;
  const _HomePage({required this.data});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.data.setUserName(_nameCtrl.text);
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
    final data = widget.data;
    final hasName = data.userName != null && data.userName!.trim().isNotEmpty;

    // ผู้ใช้ครั้งแรก (ยังไม่เคยตั้งชื่อ) -> ถามชื่อก่อน ยังไม่แสดงยอดรวม/เมนู
    if (!hasName) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.waving_hand, size: 40, color: Colors.amber),
              const SizedBox(height: 12),
              Text(
                'สวัสดีค่ะ/ครับ ยินดีต้อนรับ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'ก่อนเริ่มใช้งาน ขอทราบชื่อของคุณหน่อยนะ',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'ชื่อของคุณ',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saveName,
                child: const Text('บันทึกชื่อ'),
              ),
            ],
          ),
        ),
      );
    }

    // ยอดรวมทุกบัญชี รวมเป็น THB เสมอ (ทุกบัญชีถูกแปลงมาก่อนรวม)
    final totalText = data.balanceVisible
        ? formatCurrencyAmount(data.totalBalance, Currency.thb)
        : maskAmountText(formatCurrencyAmount(data.totalBalance, Currency.thb));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----- มุมซ้ายบน: ชื่อผู้ใช้ ลงมาคือยอดรวม -----
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  data.userName!.trim().substring(0, 1).toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'สวัสดี, ${data.userName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            totalText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const BalanceVisibilityToggle(size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ----- ไอคอนนำทางไปหน้าต่างๆ (ย้ายมารวมจากหน้าหลักเดิม) -----
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.95,
              children: [
                _CircleMenuButton(
                  icon: Icons.account_balance_wallet,
                  label: 'บัญชี',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AccountScreen())),
                ),
                _CircleMenuButton(
                  icon: Icons.arrow_downward,
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
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const PortfolioScreen())),
                ),
                _CircleMenuButton(
                  icon: Icons.pie_chart,
                  label: 'บทวิเคราะห์',
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AnalysisScreen())),
                ),
                _CircleMenuButton(
                  icon: Icons.history,
                  label: 'ประวัติทั้งหมด',
                  color: Theme.of(context).colorScheme.outline,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ปุ่มเมนูไอคอนวงกลม (ย้ายมาจากหน้าหลักเดิม dashboard_screen.dart)
class _CircleMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _CircleMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
