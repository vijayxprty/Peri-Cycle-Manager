import 'package:intl/intl.dart';

/// Date helpers. All dates are local, day-precision (midnight).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

final _shortMonth = DateFormat('MMM');
final _fullMonth = DateFormat('MMMM');
final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM yyyy');
final _weekdayDay = DateFormat('EEEE, d MMM');
final _weekdayFull = DateFormat('EEEE');
final _heroDate = DateFormat('EEEE · d MMMM');

String fmtWeekdayFull(DateTime d) => _weekdayFull.format(d);

/// "WEDNESDAY · 18 NOVEMBER" (uppercased by the caller) — hero eyebrow.
String fmtHeroDate(DateTime d) => _heroDate.format(d);

String fmtShortMonth(DateTime d) => _shortMonth.format(d);
String fmtFullMonth(DateTime d) => _fullMonth.format(d);
String fmtDayMonth(DateTime d) => _dayMonth.format(d);
String fmtDayMonthYear(DateTime d) => _dayMonthYear.format(d);
String fmtWeekdayDay(DateTime d) => _weekdayDay.format(d);

/// "1 Nov" / "5 Nov"
String fmtRangeShort(DateTime start, DateTime end) =>
    '${fmtDayMonth(start)} – ${fmtDayMonth(end)}';

/// "1 – 5 Nov 2026"
String fmtRangeLong(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month) {
    return '${start.day} – ${end.day} ${fmtShortMonth(start)} ${start.year}';
  }
  return '${fmtDayMonth(start)} – ${fmtDayMonth(end)} ${end.year}';
}

/// "8:00 AM" from "08:00" (24h).
String to12h(String time24) {
  final parts = time24.split(':');
  if (parts.length != 2) return time24;
  final h = int.tryParse(parts[0]) ?? 8;
  final m = parts[1];
  final ap = h >= 12 ? 'PM' : 'AM';
  var h12 = h % 12;
  if (h12 == 0) h12 = 12;
  return '$h12:$m $ap';
}

/// "08:00" (24h) from a [TimeOfDay]-like hour/minute.
String to24h(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Weekday abbreviation, Mon-first list of the 7 days of the week
/// containing [anchor] (Mon..Sun).
List<DateTime> weekDays(DateTime anchor) {
  final monday = dateOnly(anchor).subtract(
    Duration(days: dateOnly(anchor).weekday - 1),
  );
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayShortSunFirst = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Day names for pick-days blocks: THU / 19 / Nov.
String dowShort(DateTime d) => weekdayShortSunFirst[d.weekday % 7];
