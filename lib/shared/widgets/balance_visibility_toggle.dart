import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_data.dart';

/// แปลงข้อความจำนวนเงินที่ format แล้ว (เช่น "฿12,345.00") ให้เป็น "*" ซ่อนตัวเลข
/// โดยยังคงสัญลักษณ์สกุลเงิน/เครื่องหมายคั่นไว้ (เช่น "฿**,***.**")
String maskAmountText(String formatted) =>
    formatted.replaceAll(RegExp(r'[0-9]'), '*');

/// ปุ่มไอคอนรูปตา สำหรับเปิด/ปิดการมองเห็น "ยอดรวม" ทั้งแอป
/// ใช้ค่าเดียวกันจาก AppData.balanceVisible (สลับที่ไหนก็มีผลทุกหน้า) และค่านี้ถูกบันทึกไว้ด้วย
class BalanceVisibilityToggle extends StatelessWidget {
  final Color? color;
  final double size;

  const BalanceVisibilityToggle({super.key, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final visible = context.watch<AppData>().balanceVisible;
    return IconButton(
      tooltip: visible ? 'ซ่อนยอดรวม' : 'แสดงยอดรวม',
      visualDensity: VisualDensity.compact,
      icon: Icon(
        visible ? Icons.visibility : Icons.visibility_off,
        size: size,
        color: color,
      ),
      onPressed: () => context.read<AppData>().toggleBalanceVisibility(),
    );
  }
}
