import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/meal_dialog.dart';

/// Diet screen.
///
/// She creates her own chart — same for all days, or different each day.
/// Add meal opens as a POPUP. Repeat: Tomorrow / This week / Weekdays /
/// Pick days, with dots on repeated days + status row with Undo.
/// Diet demo data only, one-tap "Remove all demo data".
class DietScreen extends StatefulWidget {
  const DietScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  int _selDayOffset = 0; // 0 = today, within current week strip
  String _repeatChoice = '';
  List<int> _repeatPick = [];

  DateTime get _today => dateOnly(DateTime.now());

  // The day strip starts on TODAY and runs 7 days forward (WED 18 …
  // TUE 24), as approved — not a Mon–Sun calendar week.
  List<DateTime> get _stripDays =>
      List.generate(7, (i) => _today.add(Duration(days: i)));

  DateTime get _selectedDay {
    final days = _stripDays;
    final idx = _selDayOffset.clamp(0, 6);
    return days[idx];
  }

  @override
  void initState() {
    super.initState();
    _selDayOffset = 0; // today, first in the strip
  }

  Future<void> _openMealDialog({Meal? existing}) async {
    final result = await showMealDialog(
      context,
      widget.state,
      existing: existing,
    );
    if (result == null) return;
    final day = _selectedDay;
    if (existing == null) {
      // New meal: add to the selected day, then apply its repeat choice
      // by copying it to the target days (diff mode only).
      await widget.state.addMeal(day, result);
      if (widget.state.dietMode == 'diff' && result.repeat != 'today') {
        final targets = widget.state.repeatTargets(
          result.repeat,
          result.pickDays,
          from: day,
        );
        for (final t in targets) {
          await widget.state.addMeal(
            t,
            result.copyWithNewId(
              '${DateTime.now().millisecondsSinceEpoch}-${t.day}',
            ),
          );
        }
      }
    } else {
      await widget.state.updateMeal(day, result);
    }
  }

  Future<void> _applyRepeat(String choice) async {
    final day = _selectedDay;
    setState(() {
      _repeatChoice = choice;
      if (choice == 'pick' && _repeatPick.isEmpty) _repeatPick = [1];
    });
    if (choice == 'pick') return;
    await widget.state.repeatTodayChart(choice, [], day);
  }

