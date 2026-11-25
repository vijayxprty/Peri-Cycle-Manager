import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'store.dart';
import 'utils.dart';

/// Discreet local notifications only — no server, no wording that says
/// "period" in the notification itself.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  bool _available = false;

  /// Best-effort: if the platform side is unavailable (or stalls),
  /// notifications are simply disabled — the app works fully without them.
  /// Every platform await is bounded so startup can never hang on this.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    try {
      await _initUnsafe().timeout(const Duration(seconds: 10));
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  Future<void> _initUnsafe() async {
    tzdata.initializeTimeZones();
    try {
      // Guarded: on some devices/emulators the timezone channel can stall.
      final name = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 5),
      );
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.local);
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin
        .initialize(const InitializationSettings(android: android, iOS: ios))
        .timeout(const Duration(seconds: 5));
    // Android runtime permission prompts are handled by the first-launch
    // permission primer, after the user has been told why reminders need it.
  }

  static const _androidDetails = AndroidNotificationDetails(
    'peribuds_reminders',
    'PeriBuds reminders',
    channelDescription: 'Gentle reminders about your cycle and meals.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _iosDetails = DarwinNotificationDetails();

  NotificationDetails get _details =>
      const NotificationDetails(android: _androidDetails, iOS: _iosDetails);

  Future<void> cancelAll() async {
    if (!_available) return;
    try {
      await _plugin.cancelAll().timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> _schedule(int id, String body, DateTime when) async {
    if (!_available) return;
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin
          .zonedSchedule(
            id,
            'PeriBuds',
            body,
            tz.TZDateTime.from(when, tz.local),
            _details,
            // Gentle reminders do not require the special exact-alarm access.
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Rebuild every scheduled reminder from current state.
  /// Period reminders are deliberately discreet: "A gentle reminder for you".
  Future<void> rescheduleAll(AppState state) async {
    await init();
    if (!_available) return;
    try {
      await _plugin.cancelAll().timeout(const Duration(seconds: 5));
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    final today = dateOnly(now);

    // --- Period reminders: 3 days before, 1 day before, morning of.
    final next = state.expectedNext;
    if (next != null && state.periodRemindersOn) {
      final d3 = dateOnly(next).subtract(const Duration(days: 3));
      final d1 = dateOnly(next).subtract(const Duration(days: 1));
      await _schedule(
        1001,
        'A gentle reminder for you — your expected date is in 3 days.',
        DateTime(d3.year, d3.month, d3.day, 9),
      );
      await _schedule(
        1002,
        'A gentle reminder for you — your expected date is tomorrow.',
        DateTime(d1.year, d1.month, d1.day, 9),
      );
      await _schedule(
        1003,
        'A gentle reminder for you.',
        DateTime(next.year, next.month, next.day, 8),
      );
    }

    // --- Meal reminders for today (only if the master toggle is on).
    if (state.mealRemindersOn) {
      var id = 2000;
      for (final meal in state.mealsForDay(today)) {
        if (!meal.remind) continue;
        final parts = meal.time24.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        final when = DateTime(today.year, today.month, today.day, hour, minute);
        if (when.isAfter(now)) {
          await _schedule(
            id++,
            'Time for ${meal.title} — ${meal.description}',
            when,
          );
        }
      }
      // --- Custom reminders for today.
      for (final r in state.customReminders) {
        if (!r.on) continue;
        final parts = r.time24.split(':');
        final hour = int.tryParse(parts[0]) ?? 9;
        final minute = int.tryParse(parts[1]) ?? 0;
        final when = DateTime(today.year, today.month, today.day, hour, minute);
        if (when.isAfter(now)) {
          await _schedule(id++, r.text, when);
        }
      }
    }
  }
}
