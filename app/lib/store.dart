import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'notifications.dart';
import 'utils.dart';

const _storeKey = 'peribuds_state_v1';

/// App state, persisted locally as JSON in SharedPreferences.
/// Fully offline — no account, no cloud, no backend, no telemetry.
class AppState extends ChangeNotifier {
  AppState();

  bool _loaded = false;
  bool get loaded => _loaded;

  // --- Period (starts EMPTY, never seeded) ---
  List<PeriodRange> periods = [];

  // --- Diet ---
  String dietMode = 'diff'; // 'same' | 'diff'
  List<Meal> templateMeals = []; // used when dietMode == 'same'
  Map<String, List<Meal>> mealsByDay = {}; // dateKey -> meals, diff mode
  Map<String, Set<String>> doneByDay = {}; // dateKey -> done meal ids
  List<CustomReminder> customReminders = [];
  bool mealRemindersOn = true;
  bool periodRemindersOn = true;
  // Wellbeing additions. Records remain in the same private, local store.
  int stepGoal = 10000;
  int stepCount = 0;
  int waterGoalMl = 2000;
  int waterTodayMl = 0;
  String wellbeingDayKey = '';
  List<Map<String, dynamic>> waterEntries = [];
  bool demoCleared = false;
  bool demoSeeded = false;

  // --- Symptoms / mood, keyed by date ---
  Map<String, List<String>> symptomsByDay = {};
  Map<String, String> moodByDay = {};

  // --- Travel ---
  List<Trip> trips = [];

  // --- Repeat undo snapshot ---
  Map<String, List<Meal>>? _lastRepeatBackup;
  String _lastRepeatLabel = '';

  String get lastRepeatLabel => _lastRepeatLabel;
  bool get canUndoRepeat => _lastRepeatBackup != null;

