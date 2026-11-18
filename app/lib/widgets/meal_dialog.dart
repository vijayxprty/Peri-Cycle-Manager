import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';

/// Add / Edit meal as a POPUP (not an inline form).
///
/// Fields: free Title (she names it), Time picker (shows as 8:00 AM),
/// Description, meal-type chips, Repeat (Today only / Tomorrow / This week /
/// Weekdays / Pick days), Remind-me toggle, Save / Cancel.
/// Pick-days blocks show day + date number + month clearly
/// (e.g. THU / 19 / Nov) — big bold date number, dark on white,
/// white on rose when selected.
Future<Meal?> showMealDialog(
  BuildContext context,
  AppState state, {
  Meal? existing,
}) {
  return showModalBottomSheet<Meal>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MealDialog(state: state, existing: existing),
  );
}

class _MealDialog extends StatefulWidget {
  const _MealDialog({required this.state, this.existing});

  final AppState state;
  final Meal? existing;

  @override
  State<_MealDialog> createState() => _MealDialogState();
}

class _MealDialogState extends State<_MealDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TimeOfDay _time;
  late String _type;
  late String _repeat;
  late List<int> _pickDays;
  late bool _remind;

  static const _types = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
  static const _repeats = [
    ('today', 'Today only'),
    ('tomorrow', 'Tomorrow'),
    ('week', 'This week'),
    ('weekdays', 'Weekdays'),
    ('pick', 'Pick days'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      final parts = e.time24.split(':');
      _time = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      _time = const TimeOfDay(hour: 8, minute: 0);
    }
    _type = e?.type ?? 'Breakfast';
    _repeat = e?.repeat ?? 'today';
    _pickDays = List<int>.from(e?.pickDays ?? []);
    _remind = e?.remind ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String get _time12h {
    final h = _time.hour;
    final ap = h >= 12 ? 'PM' : 'AM';
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${_time.minute.toString().padLeft(2, '0')} $ap';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Meal time',
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your meal a name first.')),
      );
      return;
    }
    final meal = Meal(
      id: widget.existing?.id ??
          '${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      time24: to24h(_time.hour, _time.minute),
      description: _descCtrl.text.trim(),
      type: _type,
      repeat: _repeat,
      pickDays: _pickDays,
      remind: _remind,
    );
    Navigator.of(context).pop(meal);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final today = dateOnly(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
            bottom: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit meal' : 'Add meal',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: PB.softText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Name it your way, pick a time, and choose when it repeats.',
                style: TextStyle(fontSize: 13, color: PB.muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _types
                    .map(
                      (t) => _Chip(
                        label: t,
                        selected: _type == t,
                        onTap: () => setState(() {
                          _type = t;
                          if (_titleCtrl.text.isEmpty) {
                            _titleCtrl.text = t;
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              const _FieldLabel('Name your meal'),
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: _inputDecoration('e.g. Breakfast, Green smoothie'),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Time'),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE8C9C4),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _time12h,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: PB.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Shows as'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _time12h,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: PB.rose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const _FieldLabel('Description'),
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                style: const TextStyle(fontSize: 15),
                decoration:
                    _inputDecoration('e.g. Poha · 1 bowl, Curd'),
              ),
              const _FieldLabel('Repeat'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _repeats
                    .map(
                      (r) => _Chip(
                        label: r.$2,
                        selected: _repeat == r.$1,
                        onTap: () => setState(() {
                          _repeat = r.$1;
                          if (_repeat == 'pick' && _pickDays.isEmpty) {
                            _pickDays = [1];
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              if (_repeat == 'pick') ...[
                const SizedBox(height: 10),
                // Every block shows day + date number + month clearly.
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.35,
                  children: List.generate(6, (i) {
                    final day = today.add(Duration(days: i + 1));
                    final selected = _pickDays.contains(i + 1);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _pickDays.remove(i + 1);
                        } else {
                          _pickDays.add(i + 1);
                        }
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? PB.rose : Colors.white,
                          border: Border.all(
                            color:
                                selected ? PB.rose : const Color(0xFFE8C9C4),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dowShort(day),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: selected
                                    ? Colors.white
                                    : PB.softText,
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
                                    : PB.softText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 16),
              // Remind row is plain in the reference (no coloured bg).
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remind me when due',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _remind,
                    onChanged: (v) => setState(() => _remind = v),
                    activeThumbColor: PB.rose,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE8C9C4),
                          width: 1.5,
                        ),
                        foregroundColor: PB.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PB.rose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        elevation: 4,
                        shadowColor: PB.rose.withValues(alpha: 0.35),
                      ),
                      child: Text(
                        isEdit ? 'Save changes' : 'Add meal',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: PB.muted, fontSize: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8C9C4), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8C9C4), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PB.rose, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 5),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: PB.muted,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? PB.rose : Colors.white,
          border: Border.all(
            color: selected ? PB.rose : const Color(0xFFE8C9C4),
            width: 1.5,
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : PB.ink,
          ),
        ),
      ),
    );
  }
}
