import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../accounts/transaction_entry.dart';
import '../accounts/currency.dart';
import '../accounts/account_screen.dart';
import '../../data/services/app_data.dart';
import '../../shared/widgets/transaction_tile.dart';

/// ฟอร์มบันทึกรายรับ/รายจ่าย (ใช้ร่วมกันทั้งหน้ารายรับและหน้ารายจ่าย)
/// ตามโน้ต: กด >> จำนวนเงิน >> แม่นตัวเลข >> หมวดหมู่ >> บันทึก
/// เพิ่ม: วัน-เวลาแบบเรียลไทม์ (ปรับเปลี่ยนได้) + อิโมจิความพึงพอใจสำหรับรายจ่าย
class TransactionFormScreen extends StatefulWidget {
  final TransactionType type;

  /// เรียกหลังบันทึกสำเร็จ — ใช้ตอนฝังหน้านี้เป็นแท็บ (ไม่ได้ถูก push มา)
  /// เพื่อสลับกลับไปแท็บ "หน้าหลัก" แทนการ Navigator.pop
  final VoidCallback? onSaved;

  const TransactionFormScreen({super.key, required this.type, this.onSaved});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _category;
  String? _satisfaction;

  // วัน-เวลา: เรียลไทม์โดยดีฟอลต์ ปรับเองได้
  DateTime _dateTime = DateTime.now();
  bool _timeIsCustom = false;
  Timer? _clockTimer;

  /// หมวดหมู่ที่แสดงเป็นปุ่มหลักในหน้าจอ (ตามที่ผู้ใช้กำหนด)
  /// ที่เหลือทั้งหมดซ่อนอยู่หลังปุ่ม "อื่นๆ"
  static const primaryIncomeCategories = [
    '💰 เงินเดือน',
    '🎓 ทุนการศึกษา',
    '🎁 โบนัส',
    '📈 เงินปันผล',
  ];

  static const primaryExpenseCategories = [
    '🍜 ค่าอาหาร',
    '🚗 ค่าเดินทาง',
    '🚰 ค่าน้ำ',
    '💡 ค่าไฟ',
    '☕ ค่าเครื่องดื่ม',
  ];

  /// หมวดหมู่ทั้งหมด (ใช้ในชีต "อื่นๆ")
  static const incomeCategories = [
    '💰 เงินเดือน',
    '🎓 ทุนการศึกษา',
    '🎁 โบนัส',
    '📈 เงินปันผล',
    '💼 ฟรีแลนซ์/ธุรกิจส่วนตัว',
    '🤝 ค่าคอมมิชชั่น',
    '🏦 ดอกเบี้ยเงินฝาก',
    '🧾 คืนภาษี',
    '🎀 ของขวัญ/เงินพิเศษ',
    '🏘️ ค่าเช่า (รายได้)',
    '⏰ รายได้พาร์ทไทม์',
    '📈 กำไรจากการขายของ',
    '🎉 เงินรางวัล/ลอตเตอรี่',
    '🤑 เงินคืน/แคชแบ็ก',
    '👨‍👩‍👧 เงินจากครอบครัว',
    '💻 รายได้ช่องทางออนไลน์',
    '🏆 เบี้ยขยัน/ค่าล่วงเวลา',
    '💵 หนี้ที่ได้รับคืน',
    '🧧 เงินอั่งเปา/ตามเทศกาล',
    '🚕 รายได้เสริม (ขับรถ/ส่งของ)',
  ];

  static const expenseCategories = [
    '🍜 ค่าอาหาร',
    '🚗 ค่าเดินทาง',
    '🚰 ค่าน้ำ',
    '💡 ค่าไฟ',
    '☕ ค่าเครื่องดื่ม',
    '🏠 ที่พัก/ค่าเช่า',
    '🌐 ค่าเน็ต/โทรศัพท์',
    '🛍️ ช้อปปิ้ง',
    '💊 สุขภาพ/ยา',
    '🎬 บันเทิง',
    '📚 การศึกษา',
    '💳 ผ่อนชำระ/หนี้สิน',
    '🍺 ค่าเหล้า/เครื่องดื่มแอลกอฮอล์',
    '🎮 เติมเกม/แอปพลิเคชัน',
    '🚬 บุหรี่/ยาสูบ',
    '🐶 เลี้ยงสัตว์',
    '💇 ความงาม/ตัดผม',
    '🎁 ของขวัญ/งานเลี้ยง',
    '🧴 ของใช้ส่วนตัว',
    '🛠️ ซ่อมแซม/บำรุงรักษา',
  ];

