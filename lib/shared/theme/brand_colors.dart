import 'package:flutter/material.dart';

/// โทนสีของแอป "ชุดที่ 2 — สดใส อบอุ่น / ครีม ส้ม เขียว"
/// สัดส่วนสี (โดยประมาณ): ส้ม/เหลือง 50% (สีหลัก) · เขียว 20% (สีรอง) ·
/// ครีม/ขาว 30% (พื้นหลัง/พื้นผิว) เพื่อให้ดูสดใส เป็นมิตร สบายตา
/// หมายเหตุ: สีเชิงความหมาย เช่น เขียว=รายรับ, แดง=รายจ่าย ในแต่ละหน้า ยังคงไว้ตามเดิม
class BrandColors {
  BrandColors._();

  // ---- ส้ม (สีหลัก) ----
  static const primary = Color(0xFFE07B3E); // ส้มเข้ม (หัวการ์ดยอดรวม)
  static const primaryLight = Color(0xFFF2A661); // ส้มอ่อน (ปลาย gradient)
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFF6E4CE); // ครีม
  static const onPrimaryContainer = Color(0xFF8A4A1E);

  // ---- เขียว (สีรอง) ----
  static const secondary = Color(0xFF6B8E5A); // เขียวเข้ม
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFDCE8D0); // เขียวอ่อน
  static const onSecondaryContainer = Color(0xFF3D5730);

  // ---- ครีม/น้ำตาลอ่อน (สีเสริม) ----
  static const tertiary = Color(0xFFB98A5E);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFF3E3D3); // ครีม
  static const onTertiaryContainer = Color(0xFF5C3F26);

  static const surface = Color(0xFFFFFBF5); // ขาวอมครีม
  static const onSurface = Color(0xFF2E241C);
  static const surfaceContainerHighest = Color(0xFFF3E9DC);

  static const outline = Color(0xFF9C8B78);
  static const outlineVariant = Color(0xFFE3D5C2);

  static const error = Color(0xFFD9534F);
  static const onError = Color(0xFFFFFFFF);

  /// สีเหลือง/อำพันสำหรับปุ่ม "โอนเงิน" (ให้ต่างจากส้มหลักเล็กน้อย ตามแบบ)
  static const amber = Color(0xFFE3A93B);

  /// Gradient หลักของแบรนด์ (การ์ดยอดรวม ฯลฯ)
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}
