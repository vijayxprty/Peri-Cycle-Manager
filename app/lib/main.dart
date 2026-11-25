import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications.dart';
import 'step_counter.dart';
import 'screens/calendar_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/water_screen.dart';
import 'store.dart';
import 'theme.dart';

/// PeriBuds — period tracker + diet companion.
/// Fully offline: local storage only, no account, no cloud, no backend.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  // Notifications are best-effort: the app works fully without them.
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.rescheduleAll(state);
  } catch (_) {}
  runApp(PeriBudsApp(state: state));
}

class PeriBudsApp extends StatelessWidget {
  const PeriBudsApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'PeriBuds',
          debugShowCheckedModeBanner: false,
          theme: PB.theme(),
          home: _Shell(state: state),
        );
      },
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell({required this.state});

  final AppState state;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  // Home is the raised, highlighted middle destination in the floating dock.
  int _tab = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFirstLaunchPermissions();
    });
  }

  Future<void> _requestFirstLaunchPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final prefs = await SharedPreferences.getInstance();
    const askedKey = 'android_permissions_explained_v1';
    if (prefs.getBool(askedKey) == true) return;

    final activityGranted =
        (await Permission.activityRecognition.status).isGranted;
    final notificationsGranted =
        (await Permission.notification.status).isGranted;
    if (activityGranted && notificationsGranted) {
      await prefs.setBool(askedKey, true);
      return;
    }
    if (!mounted) return;

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make the most of PeriBuds'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allow these optional permissions for the features you use?'),
            SizedBox(height: 12),
            Text('• Physical activity — count your steps automatically.'),
            SizedBox(height: 8),
            Text('• Notifications — receive the reminders you turn on.'),
            SizedBox(height: 12),
            Text('Your health and cycle data stays on this device.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (allow == true) {
      if (!activityGranted) {
        await StepCounter().requestPermission();
      }
      if (!notificationsGranted) {
        await Permission.notification.request();
      }
    }
    await prefs.setBool(askedKey, true);
  }

  void _goTo(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (!state.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: PB.rose)),
      );
    }
    final pages = [
      CalendarScreen(state: state),
      DietScreen(state: state),
      HomeScreen(
        state: state,
        onGoToCalendar: () => _goTo(0),
        onGoToDiet: () => _goTo(1),
        onGoToSteps: () => _goTo(5),
        onGoToWater: () => _goTo(6),
      ),
      ReportsScreen(state: state, onGoToCalendar: () => _goTo(0)),
      SettingsScreen(state: state),
      StepsScreen(state: state),
      WaterScreen(state: state),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: PB.line),
              boxShadow: [
                BoxShadow(
                  color: PB.ink.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              height: 66,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DockItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Calendar',
                    selected: _tab == 0,
                    onTap: () => _goTo(0),
                  ),
                  _DockItem(
                    icon: Icons.restaurant_outlined,
                    label: 'Diet',
                    selected: _tab == 1,
                    onTap: () => _goTo(1),
                  ),
                  _DockItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: _tab == 2,
                    raised: true,
                    onTap: () => _goTo(2),
                  ),
                  _DockItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    selected: _tab == 3,
                    onTap: () => _goTo(3),
                  ),
                  _DockItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: _tab == 4,
                    onTap: () => _goTo(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.raised = false,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool raised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (raised)
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(top: -20, bottom: -1),
              decoration: BoxDecoration(
                color: PB.rose,
                shape: BoxShape.circle,
                border: Border.all(color: PB.bg, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: PB.rose.withValues(alpha: .3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            )
          else
            Icon(icon, color: selected ? PB.rose : PB.muted, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? PB.rose : PB.muted,
            ),
          ),
        ],
      ),
    ),
  );
}