  // 5 ระดับความพึงพอใจต่อรายจ่าย
  static const satisfactionLevels = [
    ('😩', 'เสียดายเงิน'),
    ('😕', 'ไม่ค่อยคุ้ม'),
    ('😐', 'เฉยๆ'),
    ('🙂', 'พอใจ'),
    ('🤩', 'คุ้มมาก'),
  ];

  // ไอคอนของแต่ละหมวดหมู่ (แสดงเป็นวงกลม) — ไม่กระทบค่า category ที่ใช้บันทึกจริง
  static const _incomeCategoryIcons = <String, IconData>{
    '💰 เงินเดือน': Icons.payments,
    '🎓 ทุนการศึกษา': Icons.school,
    '🎁 โบนัส': Icons.card_giftcard,
    '📈 เงินปันผล': Icons.trending_up,
    '💼 ฟรีแลนซ์/ธุรกิจส่วนตัว': Icons.work,
    '🤝 ค่าคอมมิชชั่น': Icons.handshake,
    '🏦 ดอกเบี้ยเงินฝาก': Icons.account_balance,
    '🧾 คืนภาษี': Icons.receipt_long,
    '🎀 ของขวัญ/เงินพิเศษ': Icons.redeem,
    '🏘️ ค่าเช่า (รายได้)': Icons.house,
    '⏰ รายได้พาร์ทไทม์': Icons.access_time_filled,
    '📈 กำไรจากการขายของ': Icons.sell,
    '🎉 เงินรางวัล/ลอตเตอรี่': Icons.emoji_events,
    '🤑 เงินคืน/แคชแบ็ก': Icons.savings,
    '👨‍👩‍👧 เงินจากครอบครัว': Icons.family_restroom,
    '💻 รายได้ช่องทางออนไลน์': Icons.laptop_mac,
    '🏆 เบี้ยขยัน/ค่าล่วงเวลา': Icons.military_tech,
    '💵 หนี้ที่ได้รับคืน': Icons.assignment_return,
    '🧧 เงินอั่งเปา/ตามเทศกาล': Icons.celebration,
    '🚕 รายได้เสริม (ขับรถ/ส่งของ)': Icons.local_taxi,
  };

  static const _expenseCategoryIcons = <String, IconData>{
    '🍜 ค่าอาหาร': Icons.restaurant,
    '🚗 ค่าเดินทาง': Icons.directions_car,
    '🚰 ค่าน้ำ': Icons.water_drop,
    '💡 ค่าไฟ': Icons.lightbulb,
    '☕ ค่าเครื่องดื่ม': Icons.local_cafe,
    '🏠 ที่พัก/ค่าเช่า': Icons.home,
    '🌐 ค่าเน็ต/โทรศัพท์': Icons.wifi,
    '🛍️ ช้อปปิ้ง': Icons.shopping_bag,
    '💊 สุขภาพ/ยา': Icons.medical_services,
    '🎬 บันเทิง': Icons.movie,
    '📚 การศึกษา': Icons.school,
    '💳 ผ่อนชำระ/หนี้สิน': Icons.credit_card,
    '🍺 ค่าเหล้า/เครื่องดื่มแอลกอฮอล์': Icons.sports_bar,
    '🎮 เติมเกม/แอปพลิเคชัน': Icons.sports_esports,
    '🚬 บุหรี่/ยาสูบ': Icons.smoking_rooms,
    '🐶 เลี้ยงสัตว์': Icons.pets,
    '💇 ความงาม/ตัดผม': Icons.content_cut,
    '🎁 ของขวัญ/งานเลี้ยง': Icons.cake,
    '🧴 ของใช้ส่วนตัว': Icons.soap,
    '🛠️ ซ่อมแซม/บำรุงรักษา': Icons.build,
  };

