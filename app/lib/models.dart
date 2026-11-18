import 'utils.dart';

/// One logged period: start date + end date, inclusive.
/// Period side starts EMPTY — never seed fake ranges.
class PeriodRange {
  PeriodRange(this.start, this.end);

  final DateTime start; // date-only
  final DateTime end; // date-only, >= start

  int get lengthDays => end.difference(start).inDays + 1;

  bool contains(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  Map<String, dynamic> toJson() => {
        'start': dateKey(start),
        'end': dateKey(end),
      };

  factory PeriodRange.fromJson(Map<String, dynamic> json) => PeriodRange(
        parseKey(json['start'] as String),
        parseKey(json['end'] as String),
      );
}

/// One meal in a diet chart. Just what + when — no calories/macros/weight.
class Meal {
  Meal({
    required this.id,
    required this.title,
    required this.time24, // "08:00"
    required this.description,
    required this.type, // Breakfast / Lunch / Snack / Dinner
    this.repeat = 'today', // today | tomorrow | week | weekdays | pick
    this.pickDays = const <int>[], // weekday offsets 1..6 from today
    this.remind = true,
  });

  final String id;
  String title;
  String time24;
  String description;
  String type;
  String repeat;
  List<int> pickDays;
  bool remind;

  String get repeatLabel {
    switch (repeat) {
      case 'tomorrow':
        return 'Tomorrow';
      case 'week':
        return 'This week';
      case 'weekdays':
        return 'Weekdays';
      case 'pick':
        return pickDays.isEmpty ? 'Pick days' : 'Picked days';
      case 'today':
      default:
        return 'Today only';
    }
  }

  Meal copyWithNewId(String newId) => Meal(
        id: newId,
        title: title,
        time24: time24,
        description: description,
        type: type,
        repeat: 'today',
        pickDays: const [],
        remind: remind,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time24': time24,
        'description': description,
        'type': type,
        'repeat': repeat,
        'pickDays': pickDays,
        'remind': remind,
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Meal',
        time24: json['time24'] as String? ?? '08:00',
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? 'Breakfast',
        repeat: json['repeat'] as String? ?? 'today',
        pickDays: (json['pickDays'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        remind: json['remind'] as bool? ?? true,
      );
}

/// A custom reminder the user creates herself.
class CustomReminder {
  CustomReminder({
    required this.id,
    required this.text,
    required this.time24,
    this.on = true,
  });

  final String id;
  String text;
  String time24;
  bool on;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'time24': time24,
        'on': on,
      };

  factory CustomReminder.fromJson(Map<String, dynamic> json) =>
      CustomReminder(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        time24: json['time24'] as String? ?? '09:00',
        on: json['on'] as bool? ?? true,
      );
}

/// A trip, for the travel overlap warning + pack-pads checklist.
class Trip {
  Trip({required this.id, required this.start, required this.end});

  final String id;
  final DateTime start;
  final DateTime end;

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': dateKey(start),
        'end': dateKey(end),
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        start: parseKey(json['start'] as String),
        end: parseKey(json['end'] as String),
      );
}

/// The demo diet chart — DIET ONLY. No fake period data ever.
List<Meal> demoMeals() => [
      Meal(
        id: 'demo-1',
        title: 'Breakfast',
        time24: '08:00',
        description: 'Poha · 1 bowl, Curd',
        type: 'Breakfast',
      ),
      Meal(
        id: 'demo-2',
        title: 'Lunch',
        time24: '13:00',
        description: 'Dal, Rice, Salad',
        type: 'Lunch',
      ),
      Meal(
        id: 'demo-3',
        title: 'Evening snack',
        time24: '17:00',
        description: 'Fruit · 1 bowl, Green tea',
        type: 'Snack',
      ),
      Meal(
        id: 'demo-4',
        title: 'Dinner',
        time24: '20:30',
        description: 'Roti · 2, Sabzi, Dal',
        type: 'Dinner',
      ),
    ];

List<CustomReminder> demoReminders() => [
      CustomReminder(id: 'demo-r1', text: 'Drink water', time24: '11:00'),
      CustomReminder(id: 'demo-r2', text: 'Take iron tablet', time24: '21:00'),
    ];
