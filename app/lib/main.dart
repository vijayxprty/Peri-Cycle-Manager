import 'package:flutter/material.dart';

import 'notifications.dart';
import 'screens/calendar_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reports_screen.dart';
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
  int _tab = 0;

  void _goTo(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (!state.loaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: PB.rose),
        ),
      );
    }
    final pages = [
      HomeScreen(
        state: state,
        onGoToCalendar: () => _goTo(1),
        onGoToDiet: () => _goTo(2),
      ),
      CalendarScreen(state: state),
      DietScreen(state: state),
      ReportsScreen(
        state: state,
        onGoToCalendar: () => _goTo(1),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: _goTo,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: PB.rose,
        unselectedItemColor: PB.muted,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            label: 'Diet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