  /// หมวดหมู่ที่มีรูปกำหนดเอง (ของผู้ใช้เอง) แทนไอคอน Material ปกติ
  /// key ต้องตรงกับข้อความหมวดหมู่ใน primaryIncomeCategories/incomeCategories เป๊ะ
  static const _categoryImages = <String, String>{
    '🎁 โบนัส': 'assets/images/bonus_icon.jpg',
    '🎓 ทุนการศึกษา': 'assets/images/scholarship_icon.jpg',
    '🏆 เบี้ยขยัน/ค่าล่วงเวลา': 'assets/images/overtime_icon.jpg',
    '🧧 เงินอั่งเปา/ตามเทศกาล': 'assets/images/gift_money_icon.jpg',
  };

  /// คืนรูปกำหนดเองของหมวดหมู่นี้ (ถ้ามี) — ใช้แทนไอคอน Material
  Widget? _customImageFor(String category) {
    final path = _categoryImages[category];
    if (path == null) return null;
    return Image.asset(path, fit: BoxFit.cover);
  }

  IconData _iconFor(String category, bool isIncome) {
    final map = isIncome ? _incomeCategoryIcons : _expenseCategoryIcons;
    return map[category] ?? Icons.category;
  }

  /// หมวดหมู่หลักที่โชว์เป็นปุ่มวงกลมในหน้าจอ (ตามชนิดของฟอร์ม)
  List<String> get primaryCategories =>
      widget.type == TransactionType.income
          ? primaryIncomeCategories
          : primaryExpenseCategories;

