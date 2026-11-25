import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key, required this.state});
  final AppState state;

  Future<void> _editGoal(BuildContext context) async {
    final controller = TextEditingController(text: '${state.waterGoalMl}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily water target'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Millilitres',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) await state.setWaterGoalMl(value);
  }

  @override
  Widget build(BuildContext context) {
    final progress = state.waterGoalMl < 1
        ? 0.0
        : (state.waterTodayMl / state.waterGoalMl).clamp(0.0, 1.0).toDouble();
    final percent = state.waterGoalMl < 1
        ? 0
        : ((state.waterTodayMl / state.waterGoalMl) * 100).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: [
        const Text(
          'Water',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: PB.ink,
          ),
        ),
        const Text(
          'DAILY INTAKE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: PB.muted,
          ),
        ),
        const SizedBox(height: 14),
        PBCard(
          child: Column(
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 158,
                      height: 158,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFE8F5FA),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF55A8CC),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(state.waterTodayMl / 1000).toStringAsFixed(2)} L',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: PB.ink,
                          ),
                        ),
                        Text(
                          '$percent% of your target',
                          style: const TextStyle(
                            fontSize: 11,
                            color: PB.softText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your daily target',
                    style: TextStyle(fontSize: 13, color: PB.softText),
                  ),
                  TextButton(
                    onPressed: () => _editGoal(context),
                    child: Text('${state.waterGoalMl} ml · Edit'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _AmountButton(
                      label: '150 ml',
                      onTap: () => state.addWater(150),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountButton(
                      label: '250 ml',
                      onTap: () => state.addWater(250),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountButton(
                      label: 'Other',
                      onTap: () => _customAmount(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today’s water',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${state.waterEntries.length} drinks',
                    style: const TextStyle(fontSize: 11, color: PB.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.waterEntries.isEmpty)
                const Text(
                  'No drinks logged yet. Tap an amount above to record one.',
                  style: TextStyle(
                    color: PB.softText,
                    fontSize: 12,
                    height: 1.5,
                  ),
                )
              else ...[
                for (final entry in state.waterEntries.reversed.take(12))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.water_drop_outlined,
                          size: 18,
                          color: Color(0xFF55A8CC),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry['ml']} ml',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _time(entry['time'] as String?),
                          style: const TextStyle(fontSize: 11, color: PB.muted),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: state.undoLastWater,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Undo latest'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Text(
          'Set a personal target that works for you. This tracker records your intake; it does not prescribe how much you should drink.',
          style: TextStyle(fontSize: 11, height: 1.5, color: PB.muted),
        ),
      ],
    );
  }

  Future<void> _customAmount(BuildContext context) async {
    final controller = TextEditingController(text: '300');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log water'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) await state.addWater(value);
  }

  static String _time(String? value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return '';
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    return '$hour:${parsed.minute.toString().padLeft(2, '0')} ${parsed.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _AmountButton extends StatelessWidget {
  const _AmountButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF3F84A5),
      side: const BorderSide(color: Color(0xFFCFE7F2)),
      backgroundColor: const Color(0xFFF2FAFE),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}
