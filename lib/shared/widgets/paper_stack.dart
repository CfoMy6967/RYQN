import 'package:flutter/material.dart';

/// วิดเจ็ตแสดงรายการเป็น "กระดาษซ้อนกัน" (paper stack)
///
/// - ใบบนสุด (index ปัจจุบัน) จะอยู่หน้าสุด มองเห็นชัดเจน
/// - ใบถัดไปจะซ้อนอยู่ด้านหลัง เยื้องลงมาเล็กน้อยและย่อขนาดลง ให้ความรู้สึกเป็นกอง
/// - ปัดขึ้น = ไปดูใบถัดไป (เก่ากว่า) / ปัดลง = ย้อนกลับไปใบก่อนหน้า (ใหม่กว่า)
///
/// ใช้ซ้ำได้ทั้งกับ "รายการล่าสุด" และ "รายการบัญชี"
class PaperStack<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) cardBuilder;

  /// ความสูงของ "การ์ด" แต่ละใบ
  final double cardHeight;

  /// จำนวนใบสูงสุดที่จะซ้อนโชว์ด้านหลังใบหน้า (แค่มิติภาพ ไม่ใช่จำนวนข้อมูล)
  final int maxVisibleLayers;

  /// ข้อความที่แสดงเมื่อไม่มีข้อมูล
  final String emptyLabel;

  const PaperStack({
    super.key,
    required this.items,
    required this.cardBuilder,
    this.cardHeight = 92,
    this.maxVisibleLayers = 4,
    this.emptyLabel = 'ยังไม่มีข้อมูล',
  });

  @override
  State<PaperStack<T>> createState() => _PaperStackState<T>();
}

class _PaperStackState<T> extends State<PaperStack<T>> {
  int _focusIndex = 0;

  @override
  void didUpdateWidget(covariant PaperStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ถ้าจำนวนรายการเปลี่ยน (เช่น มีรายการใหม่/ถูกลบ) ให้ปรับ index ให้อยู่ในขอบเขต
    if (widget.items.isEmpty) {
      _focusIndex = 0;
    } else if (_focusIndex > widget.items.length - 1) {
      _focusIndex = widget.items.length - 1;
    }
  }

  void _goNext() {
    if (_focusIndex < widget.items.length - 1) {
      setState(() => _focusIndex++);
    }
  }

  void _goPrevious() {
    if (_focusIndex > 0) {
      setState(() => _focusIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(
        height: widget.cardHeight,
        child: Center(
          child: Text(
            widget.emptyLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final layerCount = widget.maxVisibleLayers
        .clamp(1, widget.items.length - _focusIndex)
        .toInt();

    final stackHeight =
        widget.cardHeight + (layerCount - 1) * 10 + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -80) {
              _goNext();
            } else if (velocity > 80) {
              _goPrevious();
            }
          },
          child: SizedBox(
            height: stackHeight,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // วาดจากใบหลังสุดมาก่อน แล้วค่อยวาดใบหน้าสุดทับด้านบน
                for (int depth = layerCount - 1; depth >= 0; depth--)
                  _buildLayer(context, depth),
              ],
            ),
          ),
        ),
        if (widget.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_focusIndex + 1} / ${widget.items.length}  ·  ปัดขึ้น-ลงเพื่อดูรายการอื่น',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildLayer(BuildContext context, int depth) {
    final itemIndex = _focusIndex + depth;
    final item = widget.items[itemIndex];
    final isFront = depth == 0;

    final scale = 1 - (depth * 0.035);
    final topOffset = depth * 10.0;
    final opacity = depth == 0 ? 1.0 : (1 - depth * 0.18).clamp(0.35, 1.0);

    final card = Material(
      elevation: isFront ? 4 : 1,
      borderRadius: BorderRadius.circular(14),
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: widget.cardHeight,
        child: IgnorePointer(
          ignoring: !isFront,
          child: widget.cardBuilder(context, item, itemIndex),
        ),
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      top: topOffset,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: card,
        ),
      ),
    );
  }
}

