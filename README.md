# Character Overlay Reminder App

A Flutter Android app that displays a floating character overlay over other apps when a reminder timer triggers.

## Features

✨ **Overlay Window**: Shows a beautiful animated character that floats over all other apps
🔔 **Background Reminders**: Schedule reminders that trigger even when the app is closed
⚙️ **Customizable Duration**: Set reminder intervals from 1 to 120 minutes
🎨 **Modern UI**: Beautiful gradient design with smooth animations
🔒 **Permission Management**: Easy-to-use overlay permission request flow

## Architecture

### Two Entry Points

1. **Entry Point A** (`main.dart`): Main settings UI where users can:
   - Grant overlay permission
   - Test the overlay immediately
   - Schedule background reminders
   - Set reminder duration

2. **Entry Point B** (`overlay_entry.dart`): The floating overlay widget that:
   - Displays an animated character
   - Shows custom messages
   - Can be dragged around the screen
   - Has a dismiss button to close

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Overlay Entry Point

You need to tell `flutter_overlay_window` where the overlay entry point is. Add this to your `pubspec.yaml`:

```yaml
flutter_overlay_window:
  overlay_main: lib/overlay_entry.dart
```

Or, register it programmatically in `main.dart` (already included):

```dart
FlutterOverlayWindow.overlayMain = overlayMain;
```

### 3. Build and Run

```bash
flutter run
```

**Note**: Overlay functionality only works on physical Android devices or emulators running API 24+.

## Permissions

The app requires the following permissions (already configured in `AndroidManifest.xml`):

- `SYSTEM_ALERT_WINDOW`: To draw over other apps
- `FOREGROUND_SERVICE`: To run the overlay service
- `WAKE_LOCK`: To wake the device when reminder triggers
- `RECEIVE_BOOT_COMPLETED`: To restore reminders after device restart
- `POST_NOTIFICATIONS`: To show notifications (Android 13+)

## How to Use

1. **First Launch**: Grant overlay permission when prompted
2. **Test Overlay**: Tap "Test Overlay Now" to see the character immediately
3. **Schedule Reminder**: 
   - Set your desired duration using +/- buttons
   - Tap "Schedule Reminder"
   - The overlay will appear after the specified time
4. **Dismiss Overlay**: Tap the red X button on the overlay to close it

## Customization

### Change Character Icon

Replace the placeholder icon in `overlay_entry.dart`:

```dart
// Current: Generic person icon
const Icon(Icons.person, size: 50, color: Colors.white)

// Replace with your image:
Image.asset('assets/images/character.png', width: 80, height: 80)
```

Don't forget to add your image to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/character.png
```

### Customize Messages

In `main.dart`, change the message sent to the overlay:

```dart
await FlutterOverlayWindow.shareData("Your custom message here!");
```

### Adjust Overlay Size

In `main.dart`, modify the overlay dimensions:

```dart
await FlutterOverlayWindow.showOverlay(
  height: 300,  // Change height
  width: 300,   // Change width
  alignment: OverlayAlignment.center,  // center, topLeft, bottomRight, etc.
  enableDrag: true,
);
```

### Change Colors

Update the gradient colors in `overlay_entry.dart`:

```dart
gradient: const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF667eea),  // Your color 1
    Color(0xFF764ba2),  // Your color 2
  ],
),
```

## Troubleshooting

### Overlay Not Showing

1. Check if overlay permission is granted
2. Verify you're running on a physical device or emulator (API 24+)
3. Check logcat for errors: `flutter logs`

### Background Task Not Triggering

1. Ensure the app is not battery optimized (Android settings)
2. Check WorkManager logs
3. Verify permissions are granted

### Build Errors

If you encounter build errors:

```bash
flutter clean
flutter pub get
flutter run
```

## Tech Stack

- **flutter_overlay_window** (v0.4.7): Overlay window functionality
- **workmanager** (v0.5.2): Background task scheduling
- **provider** (v6.1.1): State management
- **permission_handler** (v11.1.0): Runtime permission handling

## Minimum Requirements

- Flutter SDK: 3.0.0+
- Dart SDK: 3.0.0+
- Android SDK: API 24 (Android 7.0) or higher
- Target SDK: Latest

## Next Steps

- [ ] Add custom character images
- [ ] Implement different character animations
- [ ] Add sound effects when overlay appears
- [ ] Create multiple reminder presets
- [ ] Add notification support
- [ ] Implement reminder history

## License

This project is open source and available for personal and commercial use.
