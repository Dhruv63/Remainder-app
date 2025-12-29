import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'overlay_entry.dart';
import 'models/reminder.dart';
import 'services/storage_service.dart';
import 'widgets/reminder_card.dart';
import 'screens/add_reminder_screen.dart';

// Entry Point B: Overlay Entry Point
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: WalkingCharacter(
          onDismiss: () => FlutterOverlayWindow.closeOverlay(),
        ),
      ),
    ),
  );
}

// Alarm callback - runs in isolate
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  debugPrint('Alarm callback triggered for id: $id');
  
  // Show overlay
  if (await FlutterOverlayWindow.isPermissionGranted()) {
    await FlutterOverlayWindow.showOverlay(
      height: -1,
      width: -1,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      enableDrag: false,
    );
    
    // TTS - get message from storage
    final prefs = await SharedPreferences.getInstance();
    final message = prefs.getString('reminder_message_$id') ?? 'Tatakae! Time to take action!';
    
    final FlutterTts tts = FlutterTts();
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.5);
    await tts.speak(message);
    
    debugPrint('Overlay shown with message: $message');
  } else {
    debugPrint('Overlay permission not granted');
  }
}

// Entry Point A: Main Settings UI
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();
  debugPrint('AndroidAlarmManager initialized');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  List<Reminder> _reminders = [];
  bool _hasOverlayPermission = false;

  List<Reminder> get reminders => _reminders;
  bool get hasOverlayPermission => _hasOverlayPermission;

  Future<void> loadReminders() async {
    _reminders = await StorageService.getReminders();
    // Sort by date
    _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    await StorageService.addReminder(reminder);
    await loadReminders();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await StorageService.updateReminder(reminder);
    await loadReminders();
  }

  Future<void> deleteReminder(String id) async {
    await StorageService.deleteReminder(id);
    await loadReminders();
  }

  Future<void> toggleReminder(String id) async {
    await StorageService.toggleReminder(id);
    await loadReminders();
  }

  void setOverlayPermission(bool value) {
    _hasOverlayPermission = value;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tatakae Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _init() async {
    await context.read<AppState>().loadReminders();
    await _checkPermission();
    // Reschedule all active reminders on app start
    await _rescheduleAllReminders();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    if (mounted) {
      context.read<AppState>().setOverlayPermission(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeTab(),
          RemindersTab(),
          SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF667eea).withOpacity(0.3),
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Reminders',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _addReminder(context),
              backgroundColor: const Color(0xFF667eea),
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            )
          : null,
    );
  }

  Future<void> _addReminder(BuildContext context) async {
    final result = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(builder: (_) => const AddReminderScreen()),
    );
    if (result != null && mounted) {
      await context.read<AppState>().addReminder(result);
      await _scheduleReminder(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder scheduled for ${_formatTime(result.dateTime)}')),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours';
    } else {
      return '${diff.inDays} days';
    }
  }

  Future<void> _scheduleReminder(Reminder reminder) async {
    if (reminder.dateTime.isBefore(DateTime.now())) {
      debugPrint('Reminder ${reminder.id} is in the past, skipping');
      return;
    }

    // Store message in SharedPreferences for the alarm callback to retrieve
    final prefs = await SharedPreferences.getInstance();
    final alarmId = reminder.id.hashCode.abs() % 2147483647; // Ensure positive int32
    await prefs.setString('reminder_message_$alarmId', reminder.message);
    
    debugPrint('Scheduling reminder $alarmId for ${reminder.dateTime}');
    
    // Schedule exact alarm
    final success = await AndroidAlarmManager.oneShotAt(
      reminder.dateTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
    
    debugPrint('Alarm scheduled: $success');
  }

  // Reschedule all active reminders (called on app start)
  Future<void> _rescheduleAllReminders() async {
    final reminders = context.read<AppState>().reminders;
    int count = 0;
    for (final reminder in reminders) {
      if (reminder.isActive && reminder.dateTime.isAfter(DateTime.now())) {
        await _scheduleReminder(reminder);
        count++;
      }
    }
    debugPrint('Rescheduled $count reminders');
  }
}

