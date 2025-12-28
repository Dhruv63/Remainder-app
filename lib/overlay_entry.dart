import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionally import overlay - it only works on Android
// ignore: uri_does_not_exist
// import 'package:flutter_overlay_window/flutter_overlay_window.dart' if (dart.library.html) '';

class WalkingCharacter extends StatefulWidget {
  final VoidCallback? onDismiss; // Optional callback for web testing
  
  const WalkingCharacter({super.key, this.onDismiss});

  @override
  State<WalkingCharacter> createState() => _WalkingCharacterState();
}

class _WalkingCharacterState extends State<WalkingCharacter>
    with TickerProviderStateMixin {
  late AnimationController _walkController;

  @override
  void initState() {
    super.initState();
    
    // Walking animation - 8 seconds to cross the screen
    _walkController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Start walking loop
    _walkController.repeat();
  }

  @override
  void dispose() {
    _walkController.dispose();
    super.dispose();
  }

  void _closeOverlay() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
    // On Android, this would call FlutterOverlayWindow.closeOverlay()
    // but we handle that in main.dart now
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: screenWidth,
      height: screenHeight,
      color: kIsWeb ? Colors.black.withOpacity(0.3) : Colors.transparent,
      child: Stack(
        children: [
          // Animated walking character using AnimatedBuilder
          AnimatedBuilder(
            animation: _walkController,
            builder: (context, child) {
              // Calculate position: -100 (off left) to screenWidth (off right)
              final double leftPos = -100.0 + (_walkController.value * (screenWidth + 100.0));
              
              return Positioned(
                left: leftPos,
                top: (screenHeight / 2) - 60,
                child: child!,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Speech bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Tatakae!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Character image from assets
                Image.asset(
                  'assets/images/character.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback purple circle with icon
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Dismiss button - bottom right, always visible (avoids notch/status bar)
          Positioned(
            bottom: 100,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _closeOverlay,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
