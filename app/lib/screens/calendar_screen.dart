import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/calendar_grid.dart';

/// Calendar screen.
///
/// Marking is by START date and END date: pick a start day and an end day,
/// then "Mark [start] – [end] as period" marks the whole range at once
/// (length shown). Tapping again removes the whole range.
/// Marked state is a clean status row — never a long green pill.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.state});

  final AppState state;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _viewMonth; // first of month
  late DateTime _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
    _selectedDay = dateOnly(now);
  }

  DateTime get _today => dateOnly(DateTime.now());

  void _goMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta, 1);
      _selectedDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    });
  }

  bool get _canPrev {
    final m = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    return !m.isBefore(DateTime(2025, 1, 1));
  }

  bool get _canNext {
    final m = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    return !m.isAfter(DateTime(2027, 12, 1));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final next = state.expectedNext;
    final selectedKey = dateKey(_selectedDay);
    final isPeriod = state.isPeriodDay(_selectedDay);
    final isOvu =
        state.ovulationDay != null &&
        dateOnly(state.ovulationDay!) == _selectedDay;
    final isFertile = state.fertileDayKeys.contains(selectedKey) && !isPeriod;
    final isPredicted =
        state.predictedDayKeys.contains(selectedKey) && !isPeriod;

    final rs = _rangeStart;
    final re = _rangeEnd;
    final hasRange = rs != null && re != null;
    var rangeLen = 0;
    if (rs != null && re != null) {
      rangeLen = dateOnly(re).difference(dateOnly(rs)).inDays.abs() + 1;
    }
    final rangeMarked =
        hasRange &&
        state.isRangeFullyMarked(
          rs.isBefore(re) ? rs : re,
          rs.isBefore(re) ? re : rs,
        );

    String detailTitle;
    String detailBody;
    if (isPeriod) {
      detailTitle = 'Period day';
      detailBody = 'This day is marked as a period day.';
    } else if (isOvu) {
      detailTitle = 'Ovulation day';
      detailBody = 'Your most fertile day.';
    } else if (isFertile) {
      detailTitle = 'Fertile day';
      detailBody = 'You are in your fertile window.';
    } else if (isPredicted) {
      detailTitle = 'Expected period day';
      detailBody = 'Predicted period day. Pack pads if you are travelling.';
    } else if (_selectedDay == _today) {
      detailTitle = state.dayOfCycle != null
          ? 'Today · Day ${state.dayOfCycle}'
          : 'Today';
      detailBody = next == null
          ? 'Log your first period below and I will start predicting.'
          : state.isOverdue
          ? 'Your period was due ${fmtWeekdayDay(next)} — ${state.daysLate} day${state.daysLate == 1 ? '' : 's'} late. Log it when it starts.'
          : '${state.currentPhase} phase. Expected next period: ${fmtWeekdayDay(next)}.';
    } else {
      detailTitle = fmtDayMonthYear(_selectedDay);
      detailBody = next == null
          ? 'Expected next period: not known yet.'
          : state.isOverdue
          ? 'Your period was due ${fmtWeekdayDay(next)} — ${state.daysLate} day${state.daysLate == 1 ? '' : 's'} late.'
          : 'Expected next period: ${fmtWeekdayDay(next)}.';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'YOUR CYCLE AT A GLANCE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: PB.muted,
                  ),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFBD9D6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: PB.rose, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: PB.rosePale,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: PB.muted,
                fontFamily: 'Outfit',
              ),
              children: [
                TextSpan(text: 'Tap a day to pick it, then set it as '),
                TextSpan(
                  text: 'start',
                  style: TextStyle(color: PB.rose, fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ' or '),
                TextSpan(
                  text: 'end',
                  style: TextStyle(color: PB.rose, fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ' below'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Stats
        Row(
          children: [
            _StatCard(
              label: 'Last period',
              value: state.lastPeriodStart != null
                  ? fmtDayMonth(state.lastPeriodStart!)
                  : '—',
              sub: state.lastPeriodEnd != null
                  ? '${state.lastPeriodEnd!.difference(state.lastPeriodStart!).inDays + 1} days'
                  : 'Not logged',
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Cycle length',
              value: '${state.avgCycle} days',
              sub: 'Average',
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Expected next',
              value: next != null ? fmtDayMonth(next) : '—',
              // Never "in -15 days": overdue shows "15 days late".
              sub: next != null ? state.daysToGoLabel : 'Log a period',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Calendar card
        PBCard(
          child: MonthCalendar(
            state: state,
            year: _viewMonth.year,
            month: _viewMonth.month,
            selectedDay: _selectedDay,
            rangeStart: _rangeStart,
            rangeEnd: _rangeEnd,
            showMonthHeader: true,
            onPrevMonth: _canPrev ? () => _goMonth(-1) : null,
            onNextMonth: _canNext ? () => _goMonth(1) : null,
            canGoPrev: _canPrev,
            canGoNext: _canNext,
            onDayTap: (d) => setState(() => _selectedDay = d),
          ),
        ),

        // Detail card
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE3E0), Color(0xFFF3E9FB)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF502332).withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fmtShortMonth(_selectedDay).toUpperCase()} ${_selectedDay.day}, ${_selectedDay.year}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: PB.rose,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detailTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detailBody,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: PB.softText,
                ),
              ),
              const SizedBox(height: 12),
              // Start / end range picker
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _RangeCell(
                          label: 'Started on',
                          value: rs != null ? fmtDayMonth(rs) : '—',
                        ),
                        const SizedBox(width: 8),
                        _RangeCell(
                          label: 'Ends on',
                          value: re != null ? fmtDayMonth(re) : '—',
                        ),
                        const SizedBox(width: 8),
                        _RangeCell(
                          label: 'Length',
                          value: hasRange ? '$rangeLen days' : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SetButton(
                            label: 'Set ${fmtDayMonth(_selectedDay)} as start',
                            onTap: () => setState(() {
                              _rangeStart = _selectedDay;
                              if (_rangeEnd != null &&
                                  _rangeEnd!.isBefore(_selectedDay)) {
                                _rangeEnd = _selectedDay;
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SetButton(
                            label: 'Set ${fmtDayMonth(_selectedDay)} as end',
                            onTap: () => setState(() {
                              _rangeEnd = _selectedDay;
                              if (_rangeStart != null &&
                                  _rangeStart!.isAfter(_selectedDay)) {
                                _rangeStart = _selectedDay;
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (hasRange && rangeMarked)
                MarkedStatusRow(
                  title: 'Period marked',
                  subtitle:
                      '${fmtRangeShort(rs.isBefore(re) ? rs : re, rs.isBefore(re) ? re : rs)} · $rangeLen days',
                  onRemove: () {
                    final s = rs.isBefore(re) ? rs : re;
                    final e = rs.isBefore(re) ? re : rs;
                    state.togglePeriodRange(s, e);
                  },
                )
              else if (hasRange)
                Center(
                  child: RosePillButton(
                    fullWidth: false,
                    label:
                        'Mark ${fmtRangeShort(rs.isBefore(re) ? rs : re, rs.isBefore(re) ? re : rs)} as period',
                    onPressed: () {
                      final s = rs.isBefore(re) ? rs : re;
                      final e = rs.isBefore(re) ? re : rs;
                      state.togglePeriodRange(s, e);
                    },
                  ),
                )
              else
                Center(
                  child: RosePillButton(
                    fullWidth: false,
                    label: 'Mark ${fmtDayMonth(_selectedDay)} as period day',
                    onPressed: () {
                      setState(() {
                        _rangeStart = _selectedDay;
                        _rangeEnd = _selectedDay;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showSymptoms(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE8C9C4)),
                    backgroundColor: Colors.white,
                    foregroundColor: PB.ink,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Add symptom for this day',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Coming up
        const SizedBox(height: 12),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coming up',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _ComingRow(
                day: next != null ? '${next.day}' : '—',
                color: const Color(0xFFFBD9D6),
                title: 'Expected next period',
                sub: next != null
                    ? fmtWeekdayDay(next)
                    : 'Log your first period',
                // Overdue: "15 days late", never "in -15 days".
                when: next != null ? state.daysToGoLabel : '',
              ),
              _ComingRow(
                // NEXT future fertile window — the current cycle's
                // window may already be in the past (overdue).
                day: state.nextFertileDays.isNotEmpty
                    ? '${state.nextFertileDays.first.day}'
                    : '—',
                color: PB.lavender,
                title: 'Next fertile window',
                sub: state.nextFertileDays.isNotEmpty
                    ? '${fmtDayMonth(state.nextFertileDays.first)} – ${fmtDayMonth(state.nextFertileDays.last)}'
                    : '—',
                when: '',
              ),
              _ComingRow(
                day: state.nextOvulationDay != null
                    ? '${state.nextOvulationDay!.day}'
                    : '—',
                color: PB.lavender,
                title: 'Next ovulation',
                sub: state.nextOvulationDay != null
                    ? fmtWeekdayDay(state.nextOvulationDay!)
                    : '—',
                when: '',
              ),
            ],
          ),
        ),

        // Travel
        const SizedBox(height: 12),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Travelling soon?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () => _addTrip(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '+ Add trip',
                      style: TextStyle(
                        color: PB.rose,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Add your trip dates — I will warn you if your expected period overlaps, with a pack-pads checklist.',
                style: TextStyle(
                  fontSize: 14,
                  color: PB.softText,
                  height: 1.55,
                ),
              ),
              if (state.trips.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...state.trips.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.luggage_outlined,
                          size: 16,
                          color: PB.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${fmtDayMonth(t.start)} – ${fmtDayMonth(t.end)} ${t.end.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => state.deleteTrip(t.id),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: PB.rose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showSymptoms(BuildContext context) {
    final key = dateKey(_selectedDay);
    final selected = widget.state.symptomsByDay[key] ?? [];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptoms · ${fmtDayMonth(_selectedDay)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppState.symptomOptions.map((s) {
                final on = selected.contains(s);
                return GestureDetector(
                  onTap: () {
                    widget.state.toggleSymptom(_selectedDay, s);
                    Navigator.of(context).pop();
                    _showSymptoms(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: on ? PB.rose : Colors.white,
                      border: Border.all(
                        color: on ? PB.rose : const Color(0xFFE8C9C4),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: on ? Colors.white : PB.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTrip(BuildContext context) async {
    DateTime start = dateOnly(DateTime.now()).add(const Duration(days: 7));
    DateTime end = start.add(const Duration(days: 4));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add a trip',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('From'),
                    subtitle: Text(fmtDayMonthYear(start)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: start,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          start = picked;
                          if (end.isBefore(start)) end = start;
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('To'),
                    subtitle: Text(fmtDayMonthYear(end)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: end,
                        firstDate: start,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => end = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Add trip',
                    style: TextStyle(color: PB.rose),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      await widget.state.addTrip(start, end);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFE2E0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF502332).withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: PB.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: PB.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeCell extends StatelessWidget {
  const _RangeCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: PB.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetButton extends StatelessWidget {
  const _SetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE8C9C4), width: 1.5),
        backgroundColor: Colors.white,
        foregroundColor: PB.ink,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ComingRow extends StatelessWidget {
  const _ComingRow({
    required this.day,
    required this.color,
    required this.title,
    required this.sub,
    required this.when,
  });

  final String day;
  final Color color;
  final String title;
  final String sub;
  final String when;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: PB.muted),
                ),
              ],
            ),
          ),
          if (when.isNotEmpty)
            Text(
              when,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: PB.rose,
              ),
            ),
        ],
      ),
    );
  }
}