// ============ HOME TAB ============
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              '🔥 Tatakae Reminder',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay motivated with character overlays',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 32),

            // Quick Test Button
            _buildQuickAction(
              context,
              icon: Icons.play_circle,
              title: 'Test Overlay Now',
              subtitle: 'See the walking character',
              color: const Color(0xFF667eea),
              onTap: () => _testOverlay(context),
            ),
            const SizedBox(height: 16),

            // Upcoming Reminder
            Consumer<AppState>(
              builder: (context, state, _) {
                final upcoming = state.reminders
                    .where((r) => r.isActive && r.dateTime.isAfter(DateTime.now()))
                    .toList();
                
                if (upcoming.isEmpty) {
                  return _buildEmptyState();
                }

                final next = upcoming.first;
                return _buildNextReminder(context, next);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_off, size: 48, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('No upcoming reminders', style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildNextReminder(BuildContext context, Reminder reminder) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF667eea)),
              const SizedBox(width: 8),
              const Text('Next Reminder', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Text(reminder.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMM d at h:mm a').format(reminder.dateTime),
            style: const TextStyle(color: Color(0xFF667eea)),
          ),
        ],
      ),
    );
  }

  Future<void> _testOverlay(BuildContext context) async {
    final hasPermission = context.read<AppState>().hasOverlayPermission;
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant overlay permission in Settings')),
      );
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      height: -1,
      width: -1,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      enableDrag: false,
    );

    final FlutterTts tts = FlutterTts();
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.5);
    await tts.speak('Tatakae! Time to take action!');
  }
}

// ============ REMINDERS TAB ============
class RemindersTab extends StatelessWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Reminders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Swipe left to delete', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<AppState>(
                builder: (context, state, _) {
                  if (state.reminders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('No reminders yet', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Tap + to create one', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = state.reminders[index];
                      return ReminderCard(
                        reminder: reminder,
                        onTap: () => _editReminder(context, reminder),
                        onDelete: () => context.read<AppState>().deleteReminder(reminder.id),
                        onToggle: () => context.read<AppState>().toggleReminder(reminder.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editReminder(BuildContext context, Reminder reminder) async {
    final result = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(builder: (_) => AddReminderScreen(existingReminder: reminder)),
    );
    if (result != null) {
      await context.read<AppState>().updateReminder(result);
    }
  }
}

// ============ SETTINGS TAB ============
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            
            // Overlay Permission
            Consumer<AppState>(
              builder: (context, state, _) {
                return _buildSettingsTile(
                  icon: state.hasOverlayPermission ? Icons.check_circle : Icons.warning_amber,
                  iconColor: state.hasOverlayPermission ? Colors.green : Colors.orange,
                  title: 'Overlay Permission',
                  subtitle: state.hasOverlayPermission ? 'Granted' : 'Required for reminders',
                  trailing: state.hasOverlayPermission
                      ? null
                      : ElevatedButton(
                          onPressed: () async {
                            await FlutterOverlayWindow.requestPermission();
                            final status = await FlutterOverlayWindow.isPermissionGranted();
                            context.read<AppState>().setOverlayPermission(status);
                          },
                          child: const Text('Grant'),
                        ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            _buildSettingsTile(
              icon: Icons.cancel,
              iconColor: Colors.red,
              title: 'Cancel All Reminders',
              subtitle: 'Remove all scheduled reminders',
              trailing: TextButton(
                onPressed: () async {
                  // Cancel all alarms by deleting reminders
                  final reminders = await StorageService.getReminders();
                  for (final r in reminders) {
                    final alarmId = r.id.hashCode.abs() % 2147483647;
                    await AndroidAlarmManager.cancel(alarmId);
                  }
                  await StorageService.saveReminders([]);
                  if (context.mounted) {
                    context.read<AppState>().loadReminders();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All reminders cancelled')),
                    );
                  }
                },
                child: const Text('Cancel All'),
              ),
            ),
            
            const Spacer(),
            Center(
              child: Text('Tatakae Reminder v1.0', style: TextStyle(color: Colors.white.withOpacity(0.3))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
