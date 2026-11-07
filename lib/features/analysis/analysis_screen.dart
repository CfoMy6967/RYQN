import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/app_data.dart';

/// หน้าสรุป — สรุปรายรับ/รายจ่าย และกราฟวงกลมแยกตามหมวดหมู่
///
/// เลือกดูได้ 2 แบบ:
/// 1) ช่วงสำเร็จรูป: วัน / สัปดาห์ / เดือน / ปี
/// 2) ค้นหาเอง: เลือกวันที่เริ่ม-สิ้นสุด (วันที่ เดือน ปี ค.ศ.)
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  /// ช่วงสำเร็จรูปที่เลือกอยู่ (null = กำลังใช้ช่วงวันที่ที่ค้นหาเอง)
  Period? _period = Period.month;

  /// ช่วงวันที่ที่ผู้ใช้เลือกเอง
  DateTime? _customStart;
  DateTime? _customEnd;

  static const _palette = [
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
    Colors.cyan,
  ];

  /// ช่วงสำเร็จรูปที่ให้เลือก — ตามที่ผู้ใช้กำหนด: วัน เดือน สัปดาห์ ปี
  static const _quickPeriods = {
    Period.day: 'วัน',
    Period.week: 'สัปดาห์',
    Period.month: 'เดือน',
    Period.year: 'ปี',
  };

  bool get _isCustom => _period == null;

  /// เปิดตัวเลือกช่วงวันที่แบบกำหนดเอง — จบในหน้าเดียว (ไม่มีขั้นตอนกรอกวันที่
  /// เป็นตัวเลขแยกต่างหากแบบ dialog ของ Flutter) แตะวันเริ่ม แตะวันสิ้นสุด
  /// แล้วปิดให้เองอัตโนมัติ ปฏิทินใช้ปี ค.ศ. เสมอตามที่ผู้ใช้กำหนด
  Future<void> _pickCustomRange() async {
    final result = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _SingleScreenRangePicker(
        initialStart: _customStart,
        initialEnd: _customEnd,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _customStart = result.start;
      _customEnd = result.end;
      _period = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final fmt =
        NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);
    final dFmt = DateFormat('d MMM y', 'en');

    // คำนวณตัวเลขตามโหมดที่เลือกอยู่
    final double income;
    final double expense;
    final Map<String, double> byCategory;

    if (_isCustom && _customStart != null && _customEnd != null) {
      income = data.incomeBetween(_customStart!, _customEnd!);
      expense = data.expenseBetween(_customStart!, _customEnd!);
      byCategory =
          data.expenseByCategoryBetween(_customStart!, _customEnd!);
    } else {
      final p = _period ?? Period.month;
      income = data.incomeInPeriod(p);
      expense = data.expenseInPeriod(p);
      byCategory = data.expenseByCategory(p);
    }

    final total = byCategory.values.fold(0.0, (s, v) => s + v);
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('สรุป')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- ไอคอนปฏิทิน (ค้นหาเอง) + ช่วงสำเร็จรูป: วัน / สัปดาห์ / เดือน / ปี ----
          // ไอคอนปฏิทินอยู่หน้าสุดของแถว ก่อนปุ่ม "วัน"
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Tooltip(
                message:
                    'ค้นหาตามวันที่\nเลือกวันเริ่มต้น-สิ้นสุดเอง (ปี ค.ศ.) '
                    'จบในหน้าเดียว ไม่ต้องพิมพ์ตัวเลขปี',
                child: InkWell(
                  onTap: _pickCustomRange,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCustom
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.date_range,
                      size: 20,
                      color: _isCustom
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              ..._quickPeriods.entries.map(
                (e) => ChoiceChip(
                  label: Text(e.value),
                  selected: !_isCustom && _period == e.key,
                  onSelected: (_) => setState(() {
                    _period = e.key;
                    _customStart = null;
                    _customEnd = null;
                  }),
                ),
              ),
            ],
          ),
          // ถ้าเลือกช่วงเองไว้แล้ว แสดงช่วงวันที่ที่เลือกไว้เป็น chip เล็กๆ ต่อท้าย
          if (_isCustom && _customStart != null && _customEnd != null) ...[
            const SizedBox(height: 8),
            InputChip(
              label: Text(
                '${dFmt.format(_customStart!)} – ${dFmt.format(_customEnd!)}',
              ),
              onDeleted: () => setState(() {
                _period = Period.month;
                _customStart = null;
                _customEnd = null;
              }),
            ),
          ],

          const SizedBox(height: 16),

          // ---- สรุปยอด ----
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      const Text('รายรับ'),
                      Text(fmt.format(income),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      const Text('รายจ่าย'),
                      Text(fmt.format(expense),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                    ]),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text('สัดส่วนรายจ่ายตามหมวดหมู่',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('ยังไม่มีข้อมูลรายจ่ายในช่วงนี้')),
            )
          else ...[
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final amt = e.value.value;
                    final color = _palette[idx % _palette.length];
                    final pct = total == 0 ? 0 : (amt / total * 100);
                    return PieChartSectionData(
                      value: amt,
                      color: color.withValues(alpha: 0.8),
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...entries.asMap().entries.map((e) {
              final idx = e.key;
              final cat = e.value.key;
              final amt = e.value.value;
              final color = _palette[idx % _palette.length];
              return ListTile(
                leading: CircleAvatar(backgroundColor: color, radius: 8),
                title: Text(cat),
                trailing: Text(fmt.format(amt)),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// ตัวเลือกช่วงวันที่แบบ "จบในหน้าเดียว"
///
/// ต่างจาก showDateRangePicker ของ Flutter ตรงที่ไม่มีขั้นตอนสลับไปหน้ากรอก
/// ตัวเลขปี/เดือน/วันแยกต่างหาก — ทุกอย่างอยู่ในปฏิทินเดียวหน้าเดียว:
///   1. แตะวันแรก = ตั้งเป็นวันเริ่มต้น
///   2. แตะวันที่สอง = ตั้งเป็นวันสิ้นสุด แล้วปุ่ม "ยืนยัน" จะกดได้ทันที
///   3. แตะวันใหม่อีกครั้งหลังเลือกครบคู่แล้ว = เริ่มเลือกช่วงใหม่
/// ปฏิทินเป็นปี ค.ศ. เสมอ เลื่อนเดือนด้วยลูกศรซ้าย-ขวา หรือแตะหัวเดือนเพื่อเลือกปี/เดือนเร็วๆ
class _SingleScreenRangePicker extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _SingleScreenRangePicker({this.initialStart, this.initialEnd});

  @override
  State<_SingleScreenRangePicker> createState() =>
      _SingleScreenRangePickerState();
}

class _SingleScreenRangePickerState extends State<_SingleScreenRangePicker> {
  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  static const _weekdayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
  static const _monthLabels = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    final ref = widget.initialStart ?? DateTime.now();
    _visibleMonth = DateTime(ref.year, ref.month);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime day) {
    if (_start == null || _end == null) return false;
    return !day.isBefore(_start!) && !day.isAfter(_end!);
  }

  void _onTapDay(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        // เริ่มเลือกช่วงใหม่
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        // แตะวันก่อนวันเริ่ม -> สลับให้เป็นวันเริ่มใหม่
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  /// เลือกปี/เดือนเร็วๆ ผ่าน dropdown แทนการกดลูกศรทีละเดือน (ยังอยู่หน้าเดียวกัน)
  void _jumpToMonth(int year, int month) {
    setState(() => _visibleMonth = DateTime(year, month));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    // weekday: Mon=1..Sun=7 -> ช่องว่างก่อนวันที่ 1
    final leadingBlank = firstOfMonth.weekday - 1;

    final now = DateTime.now();
    final years = [for (var y = now.year - 5; y <= now.year + 1; y++) y];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: cs.primary),
                const SizedBox(width: 8),
                Text('เลือกช่วงวันที่', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _start == null
                  ? 'แตะวันเริ่มต้น'
                  : _end == null
                      ? 'แตะวันสิ้นสุด (หรือแตะวันเริ่มต้นใหม่อีกครั้ง)'
                      : '${DateFormat('d MMM y', 'en').format(_start!)}  –  ${DateFormat('d MMM y', 'en').format(_end!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),

            // ---- เลือกเดือน/ปีแบบเร็ว (ยังอยู่หน้าเดียวกัน ไม่เปลี่ยนหน้า) ----
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _jumpToMonth(
                    _visibleMonth.month == 1
                        ? _visibleMonth.year - 1
                        : _visibleMonth.year,
                    _visibleMonth.month == 1 ? 12 : _visibleMonth.month - 1,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: _visibleMonth.month,
                        underline: const SizedBox.shrink(),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_monthLabels[i]),
                          ),
                        ),
                        onChanged: (m) {
                          if (m != null) _jumpToMonth(_visibleMonth.year, m);
                        },
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<int>(
                        value: _visibleMonth.year,
                        underline: const SizedBox.shrink(),
                        items: years
                            .map((y) => DropdownMenuItem(
                                value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (y) {
                          if (y != null) _jumpToMonth(y, _visibleMonth.month);
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _jumpToMonth(
                    _visibleMonth.month == 12
                        ? _visibleMonth.year + 1
                        : _visibleMonth.year,
                    _visibleMonth.month == 12 ? 1 : _visibleMonth.month + 1,
                  ),
                ),
              ],
            ),

            // ---- หัววัน ----
            Row(
              children: _weekdayLabels
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),

            // ---- กริดวันที่ ----
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: leadingBlank + daysInMonth,
              itemBuilder: (ctx, i) {
                if (i < leadingBlank) return const SizedBox.shrink();
                final day = DateTime(
                    _visibleMonth.year, _visibleMonth.month, i - leadingBlank + 1);
                final isStart = _start != null && _isSameDay(day, _start!);
                final isEnd = _end != null && _isSameDay(day, _end!);
                final inRange = _inRange(day);
                final isToday = _isSameDay(day, now);

                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: Material(
                    color: isStart || isEnd
                        ? cs.primary
                        : inRange
                            ? cs.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _onTapDay(day),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: isToday && !isStart && !isEnd
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.primary, width: 1),
                              )
                            : null,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isStart || isEnd
                                ? cs.onPrimary
                                : inRange
                                    ? cs.primary
                                    : null,
                            fontWeight: isStart || isEnd
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    // กดยืนยันได้ทันทีที่มีครบทั้งวันเริ่มและวันสิ้นสุด — จบในหน้าเดียว
                    onPressed: _start != null && _end != null
                        ? () => Navigator.pop(
                              context,
                              DateTimeRange(start: _start!, end: _end!),
                            )
                        : null,
                    child: const Text('ยืนยัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
