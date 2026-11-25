import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../step_counter.dart';
import '../store.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _steps = StepCounter();
  String _activityStatus = 'Checking';
  String _notificationStatus = 'Checking';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final activity = await _steps.isGranted;
    final notifications = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _activityStatus = activity ? 'Allowed' : 'Not allowed';
      _notificationStatus = notifications.isGranted ? 'Allowed' : 'Not allowed';
    });
  }

  Future<void> _requestActivity() async {
    if (await _steps.isGranted) {
      await openAppSettings();
    } else {
      await _steps.requestPermission();
    }
    await _refreshPermissions();
  }

  Future<void> _requestNotifications() async {
    if ((await Permission.notification.status).isGranted) {
      await openAppSettings();
    } else {
      await Permission.notification.request();
    }
    await _refreshPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: PB.ink,
          ),
        ),
        const Text(
          'PERMISSIONS & PREFERENCES',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: PB.muted,
          ),
        ),
        const SizedBox(height: 14),
        const _Label('PERMISSIONS'),
        PBCard(
          child: Column(
            children: [
              _PermissionRow(
                icon: Icons.directions_walk,
                title: 'Physical activity',
                detail: 'Needed for automatic step counting.',
                status: _activityStatus,
                onTap: _requestActivity,
              ),
              const Divider(height: 1, color: PB.line),
              _PermissionRow(
                icon: Icons.notifications_none,
                title: 'Notifications',
                detail: 'Used for reminders you choose.',
                status: _notificationStatus,
                onTap: _requestNotifications,
              ),
              const SizedBox(height: 9),
              const Text(
                'PeriBuds remains usable when either permission is off. Water logging does not need device access.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: PB.softText,
                ),
              ),
            ],
          ),
        ),
        const _Label('REMINDERS'),
        PBCard(
          child: Column(
            children: [
              _ToggleRow(
                title: 'Discreet period reminders',
                detail: 'Gentle reminders around your expected date.',
                value: state.periodRemindersOn,
                onChanged: state.setPeriodRemindersOn,
              ),
              const Divider(height: 1, color: PB.line),
              _ToggleRow(
                title: 'Meal reminders',
                detail: 'Reminders for meals you choose.',
                value: state.mealRemindersOn,
                onChanged: state.setMealRemindersOn,
              ),
            ],
          ),
        ),
        const _Label('YOUR DATA'),
        const PBCard(
          child: Text(
            'Your period, meal, step, and water records stay in PeriBuds’ local storage on this device. No account or cloud sync.',
            style: TextStyle(fontSize: 12, height: 1.5, color: PB.softText),
          ),
        ),
        const _Label('SUPPORT THE DEVELOPER'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [PB.roseSoft, PB.lavender]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enjoying PeriBuds?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your support helps the developer maintain and improve the app.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: PB.softText,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Add the developer’s donation link or QR to enable donations.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.favorite_border, size: 18),
                label: const Text('Donate to developer'),
              ),
            ],
          ),
        ),
        const _Label('CREDITS'),
        const PBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PeriBuds',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                'Independently designed and developed.',
                style: TextStyle(fontSize: 12, color: PB.softText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'PeriBuds · Made with care · v1.1.2',
            style: TextStyle(fontSize: 10, color: PB.muted),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 7),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: PB.muted,
      ),
    ),
  );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.onTap,
  });
  final IconData icon;
  final String title, detail, status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PB.roseSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: PB.rose, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$detail  ·  $status',
                style: const TextStyle(fontSize: 10, color: PB.softText),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(status == 'Allowed' ? 'Manage' : 'Allow'),
        ),
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });
  final String title, detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(fontSize: 10, color: PB.softText),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: PB.rose),
      ],
    ),
  );
}
