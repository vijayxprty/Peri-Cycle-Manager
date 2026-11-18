import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../utils.dart';

/// Shared month calendar grid, used on Home and on the Calendar screen.
///
/// Design rules — approved screenshots, 18 Nov 2026 (they override the
/// earlier soft-fill note):
/// - Date numbers truly centred in their boxes; the ovulation dot is pinned
///   absolute to the bottom so it never pushes the number.
/// - Selected day (Calendar screen): solid rose #C24E64, white text, soft
///   shadow. NEVER black. A small white dot sits under the number.
/// - Today (Calendar screen, when not selected): ONE clean 1.5px rose ring.
/// - Today on the HOME mini-calendar: DARK filled square, white text
///   ([todayDark]) — that is what the approved Home screen shows.
/// - Predicted period days: DASHED rose outline, white fill, rose text.
///   The expected start day itself renders PLAIN (28 Nov is unstyled in
///   both approved screenshots; only 29–30 are dashed).
/// - In-range days (picked start–end): soft light-pink fill, NOT an outline.
/// - Pressed state: slight scale-down, not a colour change.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.state,
    required this.year,
    required this.month,
    required this.selectedDay,
    this.rangeStart,
    this.rangeEnd,
    this.onDayTap,
    this.showMonthHeader = false,
    this.onPrevMonth,
    this.onNextMonth,
    this.canGoPrev = true,
    this.canGoNext = true,
    this.todayDark = false,
  });

  final AppState state;
  final int year;
  final int month;
  final DateTime selectedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final ValueChanged<DateTime>? onDayTap;
  final bool showMonthHeader;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;
  final bool canGoPrev;
  final bool canGoNext;
  // Home mini-calendar: today renders as a dark filled square.
  final bool todayDark;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  DateTime? _pressed;

  @override
  Widget build(BuildContext context) {
    final firstDow = DateTime(widget.year, widget.month, 1).weekday % 7;
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    final today = dateOnly(DateTime.now());
    final periodKeys = widget.state.periodDayKeys;
    final fertileKeys = widget.state.fertileDayKeys;
    final predictedKeys = widget.state.predictedDayKeys;
    final expectedNext = widget.state.expectedNext;
    final ovu = widget.state.ovulationDay;
    final rangeStart = widget.rangeStart != null
        ? dateOnly(widget.rangeStart!)
        : null;
    final rangeEnd =
        widget.rangeEnd != null ? dateOnly(widget.rangeEnd!) : null;

    bool inPickedRange(DateTime d) {
      if (rangeStart == null || rangeEnd == null) return false;
      final s = rangeStart.isBefore(rangeEnd) ? rangeStart : rangeEnd;
      final e = rangeStart.isBefore(rangeEnd) ? rangeEnd : rangeStart;
      return !d.isBefore(s) && !d.isAfter(e);
    }

    final cells = <Widget>[];
    for (var i = 0; i < firstDow; i++) {
      cells.add(const SizedBox(height: 42));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(widget.year, widget.month, day);
      final key = dateKey(date);
      final isSelected = dateOnly(widget.selectedDay) == date;
      final isToday = today == date;
      final isPeriod = periodKeys.contains(key);
      final isFertile = fertileKeys.contains(key) && !isPeriod;
      final isOvu = ovu != null && dateOnly(ovu) == date;
      // Predicted days are the rest of the predicted window — the expected
      // start day itself renders PLAIN (approved screenshots: 28 Nov is
      // unstyled, 29–30 are dashed). Never mark the expected date dashed.
      final isExpectedStart =
          expectedNext != null && dateOnly(expectedNext) == date;
      final isPredicted =
          predictedKeys.contains(key) && !isPeriod && !isExpectedStart;
      final inRange = inPickedRange(date) && !isPeriod;

      Color? bg;
      Color textColor = PB.ink;
      FontWeight weight = FontWeight.w500;
      Border? border;
      List<BoxShadow>? shadow;
      bool dashedPredicted = false;

      if (widget.todayDark && isToday) {
        // Approved Home mini-calendar: today is a dark filled square.
        bg = PB.dark;
        textColor = Colors.white;
        weight = FontWeight.w800;
      } else if (isSelected) {
        bg = PB.rose;
        textColor = Colors.white;
        weight = FontWeight.w800;
        shadow = [
          BoxShadow(
            color: PB.rose.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ];
      } else if (isPeriod) {
        bg = PB.roseLight;
        textColor = PB.roseDark;
        weight = FontWeight.w700;
      } else if (inRange) {
        bg = PB.roseSoft;
        textColor = PB.roseDark;
      } else if (isOvu) {
        // Ovulation BEFORE fertile: the ovulation day is inside the
        // fertile window, but it renders mint, not lavender.
        bg = PB.mint;
      } else if (isFertile) {
        bg = PB.lavender;
      } else if (isPredicted) {
        // Predicted period days: DASHED rose outline, white fill,
        // rose text (approved screenshots). Never a solid fill.
        dashedPredicted = true;
        textColor = PB.rose;
        weight = FontWeight.w700;
      }
      if (isToday && !isSelected && !widget.todayDark) {
        // ONE clean ring only — the border itself, no pseudo-element.
        border = Border.all(color: PB.rose, width: 1.5);
        weight = FontWeight.w700;
      }

      final pressed = _pressed == date;
      // Number centred; dot pinned absolute to the bottom.
      final cellContent = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: weight,
              color: textColor,
              height: 1,
            ),
          ),
          if (isOvu)
            Positioned(
              bottom: 5,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: (isSelected || (widget.todayDark && isToday))
                      ? Colors.white
                      : PB.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // White dot under a ROSE selected day (approved Calendar).
          // Not on the dark Home-today cell, which has no dot.
          if (isSelected && !(widget.todayDark && isToday) && !isOvu)
            Positioned(
              bottom: 5,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
      final Widget cell = dashedPredicted
          ? DashedBorderBox(
              radius: 12,
              child: SizedBox(height: 42, child: cellContent),
            )
          : Container(
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: border,
                boxShadow: shadow,
              ),
              child: cellContent,
            );
      cells.add(
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = date),
          onTapUp: (_) => setState(() => _pressed = null),
          onTapCancel: () => setState(() => _pressed = null),
          onTap: () => widget.onDayTap?.call(date),
          child: AnimatedScale(
            scale: pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 90),
            child: cell,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (widget.showMonthHeader)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fmtFullMonth(DateTime(widget.year, widget.month))} ${widget.year}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                children: [
                  _arrow(Icons.chevron_left, widget.onPrevMonth,
                      widget.canGoPrev),
                  const SizedBox(width: 6),
                  _arrow(Icons.chevron_right, widget.onNextMonth,
                      widget.canGoNext),
                ],
              ),
            ],
          ),
        const SizedBox(height: 14),
        Row(
          children: weekdayShortSunFirst
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PB.muted,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 5),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const _LegendDot(color: Color(0xFFF4A9B2), label: 'Period'),
            SizedBox(width: 10),
            const _LegendDot(color: Color(0xFFB7A6E3), label: 'Fertile'),
            SizedBox(width: 10),
            const _LegendDot(color: PB.green, label: 'Ovulation'),
            SizedBox(width: 10),
            // Predicted = dashed rose outline, as on the days themselves.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  painter: DashedRectPainter(
                    color: PB.rose,
                    strokeWidth: 1.2,
                    radius: 4.5,
                  ),
                  child: const SizedBox(width: 9, height: 9),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Predicted',
                  style: TextStyle(fontSize: 11, color: PB.muted),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap, bool enabled) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF0EE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? PB.rose : const Color(0xFFD8C4C8),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: PB.muted),
        ),
      ],
    );
  }
}

