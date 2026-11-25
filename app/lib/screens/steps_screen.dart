import 'dart:async';

import 'package:flutter/material.dart';

import '../step_counter.dart';
import '../store.dart';
import '../theme.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final _counter = StepCounter();
  Timer? _dayTimer;
  String _status = 'Steps will be counted by your phone sensor.';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_startIfAllowed());
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final oldDay = widget.state.wellbeingDayKey;
      await widget.state.ensureWellbeingDay();
      if (oldDay != widget.state.wellbeingDayKey && await _counter.isGranted) {
        await _beginListening();
      }
    });
  }

  Future<void> _startIfAllowed() async {
    await widget.state.ensureWellbeingDay();
    if (!await _counter.isGranted) return;
    await _beginListening();
  }

  Future<void> _askPermission() async {
    setState(() => _loading = true);
    final granted = await _counter.requestPermission();
    if (!mounted) return;
    if (granted) {
      await _beginListening();
    } else {
      setState(() {
        _loading = false;
        _status = 'Activity permission is off. You can enable it in Settings.';
      });
    }
  }

  Future<void> _beginListening() async {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = 'Counting automatically · displayed in 8-step increments';
    });
    await _counter.start(
      widget.state.stepCount,
      (steps) {
        unawaited(widget.state.recordSensorSteps(steps));
      },
      (error) {
        if (mounted) {
          setState(() => _status = 'Step sensor unavailable on this device.');
        }
      },
    );
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    unawaited(_counter.stop());
    super.dispose();
  }

  Future<void> _editGoal() async {
    final controller = TextEditingController(text: '${widget.state.stepGoal}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily step goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Steps',
            suffixText: 'steps',
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
    if (value != null && value > 0) await widget.state.setStepGoal(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final progress = state.stepGoal < 1
        ? 0.0
        : (state.stepCount / state.stepGoal).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: [
        const _SectionTitle(
          title: 'Steps',
          eyebrow: 'WALKING & DAILY MOVEMENT',
        ),
        PBCard(
          child: Column(
            children: [
              SizedBox(
                width: 204,
                height: 204,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 192,
                      height: 192,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 13,
                        strokeCap: StrokeCap.round,
                        backgroundColor: PB.roseSoft,
                        valueColor: const AlwaysStoppedAnimation(PB.rose),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${state.stepCount}',
                          style: const TextStyle(
                            fontSize: 38,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: PB.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'steps today',
                          style: TextStyle(color: PB.softText),
                        ),
                        Text(
                          '${(progress * 100).round()}% of goal',
                          style: const TextStyle(
                            color: PB.rose,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
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
                    'Your daily goal',
                    style: TextStyle(color: PB.softText, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: _editGoal,
                    child: Text('${state.stepGoal} steps · Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: PBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CALORIES BURNED · ESTIMATE',
                      style: TextStyle(
                        fontSize: 10,
                        color: PB.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '~${state.stepCaloriesEstimate.round()} kcal',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TO YOUR GOAL',
                      style: TextStyle(
                        fontSize: 10,
                        color: PB.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${(state.stepGoal - state.stepCount).clamp(0, state.stepGoal)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'steps left',
                      style: TextStyle(fontSize: 11, color: PB.softText),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AUTOMATIC STEP COUNTING',
                style: TextStyle(
                  fontSize: 10,
                  color: PB.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.directions_walk, color: PB.rose),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PB.softText,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _loading ? null : _askPermission,
                    child: Text(_loading ? '…' : 'Allow'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The phone counts steps automatically after you allow activity access. Steps from earlier that day may not be included. The display advances in 8-step increments; there are no manual add or remove controls.',
                style: TextStyle(fontSize: 12, height: 1.5, color: PB.softText),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            'Calories are an estimate. Step sensing requires activity access and a supported phone sensor.',
            style: TextStyle(fontSize: 11, height: 1.5, color: PB.muted),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.eyebrow});
  final String title;
  final String eyebrow;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: PB.ink,
          ),
        ),
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: PB.muted,
          ),
        ),
      ],
    ),
  );
}
