import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'overlay_entry.dart';

// Entry Point A: Main Settings UI
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize WorkManager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ReminderState(),
      child: const MyApp(),
    ),
  );
}

// WorkManager callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // When the background task triggers, show the overlay
    if (await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.shareData("Tatakae! Time to take action!");
      await FlutterOverlayWindow.showOverlay(
        height: 300,
        width: 300,
        alignment: OverlayAlignment.center,
        enableDrag: true,
      );
    }
    return Future.value(true);
  });
}

// Entry Point B: Overlay Entry Point
// This is called when the overlay window is shown
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: AnimatedOverlayWidget(),
      ),
    ),
  );
}

class AnimatedOverlayWidget extends StatelessWidget {
  const AnimatedOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB6C1), Color(0xFFDDA0DD)],
          ),
          borderRadius: BorderRadius.circular(140),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF69B4).withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("\ud83e\udd8b", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 8),
            const Text(
              "Tatakae!",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Time to take action!",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => FlutterOverlayWindow.closeOverlay(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white38),
                ),
                child: const Text("Dismiss", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderState extends ChangeNotifier {
  bool _isOverlayActive = false;
  
  bool get isOverlayActive => _isOverlayActive;
  
  void setOverlayActive(bool value) {
    _isOverlayActive = value;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Character Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _hasOverlayPermission = false;
  int _reminderMinutes = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-check permissions when app resumes
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    setState(() {
      _hasOverlayPermission = status;
    });
  }

  Future<void> _requestOverlayPermission() async {
    final status = await FlutterOverlayWindow.requestPermission();
    setState(() {
      _hasOverlayPermission = status ?? false;
    });
    
    if (_hasOverlayPermission) {
      _showSnackBar('Overlay permission granted! ✓');
    } else {
      _showSnackBar('Overlay permission denied. Please enable it in settings.');
    }
  }

  Future<void> _testOverlay() async {
    if (!_hasOverlayPermission) {
      _showSnackBar('Please grant overlay permission first!');
      return;
    }

    try {
      // Show the overlay
      await FlutterOverlayWindow.showOverlay(
        height: 900,
        width: 900,
        alignment: OverlayAlignment.center,
        enableDrag: true,
      );
      
      // Speak in loop
      final FlutterTts tts = FlutterTts();
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.5);
      await tts.speak('Tatakae! Time to take action!');
      
      Provider.of<ReminderState>(context, listen: false).setOverlayActive(true);
      _showSnackBar('Overlay displayed!');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _scheduleReminder() async {
    if (!_hasOverlayPermission) {
      _showSnackBar('Please grant overlay permission first!');
      return;
    }

    // Cancel any existing tasks
    await Workmanager().cancelAll();
    
    // Schedule a one-time task
    await Workmanager().registerOneOffTask(
      'reminder-task',
      'showOverlay',
      initialDelay: Duration(minutes: _reminderMinutes),
      inputData: {
        'message': 'Tatakae! Your reminder is here!',
      },
    );
    
    _showSnackBar('Reminder scheduled for $_reminderMinutes minutes from now!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Character Reminder',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A237E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay motivated with overlay reminders',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Permission Status Card
                _buildCard(
                  child: Column(
                    children: [
                      Icon(
                        _hasOverlayPermission ? Icons.check_circle : Icons.warning_amber,
                        size: 48,
                        color: _hasOverlayPermission ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _hasOverlayPermission
                            ? 'Overlay Permission Granted'
                            : 'Overlay Permission Required',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasOverlayPermission
                            ? 'You can now show character overlays'
                            : 'Tap below to grant permission',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_hasOverlayPermission) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _requestOverlayPermission,
                          icon: const Icon(Icons.security),
                          label: const Text('Grant Permission'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Reminder Duration Selector
                _buildCard(
                  child: Column(
                    children: [
                      const Text(
                        'Reminder Duration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_reminderMinutes > 1) {
                                setState(() => _reminderMinutes--);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_reminderMinutes min',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_reminderMinutes < 120) {
                                setState(() => _reminderMinutes++);
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                ElevatedButton.icon(
                  onPressed: _testOverlay,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Test Overlay Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _scheduleReminder,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Schedule Reminder'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    await Workmanager().cancelAll();
                    _showSnackBar('All reminders cancelled');
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel All Reminders'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