  /// เปิดชีตเลือกหมวดหมู่ "อื่นๆ" — แสดงหมวดที่เหลือทั้งหมดที่ไม่ได้อยู่ในปุ่มหลัก
  /// เลื่อนขึ้นได้เกือบเต็มจอ เพื่อให้เห็นหมวดหมู่ได้มากที่สุดในครั้งเดียว
  Future<void> _pickOtherCategory(bool isIncome) async {
    final all = isIncome ? incomeCategories : expenseCategories;
    final others =
        all.where((c) => !primaryCategories.contains(c)).toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.more_horiz,
                    color: isIncome ? Colors.green : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'เลือกหมวดหมู่เพิ่มเติม',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: others.length,
                itemBuilder: (ctx, i) {
                  final c = others[i];
                  final selected = _category == c;
                  final baseColor = isIncome ? Colors.green : Colors.redAccent;
                  final customImage = _customImageFor(c);

                  return ListTile(
                    leading: customImage != null
                        ? CircleAvatar(child: ClipOval(child: customImage))
                        : CircleAvatar(
                            backgroundColor: baseColor.withValues(alpha: 0.12),
                            child: Icon(
                              _iconFor(c, isIncome),
                              color: baseColor,
                              size: 22,
                            ),
                          ),
                    title: Text(_labelFor(c)),
                    trailing: selected
                        ? Icon(Icons.check_circle, color: baseColor)
                        : null,
                    onTap: () => Navigator.pop(ctx, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _category = picked);
    }
  }

  /// ตัดอิโมจินำหน้าออก เหลือแค่ข้อความ เพื่อโชว์เป็นป้ายใต้ไอคอนวงกลม
  /// (ค่า category ที่บันทึกจริงยังคงเดิมทุกตัวอักษร ไม่ได้ถูกแก้ไข)
  String _labelFor(String category) {
    final spaceIndex = category.indexOf(' ');
    if (spaceIndex == -1) return category;
    return category.substring(spaceIndex + 1);
  }

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_timeIsCustom && mounted) {
        setState(() => _dateTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _timeIsCustom = true;
    });
  }

  void _resetToNow() {
    setState(() {
      _dateTime = DateTime.now();
      _timeIsCustom = false;
    });
  }

  Future<void> _save(AppData data) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0 || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }
    // บันทึกโดยยังไม่ผูกบัญชี — ไปผูกบัญชีทีหลังได้ที่หน้า "บัญชี"
    // (ลากไอคอนรายการที่ยังไม่ระบุบัญชีไปวางบนบัญชีที่ต้องการ)
    data.addTransaction(
      accountId: null,
      amount: amount,
      category: _category!,
      type: widget.type,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _dateTime,
      satisfaction: _satisfaction,
    );

    // รายการที่เพิ่งบันทึกจะถูกแทรกไว้บนสุดของลิสต์เสมอ (ดู AppData.addTransaction:
    // transactions.insert(0, tx)) จึงหยิบรายการแรกมาใช้เป็นตัวไฮไลต์ในหน้าบัญชีได้เลย
    final newTx = data.transactions.first;

    _amountCtrl.clear();
    _noteCtrl.clear();
    setState(() {
      _category = null;
      _satisfaction = null;
      _timeIsCustom = false;
      _dateTime = DateTime.now();
    });

    if (!mounted) return;

    // กดบันทึกแล้ว: ไปหน้า "บัญชี" — รายการที่เพิ่งบันทึกจะกลายเป็นไอคอนลอยกลางจอ
    // (ใหญ่ 4 เท่า โปร่งใส) ค้างอยู่จนกว่าผู้ใช้จะจัดการ
    // กดค้างที่ไอคอน = เลือกบัญชีแบบอิสระ / ลากไอคอน = วางลงการ์ดบัญชี
    // ถ้าบันทึกหลายรายการติดกัน ไอคอนจะซ้อนกันได้
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountScreen(highlightTransactionId: newTx.id),
      ),
    );

    if (!mounted) return;
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final data = context.watch<AppData>();
    final list = data.transactions.where((t) => t.type == widget.type).toList();
    final fmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);
    final dtFmt = DateFormat('d MMM y, HH:mm:ss', 'th');

    return Scaffold(
      appBar: AppBar(title: Text(isIncome ? 'รายรับ' : 'รายจ่าย')),
      body: data.accounts.isEmpty
          ? const Center(child: Text('กรุณาเพิ่มบัญชีก่อน (หน้า "บัญชี")'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // วัน-เวลา แบบเรียลไทม์ / ปรับเองได้
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _timeIsCustom ? Icons.event : Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dtFmt.format(_dateTime),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_timeIsCustom)
                          IconButton(
                            tooltip: 'กลับเป็นตอนนี้',
                            icon: const Icon(Icons.restart_alt),
                            onPressed: _resetToNow,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'จำนวนเงิน', border: OutlineInputBorder(), prefixText: '฿ '),
                ),
                const SizedBox(height: 12),
                _FrequentCategories(
                  type: widget.type,
                  selected: _category,
                  isIncome: isIncome,
                  iconFor: (c) => _iconFor(c, isIncome),
                  labelFor: _labelFor,
                  onSelected: (c) => setState(() => _category = c),
                ),
                Text('หมวดหมู่', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    ...primaryCategories.map((c) => _CategoryCircle(
                          label: _labelFor(c),
                          icon: _iconFor(c, isIncome),
                          customImage: _customImageFor(c),
                          selected: _category == c,
                          baseColor: isIncome ? Colors.green : Colors.redAccent,
                          onTap: () => setState(() => _category = c),
                        )),
                    // ปุ่ม "อื่นๆ" — เปิดชีตให้เลือกหมวดหมู่ที่เหลือทั้งหมด
                    _CategoryCircle(
                      label: 'อื่นๆ',
                      icon: Icons.more_horiz,
                      // ถ้าเลือกหมวดนอกรายการหลักที่มีรูปกำหนดเอง (เช่น ค่าล่วงเวลา/อั่งเปา)
                      // ให้ปุ่ม "อื่นๆ" นี้โชว์รูปนั้นแทนไอคอน more_horiz ด้วย
                      customImage: _category != null &&
                              !primaryCategories.contains(_category)
                          ? _customImageFor(_category!)
                          : null,
                      // ถ้าเลือกหมวดที่อยู่นอกรายการหลักไว้ ให้ปุ่มนี้ติดสถานะเลือกด้วย
                      selected: _category != null &&
                          !primaryCategories.contains(_category),
                      baseColor: isIncome ? Colors.green : Colors.redAccent,
                      // แสดงชื่อหมวดที่เลือกจากชีตแทนคำว่า "อื่นๆ"
                      overrideLabel: _category != null &&
                              !primaryCategories.contains(_category)
                          ? _labelFor(_category!)
                          : null,
                      onTap: () => _pickOtherCategory(isIncome),
                    ),
                  ],
                ),
                if (!isIncome) ...[
                  const SizedBox(height: 16),
                  Text('ความพึงพอใจกับรายจ่ายนี้', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: satisfactionLevels.map((s) {
                      final (emoji, label) = s;
                      final selected = _satisfaction == emoji;
                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(
                              () => _satisfaction = selected ? null : emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 26)),
                                const SizedBox(height: 2),
                                Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                _FrequentNotes(
                  type: widget.type,
                  isIncome: isIncome,
                  onPicked: (note) => setState(() => _noteCtrl.text = note),
                ),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'บันทึกเพิ่มเติม', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _save(data),
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึก'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isIncome ? Colors.green : Colors.redAccent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ประวัติ${isIncome ? 'รายรับ' : 'รายจ่าย'} รวม '
                  '${fmt.format(list.fold(0.0, (s, t) => s + t.amount))}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...list.map((t) => TransactionTile(
                      tx: t,
                      accountName: t.accountId != null
                          ? data.accountById(t.accountId!).name
                          : 'ไม่ระบุบัญชี',
                      currency: t.accountId != null
                          ? data.accountById(t.accountId!).currency
                          : Currency.thb,
                      onRepeat: () => data.repeatTransaction(t),
                    )),
              ],
            ),
    );
  }
}