  Future<void> _applyPickDays() async {
    await widget.state.repeatTodayChart('pick', _repeatPick, _selectedDay);
    setState(() => _repeatChoice = 'pick');
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final days = _stripDays;
    final selectedDay = _selectedDay;
    final isToday = selectedDay == _today;
    final meals = state.mealsForDay(selectedDay);
    final doneCount =
        meals.where((m) => state.isMealDone(selectedDay, m.id)).length;
    final skipped = meals.length - doneCount;
    final repeated = state.repeatedDayKeys;

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
                  'Diet',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'YOUR FOOD, YOUR WAY',
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
              child: const Icon(
                Icons.favorite,
                color: PB.rose,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Demo banner (diet only)
        if (!state.demoCleared && state.demoSeeded) ...[
          Container(
            decoration: BoxDecoration(
              color: PB.amberBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3D9A4), width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sample diet — demo data, just to show how it looks',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A6A2A)),
                  ),
                ),
                // Real gap + padding so "Remove all" never runs into
                // the text at the right edge (v1.0.0 bug, screenshot).
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Remove demo data?'),
                        content: const Text(
                          'This clears the sample meals and reminders so you can start from empty.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Keep it'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text(
                              'Remove all',
                              style: TextStyle(color: PB.rose),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await state.clearDemoData();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Remove all',
                    style: TextStyle(
                      color: PB.rose,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Same / Different toggle (reference: #F8ECE9 pill, no shadow).
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8ECE9),
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _ModeButton(
                label: 'Same for all days',
                selected: state.dietMode == 'same',
                onTap: () => state.setDietMode('same'),
              ),
              _ModeButton(
                label: 'Different each day',
                selected: state.dietMode == 'diff',
                onTap: () => state.setDietMode('diff'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Day strip
        Row(
          children: List.generate(7, (i) {
            final d = days[i];
            final isSel = i == _selDayOffset;
            final isTodayCell = d == _today;
            final hasDot = repeated.contains(dateKey(d));
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selDayOffset = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSel ? PB.rose : Colors.white,
                    border: isTodayCell && !isSel
                        ? Border.all(color: PB.rose, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: PB.rose.withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: const Color(0xFF502332)
                                  .withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        dowShort(d).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : PB.softText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSel ? Colors.white : PB.ink,
                        ),
                      ),
                      if (hasDot)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : PB.rose,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Today's food card
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday
                        ? "Today's food"
                        : '${weekdayShort[selectedDay.weekday - 1]} ${selectedDay.day} ${fmtShortMonth(selectedDay)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Row(
                    children: [
                      if (meals.isNotEmpty)
                        Text(
                          '$doneCount of ${meals.length} done',
                          style: const TextStyle(
                            fontSize: 13,
                            color: PB.muted,
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openMealDialog(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: PB.rose,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: PB.rose.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (meals.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 6,
                    color: const Color(0xFFF8ECE9),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: meals.isEmpty
                          ? 0
                          : doneCount / meals.length,
                      child: Container(color: PB.rose),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$doneCount done · $skipped to go',
                  style: const TextStyle(fontSize: 12, color: PB.muted),
                ),
                const SizedBox(height: 4),
              ],
              if (meals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Your chart is empty.\nAdd breakfast, lunch, dinner — whatever you eat, in your own words.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: PB.muted,
                        height: 1.55,
                      ),
                    ),
                  ),
                )
              else
                ...meals.map(
                  (m) => _DietMealRow(
                    state: state,
                    day: selectedDay,
                    meal: m,
                    onEdit: () => _openMealDialog(existing: m),
                  ),
                ),
              const SizedBox(height: 10),
              DashedButton(
                label: '+ Add meal',
                onPressed: () => _openMealDialog(),
              ),
              // Repeat status lives inside the food card (reference).
              if (state.canUndoRepeat) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.lastRepeatLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await state.undoRepeat();
                          setState(() => _repeatChoice = '');
                        },
                        child: const Text(
                          'Undo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: PB.rose,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (state.dietMode == 'diff') ...[
                const SizedBox(height: 10),
                GhostPillButton(
                  label: 'Copy today to all days',
                  onPressed: () => state.copyTodayToAllDays(selectedDay),
                ),
              ],
            ],
          ),
        ),

        // Repeat today's chart
        const SizedBox(height: 12),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Repeat today's chart",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Copy to…',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PB.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Made a good chart? Repeat it instead of typing it again.',
                style: TextStyle(fontSize: 12, color: PB.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RepeatChip(
                    label: 'Tomorrow',
                    selected: _repeatChoice == 'tomorrow',
                    onTap: () => _applyRepeat('tomorrow'),
                  ),
                  _RepeatChip(
                    label: 'This week',
                    selected: _repeatChoice == 'week',
                    onTap: () => _applyRepeat('week'),
                  ),
                  _RepeatChip(
                    label: 'Weekdays',
                    selected: _repeatChoice == 'weekdays',
                    onTap: () => _applyRepeat('weekdays'),
                  ),
                  _RepeatChip(
                    label: 'Pick days',
                    selected: _repeatChoice == 'pick',
                    onTap: () => _applyRepeat('pick'),
                  ),
                ],
              ),
              if (_repeatChoice == 'pick') ...[
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.35,
                  children: List.generate(6, (i) {
                    final day = _today.add(Duration(days: i + 1));
                    final selected = _repeatPick.contains(i + 1);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _repeatPick.remove(i + 1);
                        } else {
                          _repeatPick.add(i + 1);
                        }
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? PB.rose : Colors.white,
                          border: Border.all(
                            color: selected
                                ? PB.rose
                                : const Color(0xFFE8C9C4),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dowShort(day),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF8A6A72),
                              ),
                            ),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: selected ? Colors.white : PB.ink,
                              ),
                            ),
                            Text(
                              fmtShortMonth(day),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF8A6A72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                RosePillButton(
                  label:
                      'Apply to ${_repeatPick.length} day${_repeatPick.length == 1 ? '' : 's'}',
                  onPressed: _applyPickDays,
                ),
              ],
              // Undo lives in the food card now (reference layout);
              // nothing repeats here.
            ],
          ),
        ),

        // Reminders
        const SizedBox(height: 12),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminders',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  Switch(
                    value: state.mealRemindersOn,
                    onChanged: (v) => state.setMealRemindersOn(v),
                    activeThumbColor: PB.rose,
                  ),
                ],
              ),
              // The switch in the card head toggles meal reminders.
              const SizedBox(height: 2),
              const Text(
                'Meal reminders — a gentle nudge when a meal is due.',
                style: TextStyle(fontSize: 12, color: PB.muted),
              ),
              ...state.customReminders.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: PB.lavender,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.alarm_outlined,
                          size: 18,
                          color: Color(0xFF5F4DA3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.text,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              to12h(r.time24),
                              style: const TextStyle(
                                fontSize: 12,
                                color: PB.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: r.on,
                        onChanged: (_) => state.toggleCustomReminder(r.id),
                        activeThumbColor: PB.rose,
                      ),
                      IconButton(
                        onPressed: () => state.deleteCustomReminder(r.id),
                        icon: const Icon(Icons.close, size: 16, color: PB.rose),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _addCustomReminder(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '+ Add custom reminder',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PB.rose,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                meals.isEmpty
                    ? 'Skipped today: nothing yet'
                    : skipped == 0
                        ? 'Skipped today: nothing yet'
                        : 'Skipped today: $skipped meal${skipped == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 13, color: PB.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addCustomReminder(BuildContext context) async {
    final textCtrl = TextEditingController();
    TimeOfDay time = const TimeOfDay(hour: 11, minute: 0);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add custom reminder',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Drink water',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time'),
                    subtitle: Text(
                      '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) {
                        setDialogState(() => time = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop({
                    'text': textCtrl.text.trim(),
                    'time': to24h(time.hour, time.minute),
                  }),
                  child: const Text(
                    'Add reminder',
                    style: TextStyle(color: PB.rose),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null && (result['text'] as String).isNotEmpty) {
      await widget.state.addCustomReminder(
        CustomReminder(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          text: result['text'] as String,
          time24: result['time'] as String,
        ),
      );
    }
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? PB.rose : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: PB.rose.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : PB.softText,
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatChip extends StatelessWidget {
  const _RepeatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? PB.rose : Colors.white,
          border: Border.all(
            color: selected ? PB.rose : const Color(0xFFE8C9C4),
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: PB.rose.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : PB.ink,
          ),
        ),
      ),
    );
  }
}

class _DietMealRow extends StatelessWidget {
  const _DietMealRow({
    required this.state,
    required this.day,
    required this.meal,
    required this.onEdit,
  });

  final AppState state;
  final DateTime day;
  final Meal meal;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final done = state.isMealDone(day, meal.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => state.toggleMealDone(day, meal.id),
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: done ? PB.green : Colors.white,
                border: Border.all(
                  color: done ? PB.green : const Color(0xFFE8C9C4),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Tap the meal itself to edit it (same Add-meal popup).
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      // Done meal's name is muted grey — but its time
                      // stays full rose (approved Diet screen).
                      color: done ? const Color(0xFFB39AA2) : PB.ink,
                    ),
                  ),
                  Text(
                    to12h(meal.time24),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PB.rose,
                    ),
                  ),
                  if (meal.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meal.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: done ? PB.muted : PB.softText,
                        height: 1.45,
                      ),
                    ),
                  ],
                    if (meal.repeat != 'today')
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBD9D6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Repeats: ${meal.repeatLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8F2F3D),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Right column, as approved: "Bell On" / "Bell Off" text,
          // with a small × delete tile beneath it.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => state.toggleMealRemind(day, meal.id),
                child: Text(
                  meal.remind ? 'Bell On' : 'Bell Off',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: meal.remind
                        ? PB.rose
                        : const Color(0xFFB39AA2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => state.deleteMeal(day, meal.id),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 15,
                    color: PB.rose,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
