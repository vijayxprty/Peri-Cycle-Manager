import 'package:flutter_test/flutter_test.dart';
import 'package:peribuds/main.dart';
import 'package:peribuds/models.dart';
import 'package:peribuds/store.dart';
import 'package:peribuds/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('overdue cycle never shows a negative day count', () {
    // Last period started 43 days ago, 28-day cycle: expected 15 days
    // ago (the 6 Oct → 3 Nov case, relative to today so the test stays
    // true whenever it runs).
    final state = AppState();
    final today = dateOnly(DateTime.now());
    state.periods = [
      PeriodRange(
        today.subtract(const Duration(days: 43)),
        today.subtract(const Duration(days: 39)),
      ),
    ];
    expect(state.isOverdue, isTrue);
    expect(state.daysLate, 15);
    expect(state.daysToGoLabel, '15 days late');
    expect(state.daysToGoLabel, isNot(contains('-')));
    expect(state.cycleDayLabel, 'Day 44 · 15 days overdue');
    expect(state.cycleDayLabel, isNot(contains('of 28')));
    expect(state.nextOvulationDay, isNotNull);
    expect(dateOnly(state.nextOvulationDay!).isBefore(today), isFalse);
    expect(state.nextFertileDays, isNotEmpty);
    expect(
      dateOnly(state.nextFertileDays.last).isBefore(today),
      isFalse,
      reason:
          'next fertile window must not be fully in the past (it may start before today when today is inside it — ovulation − 4 .. + 1)',
    );
    expect(state.cyclesForReports.length, 1);
  });

  test('cycle still on time shows a positive countdown', () {
    final state = AppState();
    final today = dateOnly(DateTime.now());
    state.periods = [
      PeriodRange(
        today.subtract(const Duration(days: 5)),
        today.subtract(const Duration(days: 1)),
      ),
    ];
    expect(state.isOverdue, isFalse);
    expect(state.daysToGo, 23);
    expect(state.daysToGoLabel, 'in 23 days');
    expect(state.cycleDayLabel, 'Day 6 of 28');
  });

  test('date helpers and demo diet data', () {
    expect(dateKey(DateTime(2026, 11, 1)), '2026-11-01');
    expect(to12h('08:00'), '8:00 AM');
    expect(to12h('13:00'), '1:00 PM');
    expect(to12h('20:30'), '8:30 PM');
    expect(fmtRangeShort(DateTime(2026, 11, 1), DateTime(2026, 11, 5)),
        '1 Nov – 5 Nov');
    expect(demoMeals().length, 4);
    expect(demoMeals().first.title, 'Breakfast');
  });

  testWidgets('PeriBuds boots to the Home tab with empty period state',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    // runAsync: load() touches the notification plugin, whose platform
    // channels have no handler in tests — its timeouts need real timers,
    // and widget tests run in a fake-async zone where timers only move
    // when pumped. Without runAsync the load awaits forever.
    await tester.runAsync(() => state.load());
    expect(state.periods, isEmpty, reason: 'period side starts empty');
    expect(state.templateMeals.length, 4,
        reason: 'diet demo data is seeded');
    await tester.pumpWidget(PeriBudsApp(state: state));
    await tester.pump();
    expect(find.text('PeriBuds'), findsWidgets);
    expect(find.text('EXPECTED NEXT PERIOD'), findsOneWidget);
    expect(find.text('Not known yet'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Diet'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('overdue period shows "days late" on Home, never "-15"',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await tester.runAsync(() => state.load());
    final today = dateOnly(DateTime.now());
    state.periods = [
      PeriodRange(
        today.subtract(const Duration(days: 43)),
        today.subtract(const Duration(days: 39)),
      ),
    ];
    await tester.pumpWidget(PeriBudsApp(state: state));
    await tester.pump();
    expect(find.text('days late'), findsOneWidget);
    expect(find.textContaining('overdue'), findsWidgets);
    expect(find.textContaining('-15'), findsNothing);
    expect(find.textContaining('in -'), findsNothing);
    expect(find.textContaining('Day 44 of 28'), findsNothing);
  });
}