  // ---------------------------------------------------------------- load/save

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _fromJson(json);
      } catch (_) {
        // Corrupt state: start fresh rather than crash.
        periods = [];
      }
    }
    if (!demoSeeded && !demoCleared) {
      // Diet demo data only. Period side stays empty.
      templateMeals = demoMeals();
      final todayKey = dateKey(DateTime.now());
      mealsByDay[todayKey] = demoMeals();
      customReminders = demoReminders();
      demoSeeded = true;
      await _save();
    }
    _loaded = true;
    notifyListeners();
    // Schedule discreet reminders for the predicted period + today's meals.
    await NotificationService.instance.rescheduleAll(this);
  }

  void _fromJson(Map<String, dynamic> json) {
    periods = (json['periods'] as List<dynamic>? ?? [])
        .map((e) => PeriodRange.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    dietMode = json['dietMode'] as String? ?? 'diff';
    templateMeals = (json['templateMeals'] as List<dynamic>? ?? [])
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList();
    mealsByDay = {};
    (json['mealsByDay'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      mealsByDay[k] = (v as List<dynamic>)
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    doneByDay = {};
    (json['doneByDay'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      doneByDay[k] = (v as List<dynamic>).map((e) => e.toString()).toSet();
    });
    customReminders = (json['customReminders'] as List<dynamic>? ?? [])
        .map((e) => CustomReminder.fromJson(e as Map<String, dynamic>))
        .toList();
    mealRemindersOn = json['mealRemindersOn'] as bool? ?? true;
    periodRemindersOn = json['periodRemindersOn'] as bool? ?? true;
    stepGoal = (json['stepGoal'] as num?)?.toInt() ?? 10000;
    stepCount = (json['stepCount'] as num?)?.toInt() ?? 0;
    waterGoalMl = (json['waterGoalMl'] as num?)?.toInt() ?? 2000;
    waterTodayMl = (json['waterTodayMl'] as num?)?.toInt() ?? 0;
    wellbeingDayKey = json['wellbeingDayKey'] as String? ?? '';
    waterEntries = (json['waterEntries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    _rollWellbeingDayIfNeeded();
    demoCleared = json['demoCleared'] as bool? ?? false;
    demoSeeded = json['demoSeeded'] as bool? ?? false;
    symptomsByDay = {};
    (json['symptomsByDay'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      symptomsByDay[k] =
          (v as List<dynamic>).map((e) => e.toString()).toList();
    });
    moodByDay = Map<String, String>.from(
      json['moodByDay'] as Map<String, dynamic>? ?? {},
    );
    trips = (json['trips'] as List<dynamic>? ?? [])
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _toJson() => {
        'periods': periods.map((p) => p.toJson()).toList(),
        'dietMode': dietMode,
        'templateMeals': templateMeals.map((m) => m.toJson()).toList(),
        'mealsByDay': mealsByDay.map(
          (k, v) => MapEntry(k, v.map((m) => m.toJson()).toList()),
        ),
        'doneByDay': doneByDay.map(
          (k, v) => MapEntry(k, v.toList()),
        ),
        'customReminders': customReminders.map((r) => r.toJson()).toList(),
        'mealRemindersOn': mealRemindersOn,
        'periodRemindersOn': periodRemindersOn,
        'stepGoal': stepGoal,
        'stepCount': stepCount,
        'waterGoalMl': waterGoalMl,
        'waterTodayMl': waterTodayMl,
        'wellbeingDayKey': wellbeingDayKey,
        'waterEntries': waterEntries,
        'demoCleared': demoCleared,
        'demoSeeded': demoSeeded,
        'symptomsByDay': symptomsByDay,
        'moodByDay': moodByDay,
        'trips': trips.map((t) => t.toJson()).toList(),
      };

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(_toJson()));
  }

  Future<void> _mutate() async {
    await _save();
    notifyListeners();
  }

  Future<void> rescheduleNotifications() async {
    await NotificationService.instance.rescheduleAll(this);
  }

  void _rollWellbeingDayIfNeeded() {
    final today = dateKey(DateTime.now());
    if (wellbeingDayKey != today) {
      wellbeingDayKey = today;
      stepCount = 0;
      waterTodayMl = 0;
      waterEntries = [];
    }
  }

  double get stepCaloriesEstimate => stepCount * 0.04;

  Future<void> setStepGoal(int value) async {
    if (value < 1) return;
    stepGoal = value;
    await _mutate();
  }

  Future<void> recordSensorSteps(int value) async {
    _rollWellbeingDayIfNeeded();
    final rounded = value < 0 ? 0 : value - (value % 8);
    if (rounded == stepCount) return;
    stepCount = rounded;
    await _mutate();
  }

  Future<void> ensureWellbeingDay() async {
    final oldKey = wellbeingDayKey;
    _rollWellbeingDayIfNeeded();
    if (oldKey != wellbeingDayKey) await _mutate();
  }

  Future<void> setWaterGoalMl(int value) async {
    if (value < 1) return;
    waterGoalMl = value;
    await _mutate();
  }

  Future<void> addWater(int millilitres) async {
    if (millilitres < 1) return;
    _rollWellbeingDayIfNeeded();
    waterTodayMl += millilitres;
    waterEntries.add({
      'ml': millilitres,
      'time': DateTime.now().toIso8601String(),
    });
    await _mutate();
  }

  Future<void> undoLastWater() async {
    if (waterEntries.isEmpty) return;
    final last = waterEntries.removeLast();
    waterTodayMl = max(0, waterTodayMl - ((last['ml'] as num?)?.toInt() ?? 0));
    await _mutate();
  }

  // ---------------------------------------------------------------- periods

  Set<String> get periodDayKeys {
    final out = <String>{};
    for (final p in periods) {
      var d = p.start;
      while (!d.isAfter(p.end)) {
        out.add(dateKey(d));
        d = d.add(const Duration(days: 1));
      }
    }
    return out;
  }

  bool isPeriodDay(DateTime day) => periodDayKeys.contains(dateKey(day));

  bool isRangeFullyMarked(DateTime start, DateTime end) {
    var d = start;
    while (!d.isAfter(end)) {
      if (!isPeriodDay(d)) return false;
      d = d.add(const Duration(days: 1));
    }
    return true;
  }

  /// Mark (or unmark) a whole start–end range at once.
  Future<void> togglePeriodRange(DateTime start, DateTime end) async {
    if (start.isAfter(end)) {
      final t = start;
      start = end;
      end = t;
    }
    start = dateOnly(start);
    end = dateOnly(end);
    if (isRangeFullyMarked(start, end)) {
      // Remove every day in the range.
      final keys = <String>{};
      var d = start;
      while (!d.isAfter(end)) {
        keys.add(dateKey(d));
        d = d.add(const Duration(days: 1));
      }
      periods = _removeDaysFromRanges(periods, keys);
    } else {
      // Add the range, merging with any overlapping ranges.
      periods = _addRange(periods, PeriodRange(start, end));
    }
    periods.sort((a, b) => a.start.compareTo(b.start));
    await _mutate();
    await rescheduleNotifications();
  }

  List<PeriodRange> _removeDaysFromRanges(
    List<PeriodRange> ranges,
    Set<String> keysToRemove,
  ) {
    final keptDays = <DateTime>{};
    for (final r in ranges) {
      var d = r.start;
      while (!d.isAfter(r.end)) {
        if (!keysToRemove.contains(dateKey(d))) keptDays.add(d);
        d = d.add(const Duration(days: 1));
      }
    }
    return _daysToRanges(keptDays);
  }

  List<PeriodRange> _addRange(List<PeriodRange> ranges, PeriodRange add) {
    final days = <DateTime>{};
    for (final r in ranges) {
      var d = r.start;
      while (!d.isAfter(r.end)) {
        days.add(d);
        d = d.add(const Duration(days: 1));
      }
    }
    var d = add.start;
    while (!d.isAfter(add.end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return _daysToRanges(days);
  }

  List<PeriodRange> _daysToRanges(Set<DateTime> days) {
    if (days.isEmpty) return [];
    final sorted = days.toList()..sort();
    final out = <PeriodRange>[];
    var start = sorted.first;
    var prev = sorted.first;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(prev).inDays == 1) {
        prev = sorted[i];
      } else {
        out.add(PeriodRange(start, prev));
        start = sorted[i];
        prev = sorted[i];
      }
    }
    out.add(PeriodRange(start, prev));
    return out;
  }

  // ------------------------------------------------------------ predictions

  /// Average cycle length (gap between period starts), default 28.
  int get avgCycle {
    if (periods.length < 2) return 28;
    final gaps = <int>[];
    for (var i = 1; i < periods.length; i++) {
      gaps.add(periods[i].start.difference(periods[i - 1].start).inDays);
    }
    if (gaps.isEmpty) return 28;
    return (gaps.reduce((a, b) => a + b) / gaps.length).round();
  }

  /// Average period length in days, default 5.
  int get avgPeriod {
    if (periods.isEmpty) return 5;
    final total =
        periods.map((p) => p.lengthDays).reduce((a, b) => a + b);
    return max(1, (total / periods.length).round());
  }

  DateTime? get lastPeriodStart =>
      periods.isEmpty ? null : periods.last.start;

  DateTime? get lastPeriodEnd =>
      periods.isEmpty ? null : periods.last.end;

  /// Expected next period start, or null until she logs her first period.
  DateTime? get expectedNext {
    final last = lastPeriodStart;
    if (last == null) return null;
    return last.add(Duration(days: avgCycle));
  }

  /// Days until expected next period (negative = overdue). Null if no data.
  int? get daysToGo {
    final next = expectedNext;
    if (next == null) return null;
    return dateOnly(next).difference(dateOnly(DateTime.now())).inDays;
  }

  /// True when the expected date has passed without a new period logged.
  /// NEVER show a negative day count anywhere — use [daysLate] instead.
  bool get isOverdue => daysToGo != null && daysToGo! < 0;

  /// Days past the expected date (0 when not overdue).
  int get daysLate => isOverdue ? -daysToGo! : 0;

  /// Human label for the countdown, never negative:
  /// "15 days late" / "Today" / "Tomorrow" / "in 3 days".
  String get daysToGoLabel {
    final d = daysToGo;
    if (d == null) return '';
    if (d < 0) return '${-d} day${-d == 1 ? '' : 's'} late';
    if (d == 0) return 'Today';
    if (d == 1) return 'Tomorrow';
    return 'in $d days';
  }

  /// Cycle-day line, honest when overdue — never "Day 44 of 28".
  /// Overdue: "Day 44 · 15 days overdue". Otherwise: "Day 18 of 28".
  String get cycleDayLabel {
    final doc = dayOfCycle;
    if (doc == null) return '';
    if (isOverdue) return 'Day $doc · $daysLate day${daysLate == 1 ? '' : 's'} overdue';
    return 'Day $doc of $avgCycle';
  }

  /// Next ovulation day that is still in the future (advances by whole
  /// cycles past an overdue one). Null until the first period is logged.
  DateTime? get nextOvulationDay {
    final first = ovulationDay;
    if (first == null) return null;
    var ovu = first;
    final today = dateOnly(DateTime.now());
    while (dateOnly(ovu).isBefore(today)) {
      ovu = ovu.add(Duration(days: avgCycle));
    }
    return ovu;
  }

  /// The NEXT fertile window that has not fully passed yet.
  /// With an overdue cycle the current window (e.g. 15–20 Oct) is in the
  /// past, so this advances by whole cycles to the next future window.
  List<DateTime> get nextFertileDays {
    var days = fertileDays;
    if (days.isEmpty) return [];
    final today = dateOnly(DateTime.now());
    while (dateOnly(days.last).isBefore(today)) {
      days = days.map((d) => d.add(Duration(days: avgCycle))).toList();
    }
    return days;
  }

  /// Predicted ovulation day (expected next − 14).
  DateTime? get ovulationDay {
    final next = expectedNext;
    if (next == null) return null;
    return next.subtract(const Duration(days: 14));
  }

  /// Fertile window: ovulation − 4 .. ovulation + 1, inclusive (6 days).
  /// Matches the approved calendar: ovulation 14 Nov → fertile 10–15 Nov.
  List<DateTime> get fertileDays {
    final ovu = ovulationDay;
    if (ovu == null) return [];
    return List.generate(6, (i) => ovu.subtract(Duration(days: 4 - i)));
  }

  Set<String> get fertileDayKeys =>
      fertileDays.map((d) => dateKey(d)).toSet();

  /// Predicted period days: expectedNext .. +avgPeriod−1.
  List<DateTime> get predictedPeriodDays {
    final next = expectedNext;
    if (next == null) return [];
    return List.generate(avgPeriod, (i) => next.add(Duration(days: i)));
  }

  Set<String> get predictedDayKeys =>
      predictedPeriodDays.map((d) => dateKey(d)).toSet();

  /// Day number within the current cycle (1-based), or null if no data.
  int? get dayOfCycle {
    final last = lastPeriodStart;
    if (last == null) return null;
    final diff = dateOnly(DateTime.now()).difference(last).inDays + 1;
    return diff < 1 ? null : diff;
  }

  /// Current phase label: Menstrual / Follicular / Ovulation / Luteal.
  String get currentPhase {
    final today = dateOnly(DateTime.now());
    if (isPeriodDay(today)) return 'Menstrual';
    final ovu = ovulationDay;
    if (ovu == null) return '—';
    if (fertileDayKeys.contains(dateKey(today))) return 'Ovulation';
    if (today.isBefore(ovu)) return 'Follicular';
    return 'Luteal';
  }

  /// Cycles for Reports: newest first, with length + late/on-time status.
  List<Map<String, dynamic>> get cyclesForReports {
    final out = <Map<String, dynamic>>[];
    for (var i = periods.length - 1; i >= 0; i--) {
      final p = periods[i];
      int? cycleLen;
      String status = 'On time';
      if (i > 0) {
        cycleLen = p.start.difference(periods[i - 1].start).inDays;
        final diff = cycleLen - avgCycle;
        if (diff >= 2) {
          status = '$diff days late';
        } else if (diff <= -2) {
          status = '${-diff} days early';
        }
      }
      out.add({
        'range': p,
        'cycleLen': cycleLen,
        'status': status,
        'ovulation': p.start.add(Duration(days: avgCycle - 14)),
        'fertileStart': p.start.add(Duration(days: avgCycle - 18)),
        'fertileEnd': p.start.add(Duration(days: avgCycle - 13)),
      });
    }
    return out;
  }

  /// "Mostly regular" insight for Reports. Names the month when exactly
  /// one cycle was late ("Sep was 2 days late — …"), as in the approved
  /// Reports screen; honest about the real logged data.
  String get regularityInsight {
    if (periods.length < 2) {
      return 'Log a couple more cycles and I will learn your pattern.';
    }
    final gaps = <int>[];
    for (var i = 1; i < periods.length; i++) {
      gaps.add(periods[i].start.difference(periods[i - 1].start).inDays);
    }
    final lateIdx = <int>[];
    for (var i = 0; i < gaps.length; i++) {
      if (gaps[i] - avgCycle >= 2) lateIdx.add(i);
    }
    if (lateIdx.isEmpty) {
      return 'Your cycles are regular — nice and steady.';
    }
    if (lateIdx.length == 1) {
      final i = lateIdx.first;
      final month = fmtShortMonth(periods[i + 1].start);
      final diff = gaps[i] - avgCycle;
      return '$month was $diff day${diff == 1 ? '' : 's'} late — nothing to worry about, but worth noting if it happens again.';
    }
    return 'Mostly regular — ${lateIdx.length} cycles started a couple of days late. Nothing to worry about, but worth noting if it happens again.';
  }

  /// Meals done / scheduled in the last 7 days.
  /// Reports: "Meals this week: 18 of 28 done — steady, not perfect,
  /// and that's fine."
  int get mealsThisWeekDone {
    final today = dateOnly(DateTime.now());
    var done = 0;
    for (var i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      for (final m in mealsForDay(d)) {
        if (isMealDone(d, m.id)) done++;
      }
    }
    return done;
  }

  int get mealsThisWeekTotal {
    final today = dateOnly(DateTime.now());
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += mealsForDay(today.subtract(Duration(days: i))).length;
    }
    return total;
  }

  /// Symptom → number of cycles (period start .. start+avgCycle) in which
  /// it was logged at least once. Reports shows "N cycles".
  Map<String, int> get symptomCycleCounts {
    final out = <String, int>{};
    if (periods.isEmpty) return out;
    for (final p in periods) {
      final windowEnd = p.start.add(Duration(days: avgCycle));
      final seen = <String>{};
      symptomsByDay.forEach((key, list) {
        final d = parseKey(key);
        if (!d.isBefore(p.start) && d.isBefore(windowEnd)) {
          seen.addAll(list);
        }
      });
      for (final s in seen) {
        out[s] = (out[s] ?? 0) + 1;
      }
    }
    return out;
  }

  // ------------------------------------------------------------------ diet

  /// Days in the last 28 where every meal on the chart was ticked done.
  /// Used by Reports ("Meals followed on X of 28 days").
  int get dietFollowedDays {
    final today = dateOnly(DateTime.now());
    var count = 0;
    for (var i = 0; i < 28; i++) {
      final d = today.subtract(Duration(days: i));
      final meals = mealsForDay(d);
      if (meals.isEmpty) continue;
      if (meals.every((m) => isMealDone(d, m.id))) count++;
    }
    return count;
  }

  /// True when any meals exist in the last 28 days.
  bool get hasRecentDiet {
    final today = dateOnly(DateTime.now());
    for (var i = 0; i < 28; i++) {
      if (mealsForDay(today.subtract(Duration(days: i))).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  List<Meal> mealsForDay(DateTime day) {
    if (dietMode == 'same') return templateMeals;
    return mealsByDay[dateKey(day)] ?? [];
  }

  bool isMealDone(DateTime day, String mealId) =>
      doneByDay[dateKey(day)]?.contains(mealId) ?? false;

  Future<void> toggleMealDone(DateTime day, String mealId) async {
    final key = dateKey(day);
    final set = doneByDay[key] ?? <String>{};
    if (set.contains(mealId)) {
      set.remove(mealId);
    } else {
      set.add(mealId);
    }
    doneByDay[key] = set;
    await _mutate();
  }

  Future<void> setDietMode(String mode) async {
    if (mode == dietMode) return;
    if (mode == 'same') {
      // Collapse today's chart into the shared template.
      templateMeals =
          mealsForDay(DateTime.now()).map((m) => m.copyWithNewId(m.id)).toList();
    } else {
      // Expand the shared template into today, keeping other days as-is.
      final key = dateKey(DateTime.now());
      mealsByDay[key] =
          templateMeals.map((m) => m.copyWithNewId(m.id)).toList();
    }
    dietMode = mode;
    await _mutate();
  }

  String _newId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

  Future<void> addMeal(DateTime day, Meal meal) async {
    if (dietMode == 'same') {
      templateMeals.add(meal);
      templateMeals.sort((a, b) => a.time24.compareTo(b.time24));
    } else {
      final key = dateKey(day);
      final list = mealsByDay[key] ?? [];
      list.add(meal);
      list.sort((a, b) => a.time24.compareTo(b.time24));
      mealsByDay[key] = list;
    }
    await _mutate();
    await rescheduleNotifications();
  }

  Future<void> updateMeal(DateTime day, Meal updated) async {
    if (dietMode == 'same') {
      final i = templateMeals.indexWhere((m) => m.id == updated.id);
      if (i >= 0) templateMeals[i] = updated;
      templateMeals.sort((a, b) => a.time24.compareTo(b.time24));
    } else {
      final key = dateKey(day);
      final list = mealsByDay[key] ?? [];
      final i = list.indexWhere((m) => m.id == updated.id);
      if (i >= 0) list[i] = updated;
      list.sort((a, b) => a.time24.compareTo(b.time24));
      mealsByDay[key] = list;
    }
    await _mutate();
    await rescheduleNotifications();
  }

  Future<void> deleteMeal(DateTime day, String mealId) async {
    if (dietMode == 'same') {
      templateMeals.removeWhere((m) => m.id == mealId);
    } else {
      final key = dateKey(day);
      mealsByDay[key]?.removeWhere((m) => m.id == mealId);
    }
    for (final set in doneByDay.values) {
      set.remove(mealId);
    }
    await _mutate();
  }

  Future<void> toggleMealRemind(DateTime day, String mealId) async {
    if (dietMode == 'same') {
      final i = templateMeals.indexWhere((m) => m.id == mealId);
      if (i >= 0) templateMeals[i].remind = !templateMeals[i].remind;
    } else {
      final list = mealsByDay[dateKey(day)];
      final i = list?.indexWhere((m) => m.id == mealId) ?? -1;
      if (i >= 0 && list != null) list[i].remind = !list[i].remind;
    }
    await _mutate();
    await rescheduleNotifications();
  }

  /// Target dates for a repeat choice, starting from [from] (exclusive).
  List<DateTime> repeatTargets(String repeat, List<int> pickDays,
      {DateTime? from}) {
    final base = dateOnly(from ?? DateTime.now());
    switch (repeat) {
      case 'tomorrow':
        return [base.add(const Duration(days: 1))];
      case 'week':
        return List.generate(6, (i) => base.add(Duration(days: i + 1)));
      case 'weekdays':
        final out = <DateTime>[];
        var d = base.add(const Duration(days: 1));
        while (out.length < 4) {
          if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) {
            out.add(d);
          }
          d = d.add(const Duration(days: 1));
        }
        return out;
      case 'pick':
        return pickDays.map((off) => base.add(Duration(days: off))).toList();
      case 'today':
      default:
        return [];
    }
  }

  /// Repeat today's whole chart to the target days (diff mode).
  /// Keeps a snapshot so she can Undo.
  Future<void> repeatTodayChart(
      String repeat, List<int> pickDays, DateTime today) async {
    final targets = repeatTargets(repeat, pickDays, from: today);
    if (targets.isEmpty) return;
    final todayMeals = mealsForDay(today);
    if (todayMeals.isEmpty) return;
    _lastRepeatBackup = {
      for (final e in mealsByDay.entries) e.key: List<Meal>.from(e.value),
    };
    _lastRepeatLabel = _repeatLabel(repeat, pickDays, targets);
    for (final target in targets) {
      final key = dateKey(target);
      mealsByDay[key] = todayMeals
          .map((m) => m.copyWithNewId(_newId()))
          .toList();
    }
    await _mutate();
  }

  String _repeatLabel(
      String repeat, List<int> pickDays, List<DateTime> targets) {
    switch (repeat) {
      case 'tomorrow':
        return 'Repeated for tomorrow · ${fmtDayMonth(targets.first)}';
      case 'week':
        return 'Repeated for this week · ${fmtDayMonth(targets.first)} – ${fmtDayMonth(targets.last)}';
      case 'weekdays':
        return 'Repeated for weekdays · ${targets.map(fmtDayMonth).join(', ')}';
      case 'pick':
        return 'Repeated for ${targets.map(fmtDayMonth).join(', ')}';
      default:
        return '';
    }
  }

  /// Copy today's chart to every day of this week.
  Future<void> copyTodayToAllDays(DateTime today) async {
    final days = weekDays(today);
    final todayMeals = mealsForDay(today);
    if (todayMeals.isEmpty) return;
    _lastRepeatBackup = {
      for (final e in mealsByDay.entries) e.key: List<Meal>.from(e.value),
    };
    _lastRepeatLabel = 'Copied to all days this week';
    for (final d in days) {
      if (dateKey(d) == dateKey(today)) continue;
      mealsByDay[dateKey(d)] =
          todayMeals.map((m) => m.copyWithNewId(_newId())).toList();
    }
    await _mutate();
  }

  Future<void> undoRepeat() async {
    if (_lastRepeatBackup == null) return;
    mealsByDay = {
      for (final e in _lastRepeatBackup!.entries)
        e.key: List<Meal>.from(e.value),
    };
    _lastRepeatBackup = null;
    _lastRepeatLabel = '';
    await _mutate();
  }

  /// Days that have a repeated chart (dot on the day strip).
  Set<String> get repeatedDayKeys {
    final todayKey = dateKey(DateTime.now());
    final out = <String>{};
    mealsByDay.forEach((key, meals) {
      if (key != todayKey && meals.isNotEmpty) out.add(key);
    });
    return out;
  }

  /// One-tap remove of all demo diet data → truly empty chart.
  Future<void> clearDemoData() async {
    templateMeals = [];
    mealsByDay = {};
    doneByDay = {};
    customReminders = [];
    demoCleared = true;
    await _mutate();
  }

  Future<void> addCustomReminder(CustomReminder r) async {
    customReminders.add(r);
    await _mutate();
    await rescheduleNotifications();
  }

  Future<void> deleteCustomReminder(String id) async {
    customReminders.removeWhere((r) => r.id == id);
    await _mutate();
    await rescheduleNotifications();
  }

  Future<void> toggleCustomReminder(String id) async {
    final i = customReminders.indexWhere((r) => r.id == id);
    if (i >= 0) customReminders[i].on = !customReminders[i].on;
    await _mutate();
    await rescheduleNotifications();
  }

  Future<void> setMealRemindersOn(bool value) async {
    mealRemindersOn = value;
    await _mutate();
    await rescheduleNotifications();
  }

  Future<void> setPeriodRemindersOn(bool value) async {
    periodRemindersOn = value;
    await _mutate();
    await rescheduleNotifications();
  }

  // ---------------------------------------------------------- symptoms/mood

  static const symptomOptions = [
    'Cramps',
    'Bloating',
    'Headache',
    'Tiredness',
    'Backache',
    'Mood swings',
    'Acne',
    'Nausea',
  ];

  static const moodOptions = ['Happy', 'Calm', 'Low', 'Irritable', 'Tired'];

  Future<void> toggleSymptom(DateTime day, String symptom) async {
    final key = dateKey(day);
    final list = symptomsByDay[key] ?? <String>[];
    if (list.contains(symptom)) {
      list.remove(symptom);
    } else {
      list.add(symptom);
    }
    symptomsByDay[key] = list;
    await _mutate();
  }

  Future<void> setMood(DateTime day, String mood) async {
    moodByDay[dateKey(day)] = mood;
    await _mutate();
  }

  // ---------------------------------------------------------------- travel

  Future<void> addTrip(DateTime start, DateTime end) async {
    trips.add(Trip(id: _newId(), start: dateOnly(start), end: dateOnly(end)));
    trips.sort((a, b) => a.start.compareTo(b.start));
    await _mutate();
  }

  Future<void> deleteTrip(String id) async {
    trips.removeWhere((t) => t.id == id);
    await _mutate();
  }

  /// Trips whose dates overlap the expected period window.
  List<Trip> get overlappingTrips {
    final next = expectedNext;
    if (next == null) return [];
    final pStart = next;
    final pEnd = next.add(Duration(days: avgPeriod - 1));
    return trips
        .where((t) => !t.end.isBefore(pStart) && !t.start.isAfter(pEnd))
        .toList();
  }

  // ------------------------------------------------------------ erase all

  Future<void> eraseAllData() async {
    periods = [];
    templateMeals = [];
    mealsByDay = {};
    doneByDay = {};
    customReminders = [];
    symptomsByDay = {};
    moodByDay = {};
    trips = [];
    stepCount = 0;
    waterTodayMl = 0;
    waterEntries = [];
    wellbeingDayKey = dateKey(DateTime.now());
    demoCleared = true;
    demoSeeded = true;
    await _mutate();
    await NotificationService.instance.cancelAll();
  }
}
