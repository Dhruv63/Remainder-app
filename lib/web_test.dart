import 'package:flutter/material.dart';
import 'overlay_entry.dart';

/// Web Test App - Run with: flutter run -d chrome
/// This allows testing the walking animation without Android overlay dependencies
void main() {
  runApp(const WebTestApp());
}

class WebTestApp extends StatelessWidget {
  const WebTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walking Character Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const WebTestPage(),
    );
  }
}

class WebTestPage extends StatefulWidget {
  const WebTestPage({super.key});

  @override
  State<WebTestPage> createState() => _WebTestPageState();
}

class _WebTestPageState extends State<WebTestPage> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content (simulated app background)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🎮 Walking Character Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Test the overlay animation on web',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showOverlay = true),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Show Walking Character'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '✅ Animation should walk left to right',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '✅ Character loops continuously',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '✅ Red X button dismisses overlay',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Overlay (when shown)
          if (_showOverlay)
            WalkingCharacter(
              onDismiss: () => setState(() => _showOverlay = false),
            ),
        ],
      ),
    );
  }
}
