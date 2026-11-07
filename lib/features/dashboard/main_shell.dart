import 'package:flutter/material.dart';

import 'home_tab.dart';
import '../accounts/account_screen.dart';
import '../transactions/income_screen.dart';
import '../transactions/expense_screen.dart';
import '../portfolio/portfolio_screen.dart';

/// เชลล์หลักของแอป
///
/// แถบนำทางด้านล่างถูกเอาออกแล้วตามที่ผู้ใช้กำหนด — ย้ายเมนูขึ้นไปไว้กลางหน้าหลัก
/// (ถัดจากการ์ดยอดรวม) แทน ดูได้ที่ _ActionRow ใน home_tab.dart
///
/// ดัชนีแท็บยังคงเดิมทุกประการ เพื่อไม่ให้โค้ดส่วนที่เรียก onNavigate(i) เสียหาย:
/// 0=หน้าหลัก 1=บัญชี 2=รายรับ 3=รายจ่าย 4=ลงทุน
/// ใช้ IndexedStack เพื่อคงสถานะของแต่ละแท็บไว้เมื่อสลับไปมา
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // แท็บ "รายรับ"/"รายจ่าย" เป็นฟอร์มบันทึกรายการ (เหมือนเดิมของแอป)
  // เมื่อบันทึกสำเร็จแล้วให้พากลับมาที่ "หน้าหลัก" พร้อมแจ้งเตือน
  void _goHome({String? message}) {
    setState(() => _index = 0);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeTab(onNavigate: _goToTab),
      const AccountScreen(),
      IncomeScreen(onSaved: () => _goHome(message: 'บันทึกรายรับแล้ว')),
      ExpenseScreen(onSaved: () => _goHome(message: 'บันทึกรายจ่ายแล้ว')),
      const PortfolioScreen(),
    ];

    // เมื่อไม่ได้อยู่หน้าหลัก: ปุ่มย้อนกลับของเครื่องจะพากลับมาหน้าหลักก่อน
    // (แทนที่จะปิดแอปทันที) เพราะไม่มีแถบนำทางด้านล่างให้กดกลับแล้ว
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) _goHome();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: tabs),
      ),
    );
  }
}