/// ปุ่มหมวดหมู่รูปวงกลม (ใช้ทั้งหมวดหลักและปุ่ม "อื่นๆ")
class _CategoryCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color baseColor;
  final VoidCallback onTap;

  /// ใช้แทนข้อความ label เดิม (กรณีปุ่ม "อื่นๆ" ที่เลือกหมวดจากชีตไว้แล้ว)
  final String? overrideLabel;

  /// รูปกำหนดเอง (เช่น Image.asset) — ถ้ามีจะโชว์แทนไอคอน Material
  /// รูปพวกนี้มีวงกลมพื้นหลังของตัวเองติดมาอยู่แล้ว จึงไม่ห่อวงกลมสีซ้ำอีกชั้น
  final Widget? customImage;

  const _CategoryCircle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.baseColor,
    required this.onTap,
    this.overrideLabel,
    this.customImage,
  });

  @override
  Widget build(BuildContext context) {
    final text = overrideLabel ?? label;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customImage != null
                ? AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? baseColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(child: customImage),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? baseColor.withValues(alpha: 0.18)
                          : baseColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: selected ? baseColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: baseColor, size: 26),
                  ),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? baseColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// แถบ "ใช้บ่อย" — 5 หมวดหมู่ที่ผู้ใช้บันทึกซ้ำมากที่สุด
/// ซ่อนตัวเองอัตโนมัติถ้ายังไม่มีข้อมูลมากพอ
class _FrequentCategories extends StatelessWidget {
  final TransactionType type;
  final String? selected;
  final bool isIncome;
  final IconData Function(String) iconFor;
  final String Function(String) labelFor;
  final ValueChanged<String> onSelected;

  const _FrequentCategories({
    required this.type,
    required this.selected,
    required this.isIncome,
    required this.iconFor,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final top = data.topCategories(type);

    if (top.isEmpty) return const SizedBox.shrink();

    final baseColor = isIncome ? Colors.green : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: baseColor),
            const SizedBox(width: 6),
            Text('ใช้บ่อย', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        
        const SizedBox(height: 2),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final c = top[i];
              final count = data.categoryUseCount(c, type);
              final isSelected = selected == c;

              return ActionChip(
                avatar: Icon(iconFor(c), size: 18, color: baseColor),
                label: Text('${labelFor(c)}  ·$count'),
                backgroundColor: isSelected
                    ? baseColor.withValues(alpha: 0.18)
                    : baseColor.withValues(alpha: 0.06),
                side: BorderSide(
                  color: isSelected ? baseColor : Colors.transparent,
                ),
                onPressed: () => onSelected(c),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// แถบ "บันทึกที่ใช้บ่อย" — 5 ข้อความที่เคยพิมพ์ซ้ำมากที่สุด กดแล้วใส่ให้เลย
class _FrequentNotes extends StatelessWidget {
  final TransactionType type;
  final bool isIncome;
  final ValueChanged<String> onPicked;

  const _FrequentNotes({
    required this.type,
    required this.isIncome,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final notes = data.topNotes(type);

    if (notes.isEmpty) return const SizedBox.shrink();

    final baseColor = isIncome ? Colors.green : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 16, color: baseColor),
            const SizedBox(width: 6),
            Text(
              'บันทึกที่ใช้บ่อย',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: notes
              .map(
                (n) => ActionChip(
                  label: Text(n, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: baseColor.withValues(alpha: 0.06),
                  side: BorderSide.none,
                  onPressed: () => onPicked(n),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
