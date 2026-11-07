import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_data.dart';
import '../../shared/theme/brand_colors.dart';
import '../../shared/widgets/balance_visibility_toggle.dart';
import '../../shared/widgets/recent_transactions_section.dart';
import '../accounts/currency.dart';
import '../analysis/analysis_screen.dart';

/// แท็บ "หน้าหลัก" — ออกแบบใหม่ตามชุดสี "ชุดที่ 2 สดใส อบอุ่น / ครีม ส้ม เขียว"
/// โครงสร้าง: แถบบน (โลโก้ + กระดิ่งแจ้งเตือน) > การ์ดยอดรวม (gradient ส้ม)
/// > การ์ดบัญชีย่อ > ปุ่มลัด 4 ปุ่ม (รายรับ/รายจ่าย/โอนเงิน/สรุป) > รายการล่าสุด
class HomeTab extends StatefulWidget {
  /// สลับไปแท็บอื่นในเชลล์หลัก (0=หน้าหลัก 1=บัญชี 2=รายรับ 3=รายจ่าย 4=ลงทุน)
  final ValueChanged<int> onNavigate;
  const HomeTab({super.key, required this.onNavigate});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName(AppData data) {
    if (_nameCtrl.text.trim().isEmpty) return;
    data.setUserName(_nameCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final hasName = data.userName != null && data.userName!.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: !hasName ? _WelcomeForm(nameCtrl: _nameCtrl, onSave: () => _saveName(data)) : _HomeContent(data: data, onNavigate: widget.onNavigate),
      ),
    );
  }
}

class _WelcomeForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final VoidCallback onSave;
  const _WelcomeForm({required this.nameCtrl, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.waving_hand, size: 40, color: Colors.amber),
            const SizedBox(height: 12),
            Text('สวัสดีค่ะ/ครับ ยินดีต้อนรับสู่ RYQN',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('ก่อนเริ่มใช้งาน ขอทราบชื่อของคุณหน่อยนะ',
                style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'ชื่อของคุณ', border: OutlineInputBorder()),
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onSave, child: const Text('บันทึกชื่อ')),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final AppData data;
  final ValueChanged<int> onNavigate;
  const _HomeContent({required this.data, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _TopBar(userName: data.userName)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BalanceCard(data: data),
                const SizedBox(height: 16),
                _AccountsRow(data: data, onNavigate: onNavigate),
                const SizedBox(height: 16),
                _ActionRow(onNavigate: onNavigate),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecentTransactionsSection(data: data),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String? userName;
  const _TopBar({this.userName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.account_balance_wallet, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('RYQN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (userName != null && userName!.trim().isNotEmpty)
                  Text('สวัสดี, $userName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'การแจ้งเตือน',
            icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('ยังไม่มีการแจ้งเตือนใหม่'))),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AppData data;
  const _BalanceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalText = data.balanceVisible
        ? formatCurrencyAmount(data.totalBalance, Currency.thb)
        : maskAmountText(formatCurrencyAmount(data.totalBalance, Currency.thb));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: BrandColors.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ยอดรวมทั้งหมด',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              BalanceVisibilityToggle(color: Colors.white.withValues(alpha: 0.9), size: 18),
              const Spacer(),
              const Icon(Icons.bar_chart_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            totalText,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AccountsRow extends StatelessWidget {
  final AppData data;
  final ValueChanged<int> onNavigate;
  const _AccountsRow({required this.data, required this.onNavigate});

  static const _icons = [Icons.account_balance_wallet_rounded, Icons.account_balance_rounded];

  @override
  Widget build(BuildContext context) {
    final accounts = data.accounts.take(2).toList();
    final cs = Theme.of(context).colorScheme;
    final colors = [cs.primary, cs.secondary];
    return Row(
      children: [
        for (var i = 0; i < accounts.length; i++) ...[
          Expanded(
            child: _AccountCard(
              icon: _icons[i % _icons.length],
              color: colors[i % colors.length],
              name: accounts[i].name,
              amount: formatCurrencyAmount(accounts[i].balance, accounts[i].currency),
              onTap: () => onNavigate(1),
            ),
          ),
          const SizedBox(width: 10),
        ],
        SizedBox(
          width: 56,
          height: 76,
          child: Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onNavigate(1),
              child: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// เล็ก ๆ ไว้เลือกสีส้ม/เขียวสลับกันสำหรับไอคอนบัญชี โดยอิงจาก ColorScheme ปัจจุบัน
// (เลือกใช้ colorScheme.primary / colorScheme.secondary สลับกันโดยตรงใน _AccountsRow แล้ว)

class _AccountCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String amount;
  final VoidCallback onTap;

  const _AccountCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 76,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(amount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// แถบเมนูหลัก 5 ปุ่ม — ย้ายขึ้นมาไว้กลางหน้าจอ ถัดจากการ์ดยอดรวม
/// (แทนแถบนำทางด้านล่างที่ถูกเอาออกไปแล้ว)
/// บัญชี / รายรับ / รายจ่าย / สรุป / ลงทุน
/// รายรับ / รายจ่าย / ลงทุน ใช้ภาพประกอบที่ผู้ใช้เตรียมไว้ (บัญชี/สรุป ยังใช้ไอคอนสำเร็จรูป)
class _ActionRow extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _ActionRow({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.account_balance_wallet_rounded,
            label: 'บัญชี',
            color: cs.primary,
            onTap: () => onNavigate(1),
          ),
        ),
        Expanded(
          child: _ActionButton(
            customImage:
                Image.asset('assets/images/income_icon.jpg', fit: BoxFit.cover),
            label: 'รายรับ',
            color: cs.secondary,
            onTap: () => onNavigate(2),
          ),
        ),
        Expanded(
          child: _ActionButton(
            customImage:
                Image.asset('assets/images/expenses_icon.jpg', fit: BoxFit.cover),
            label: 'รายจ่าย',
            color: cs.error,
            onTap: () => onNavigate(3),
          ),
        ),
        Expanded(
          child: _ActionButton(
            icon: Icons.pie_chart_rounded,
            label: 'สรุป',
            color: BrandColors.amber,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AnalysisScreen())),
          ),
        ),
        Expanded(
          child: _ActionButton(
            customImage:
                Image.asset('assets/images/investment_icon.jpg', fit: BoxFit.cover),
            label: 'ลงทุน',
            color: cs.secondary,
            onTap: () => onNavigate(4),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  /// ใช้เมื่อเป็นไอคอนสำเร็จรูปของ Material (จะย้อมสีขาวให้อัตโนมัติ)
  final IconData? icon;
  /// ใช้เมื่อเป็นรูปกำหนดเอง (เช่น Image.asset) ที่มีพื้นหลัง/วงกลมของตัวเองอยู่แล้ว
  final Widget? customImage;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    this.icon,
    this.customImage,
    required this.label,
    required this.color,
    required this.onTap,
  }) : assert(icon != null || customImage != null);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            customImage != null
                ? ClipOval(
                    child: SizedBox(width: 44, height: 44, child: customImage),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
