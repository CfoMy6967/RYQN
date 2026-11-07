import 'package:flutter/material.dart';
import '../../data/services/app_data.dart';

/// แถบเลือกช่วงเวลา: วัน / สัปดาห์ / เดือน / ปี / 3 ปี / ทั้งหมด
/// ใช้ในหน้าพอร์ตการลงทุน และหน้าบทวิเคราะห์ ตามที่ร่างไว้ในโน้ต (กล่องกราฟ)
class PeriodSelector extends StatelessWidget {
  final Period value;
  final ValueChanged<Period> onChanged;

  const PeriodSelector({super.key, required this.value, required this.onChanged});

  static const _labels = {
    Period.day: 'วัน',
    Period.week: 'สัปดาห์',
    Period.month: 'เดือน',
    Period.year: 'ปี',
    Period.threeYears: '3 ปี',
    Period.all: 'ทั้งหมด',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: Period.values.map((p) {
          final selected = p == value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(_labels[p]!),
              selected: selected,
              onSelected: (_) => onChanged(p),
            ),
          );
        }).toList(),
      ),
    );
  }
}
