import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/meal_dialog.dart';

/// Home screen. Period side shows real data only — when nothing is logged
/// yet, the hero says so plainly and invites her to log her first period.
/// No sample/fake period data, ever.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onGoToCalendar,
    required this.onGoToDiet,
    required this.onGoToSteps,
    required this.onGoToWater,
  });

  final AppState state;
  final VoidCallback onGoToCalendar;
  final VoidCallback onGoToDiet;
  final VoidCallback onGoToSteps;
  final VoidCallback onGoToWater;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = dateOnly(DateTime.now());
  late DateTime _viewMonth; // first of the month shown in the mini calendar

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final today = dateOnly(DateTime.now());
    final hasData = state.expectedNext != null;
    final daysToGo = state.daysToGo;
    final dayOfCycle = state.dayOfCycle;
    final phase = state.currentPhase;
    final meals = state.mealsForDay(today);
    final doneCount = meals.where((m) => state.isMealDone(today, m.id)).length;
    final overlapping = state.overlappingTrips;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PeriBuds',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'CYCLE & FOOD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: PB.muted,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showSettings(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBD9D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: PB.rose, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Hero — vibrant peach → pink → lavender gradient (reference Home V9).
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE8D9), Color(0xFFFFD9E2), Color(0xFFEDE7FA)],
              stops: [0.0, 0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF502332).withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            children: [
              // "WEDNESDAY · 18 NOVEMBER" eyebrow across the top of the hero.
              Text(
                fmtHeroDate(today).toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: PB.softText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ring — plain WHITE ring, no progress arc (approved
                  // hero: the ring is a uniform white circle).
                  SizedBox(
                    width: 126,
                    height: 126,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 9),
                      ),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 84,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              // NEVER a negative number: overdue shows
                              // "15" + "days late", never "-15 days to go".
                              hasData && daysToGo != null
                                  ? (state.isOverdue
                                        ? '${state.daysLate}'
                                        : '$daysToGo')
                                  : '—',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: PB.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasData
                                  ? (state.isOverdue
                                        ? 'days late'
                                        : 'days to go')
                                  : 'log your first\nperiod',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: PB.softText,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPECTED NEXT PERIOD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: PB.rose,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // "Friday," in ink, "28 Nov" in rose — as approved.
                        hasData && state.expectedNext != null
                            ? RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                    color: PB.ink,
                                    fontFamily: 'Outfit',
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${fmtWeekdayFull(state.expectedNext!)},\n',
                                    ),
                                    TextSpan(
                                      text: fmtDayMonth(state.expectedNext!),
                                      style: const TextStyle(color: PB.rose),
                                    ),
                                  ],
                                ),
                              )
                            : const Text(
                                'Not known yet',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  height: 1.15,
                                ),
                              ),
                        const SizedBox(height: 4),
                        Text(
                          hasData && dayOfCycle != null
                              ? '${state.cycleDayLabel} · $phase phase. ${_phaseNote(phase)}'
                              : 'Log your first period and I will learn your pattern.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: PB.softText,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Chips — intrinsic-width pills that WRAP to a second row
              // ("Last period · 1 Nov" + "Ovulation · 14 Nov", then
              // "Cycle · 28 days"), as approved.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    label: 'Last period',
                    value: state.lastPeriodStart != null
                        ? fmtDayMonth(state.lastPeriodStart!)
                        : '—',
                  ),
                  _HeroChip(
                    // Next ovulation still in the future — the current
                    // cycle's ovulation date may already be past (overdue).
                    label: 'Ovulation',
                    value: state.nextOvulationDay != null
                        ? fmtDayMonth(state.nextOvulationDay!)
                        : '—',
                  ),
                  _HeroChip(
                    label: 'Cycle',
                    value: hasData ? '${state.avgCycle} days' : '—',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Phase bar
              _PhaseBar(current: hasData ? phase : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _HeroAction(
                      label: 'Log period',
                      dark: true,
                      onTap: widget.onGoToCalendar,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _HeroAction(
                      label: 'Symptoms',
                      onTap: () => _showSymptoms(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _HeroAction(
                      label: 'Mood',
                      onTap: () => _showMood(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Travel overlap warning
        if (overlapping.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: PB.amberBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF5D9A8)),
            ),
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.luggage_outlined, size: 18, color: PB.amberText),
                    SizedBox(width: 8),
                    Text(
                      'Heads up — your trip overlaps',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A5A2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your expected period (${state.expectedNext != null ? fmtRangeShort(state.expectedNext!, state.expectedNext!.add(Duration(days: state.avgPeriod - 1))) : ''}) falls during your trip. Pack pads, pain relief and extra clothes.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Color(0xFF7A5A2A),
                  ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PackChip('Sanitary pads'),
                    _PackChip('Pain relief'),
                    _PackChip('Extra clothes'),
                    _PackChip('Hot water bag'),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Wellbeing additions. Existing cycle, calendar, and meal flows stay.
        const SizedBox(height: 12),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today’s wellbeing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Text(
                'Movement & hydration',
                style: TextStyle(fontSize: 12, color: PB.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _WellbeingTile(
                      icon: Icons.directions_walk,
                      title: 'Steps',
                      value: '${state.stepCount}',
                      detail:
                          'of ${state.stepGoal} · ~${state.stepCaloriesEstimate.round()} kcal',
                      color: PB.roseSoft,
                      onTap: widget.onGoToSteps,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WellbeingTile(
                      icon: Icons.water_drop_outlined,
                      title: 'Water',
                      value:
                          '${(state.waterTodayMl / 1000).toStringAsFixed(2)} L',
                      detail:
                          'of ${(state.waterGoalMl / 1000).toStringAsFixed(1)} L goal',
                      color: const Color(0xFFEAF6FB),
                      onTap: widget.onGoToWater,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Calendar card — month header with ‹ › arrows, today is a dark
        // filled square here (approved Home), plus the "Today, 18 Nov — …"
        // strip underneath.
        const SizedBox(height: 12),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonthCalendar(
                state: state,
                year: _viewMonth.year,
                month: _viewMonth.month,
                selectedDay: _selectedDay,
                todayDark: true,
                showMonthHeader: true,
                onPrevMonth: () => setState(
                  () => _viewMonth = DateTime(
                    _viewMonth.year,
                    _viewMonth.month - 1,
                    1,
                  ),
                ),
                onNextMonth: () => setState(
                  () => _viewMonth = DateTime(
                    _viewMonth.year,
                    _viewMonth.month + 1,
                    1,
                  ),
                ),
                onDayTap: (d) {
                  setState(() => _selectedDay = d);
                  widget.onGoToCalendar();
                },
              ),
              if (hasData) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: PB.rosePale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    _todayNote(state, today),
                    style: const TextStyle(
                      fontSize: 13,
                      color: PB.softText,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Gentle note — lavender card, bold lead-in, as approved.
        if (hasData) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: PB.lavender,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: PB.softText,
                  fontFamily: 'Outfit',
                ),
                children: [
                  const TextSpan(
                    text: 'A gentle note for this phase: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: PB.ink,
                    ),
                  ),
                  TextSpan(text: _gentleNoteText(phase)),
                ],
              ),
            ),
          ),
        ],

        // Today's food
        const SizedBox(height: 12),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's food",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Row(
                    children: [
                      if (meals.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: PB.greenBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$doneCount of ${meals.length} done',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: PB.green,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _addMealToday(context),
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
              const SizedBox(height: 2),
              const Text(
                'Your own chart · Tap to mark done',
                style: TextStyle(fontSize: 13, color: PB.muted),
              ),
              if (meals.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FoodProgress(done: doneCount, total: meals.length),
                const SizedBox(height: 4),
              ],
              if (meals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No meals yet — add your first one below.',
                    style: TextStyle(fontSize: 13, color: PB.softText),
                  ),
                )
              else
                ...meals.map(
                  (m) => _MealRow(state: state, day: today, meal: m),
                ),
              const SizedBox(height: 12),
              DashedButton(
                label: '+ Add meal',
                onPressed: () => _addMealToday(context),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onGoToDiet,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Open diet →',
                  style: TextStyle(
                    color: PB.rose,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Add a meal from Home (the + in Today's food and the dashed
  /// "+ Add meal" button) — same popup as the Diet tab.
  Future<void> _addMealToday(BuildContext context) async {
    final result = await showMealDialog(context, widget.state);
    if (result == null) return;
    final today = dateOnly(DateTime.now());
    await widget.state.addMeal(today, result);
    if (widget.state.dietMode == 'diff' && result.repeat != 'today') {
      final targets = widget.state.repeatTargets(
        result.repeat,
        result.pickDays,
        from: today,
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
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(state: widget.state),
    );
  }

  void _showSymptoms(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final selected = widget.state.symptomsByDay[dateKey(today)] ?? [];
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
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppState.symptomOptions.map((s) {
                final on = selected.contains(s);
                return GestureDetector(
                  onTap: () {
                    widget.state.toggleSymptom(today, s);
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

  void _showMood(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final current = widget.state.moodByDay[dateKey(today)];
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
            const Text(
              'Your mood today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppState.moodOptions.map((m) {
                final on = current == m;
                return GestureDetector(
                  onTap: () {
                    widget.state.setMood(today, m);
                    Navigator.of(context).pop();
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
                      m,
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
}

/// Short phase note for the hero line ("Day 18 of 28 · Luteal phase.
/// Calm, steady days.").
String _phaseNote(String phase) {
  switch (phase) {
    case 'Luteal':
      return 'Calm, steady days.';
    case 'Menstrual':
      return 'Rest and stay warm.';
    case 'Follicular':
      return 'Energy is rising.';
    case 'Ovulation':
      return 'Ovulation is near.';
    default:
      return '';
  }
}

/// Gentle-note body for the lavender card ("A gentle note for this phase:
/// you may feel a little more tired …").
String _gentleNoteText(String phase) {
  switch (phase) {
    case 'Luteal':
      return 'you may feel a little more tired or crave comfort food. Warm meals, water and an early night help.';
    case 'Menstrual':
      return 'rest, stay warm and take it slow today.';
    case 'Follicular':
      return 'energy is usually rising — fresh food and a little movement feel good.';
    case 'Ovulation':
      return 'ovulation is near — stay hydrated and listen to your body.';
    default:
      return 'be gentle with yourself today.';
  }
}

/// "Today, 18 Nov — Day 18. Past your fertile window. Expected next
/// period: 28 Nov." — the strip under the Home mini-calendar.
String _todayNote(AppState state, DateTime today) {
  final next = state.expectedNext;
  final doc = state.dayOfCycle;
  if (next == null || doc == null) return '';
  final fertile = state.nextFertileDays;
  String fertileBit;
  if (state.isOverdue) {
    fertileBit =
        'Your period is ${state.daysLate} day${state.daysLate == 1 ? '' : 's'} late.';
  } else if (fertile.isNotEmpty &&
      !today.isBefore(fertile.first) &&
      !today.isAfter(fertile.last)) {
    fertileBit = 'You are in your fertile window.';
  } else if (fertile.isNotEmpty && today.isAfter(fertile.last)) {
    fertileBit = 'Past your fertile window.';
  } else if (fertile.isNotEmpty) {
    fertileBit =
        'Fertile window: ${fmtDayMonth(fertile.first)} – ${fmtDayMonth(fertile.last)}.';
  } else {
    fertileBit = '';
  }
  return 'Today, ${fmtDayMonth(today)} — Day $doc. $fertileBit Expected next period: ${fmtDayMonth(next)}.';
}

class _WellbeingTile extends StatelessWidget {
  const _WellbeingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title, value, detail;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: title == 'Water' ? const Color(0xFF418BB5) : PB.rose,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: PB.softText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: PB.ink,
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: PB.softText),
            ),
            const SizedBox(height: 6),
            Text(
              title == 'Water' ? 'Log water ›' : 'View steps ›',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: PB.rose,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // One-line pill — "Last period · 1 Nov" — intrinsic width, as approved.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12.5,
            fontFamily: 'Outfit',
            color: PB.ink,
          ),
          children: [
            TextSpan(
              text: '$label · ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: PB.softText,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseBar extends StatelessWidget {
  const _PhaseBar({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    // ONE continuous 4-segment bar (Menstrual pink / Follicular lavender
    // / Ovulation green / Luteal rose) with the labels underneath and a
    // red dot on the active phase — as approved. Segments are NOT equal:
    // flex 5 / 9 / 5 / 9, matching the approved bar's proportions.
    const phases = ['Menstrual', 'Follicular', 'Ovulation', 'Luteal'];
    const colors = [
      Color(0xFFF4A9B2),
      Color(0xFFC9B8E8),
      Color(0xFFA8CBB8),
      PB.rose,
    ];
    const flexes = [5, 9, 5, 9];
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: List.generate(
              4,
              (i) => Expanded(
                flex: flexes[i],
                child: Container(height: 8, color: colors[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (i) {
            final p = phases[i];
            final on = current == p;
            // First label left, middle two centred, last right.
            final align = i == 0
                ? MainAxisAlignment.start
                : i == 3
                ? MainAxisAlignment.end
                : MainAxisAlignment.center;
            return Expanded(
              flex: flexes[i],
              child: Row(
                mainAxisAlignment: align,
                children: [
                  if (on)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: PB.rose,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      p,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                        color: on ? PB.rose : PB.softText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.label,
    required this.onTap,
    this.dark = false,
  });

  final String label;
  final VoidCallback onTap;
  // "Log period" is a DARK pill; Symptoms / Mood are white pills.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? PB.dark : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF502332).withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : PB.ink,
          ),
        ),
      ),
    );
  }
}

class _PackChip extends StatelessWidget {
  const _PackChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 13, color: PB.green),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Rose → green gradient progress bar for the food card.
class _FoodProgress extends StatelessWidget {
  const _FoodProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final f = total == 0 ? 0.0 : done / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: const Color(0xFFF8ECE9),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: f,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [PB.rose, Color(0xFF5E9C7A)]),
            ),
          ),
        ),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.state, required this.day, required this.meal});

  final AppState state;
  final DateTime day;
  final Meal meal;

  /// Coloured letter tile by meal type — B tan, L mint, S lavender,
  /// D pink — as approved.
  (Color, Color) _tile() {
    switch (meal.type) {
      case 'Lunch':
        return (const Color(0xFFDCEFE7), PB.green);
      case 'Snack':
        return (PB.lavender, const Color(0xFF5F4DA3));
      case 'Dinner':
        return (PB.roseLight, PB.roseDark);
      case 'Breakfast':
      default:
        return (const Color(0xFFF5E3C8), const Color(0xFF8A6A2A));
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = state.isMealDone(day, meal.id);
    final (bg, fg) = _tile();
    final letter = meal.type.isNotEmpty ? meal.type[0].toUpperCase() : '•';
    return GestureDetector(
      onTap: () => state.toggleMealDone(day, meal.id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: done ? 0.55 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'Outfit',
                          color: PB.ink,
                        ),
                        children: [
                          TextSpan(
                            text: meal.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' · ${to12h(meal.time24)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: PB.softText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.description,
                      style: const TextStyle(fontSize: 13, color: PB.softText),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
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
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.state});

  final AppState state;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Everything stays on your phone. No account, no cloud.',
            style: TextStyle(fontSize: 12.5, color: PB.softText),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discreet period reminders',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Switch(
                value: state.periodRemindersOn,
                onChanged: (v) => state.setPeriodRemindersOn(v),
                activeThumbColor: PB.rose,
              ),
            ],
          ),
          const Text(
            'A gentle reminder 3 days before, 1 day before, and on the morning of your expected date. It never says the word “period”.',
            style: TextStyle(fontSize: 12, color: PB.softText, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meal reminders',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Switch(
                value: state.mealRemindersOn,
                onChanged: (v) => state.setMealRemindersOn(v),
                activeThumbColor: PB.rose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GhostPillButton(
            label: 'Erase all my data',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Erase everything?'),
                  content: const Text(
                    'This deletes all periods, meals, reminders and trips from this phone. It cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(true),
                      child: const Text(
                        'Erase',
                        style: TextStyle(color: PB.rose),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await state.eraseAllData();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'PeriBuds 1.0.4 · Made with care, fully offline',
              style: TextStyle(fontSize: 11, color: PB.muted),
            ),
          ),
        ],
      ),
    );
  }
}
