# libuiohook FFI Integration

## Overview

This implementation integrates libuiohook using Dart FFI for cross-platform native input injection on desktop platforms (macOS, Linux, Windows). Android continues to use the MethodChannel approach for platform-specific input injection.

## Architecture

### Files

- **uiohook_ffi.dart**: FFI bindings for libuiohook C library
  - Event type constants (EVENT_KEY_PRESSED, EVENT_MOUSE_MOVED, etc.)
  - Virtual key codes (VC_A-Z, VC_0-9, etc.)
  - FFI struct classes (UiohookEvent, KeyboardEventData, MouseEventData, etc.)
  - UiohookBindings: Loads platform-specific library and exposes FFI functions
  - UiohookEventHelper: High-level API for posting events
  - sdlToUiohookKeycode: Converts SDL key codes to uiohook virtual key codes

- **input_injector.dart**: Cross-platform input injection service
  - Detects platform and chooses FFI (desktop) or MethodChannel (Android)
  - Handles mouse absolute/relative positioning, wheel scrolling
  - Handles keyboard events with modifier keys
  - Tracks button state changes for proper press/release events

## Setup

### Building libuiohook

The library is already compiled for macOS:

```bash
cd third_party/libuiohook
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
cmake --build build --config Release
```

The compiled library is located at:
- macOS: `third_party/libuiohook/build/libuiohook.dylib`
- Linux: `third_party/libuiohook/build/libuiohook.so`
- Windows: `third_party/libuiohook/build/uiohook.dll`

### Deploying Libraries

For macOS, the library is copied to the app bundle:
```bash
cp -L third_party/libuiohook/build/libuiohook.dylib macos/Runner/Frameworks/
```

For Linux and Windows, you'll need to:
1. Build the library on the target platform
2. Copy to appropriate location (system library path or app bundle)

## Usage

### Initialization

```dart
final injector = InputInjector();
await injector.initialize(); // Automatically detects platform
```

### Mouse Events

```dart
// Absolute positioning
await injector.injectMouseAbsolute(
  x: 0.5,           // Normalized 0.0-1.0
  y: 0.5,
  displayW: 1920,
  displayH: 1080,
  buttons: 0x01,    // Left button pressed
);

// Mouse wheel
await injector.injectMouseWheel(dx: 0.0, dy: -1.0);
```

### Keyboard Events

```dart
// Press key
await injector.injectKeyboard(
  key: 'a',
  code: 97,        // SDL keycode
  down: true,
  mods: 0x0001,    // Shift modifier
);

// Release key
await injector.injectKeyboard(
  key: 'a',
  code: 97,
  down: false,
  mods: 0x0000,
);
```

## Key Code Mapping

SDL key codes are automatically converted to uiohook virtual key codes:

- **Letters**: SDL 97-122 (a-z) → VC_A-Z
- **Numbers**: SDL 48-57 (0-9) → VC_0-9
- **Function Keys**: SDL 1073741882-1073741893 → VC_F1-F12
- **Arrows**: SDL 1073741903-1073741906 → VC_LEFT/RIGHT/UP/DOWN
- **Modifiers**: SDL 1073742048+ → VC_CONTROL_L/SHIFT_L/ALT_L/META_L

## Button and Modifier Masks

### Mouse Buttons
- Bit 0: Left button (0x01)
- Bit 1: Right button (0x02)
- Bit 2: Middle button (0x04)
- Bit 3: Button 4 (0x08)
- Bit 4: Button 5 (0x10)

### Keyboard Modifiers
- Bit 0: Shift (0x0001)
- Bit 1: Ctrl (0x0002)
- Bit 2: Alt (0x0004)
- Bit 3: Meta/Win (0x0008)

## Platform Notes

### macOS
- Requires Accessibility permissions
- Grant in System Preferences → Security & Privacy → Privacy → Accessibility
- Library loaded from app bundle

### Linux
- May require X11 XTEST extension
- Install: `sudo apt-get install libxtst-dev`
- May need to run with appropriate permissions

### Windows
- Should work without special permissions
- Library must be in system PATH or app directory

### Android
- Uses MethodChannel with native Kotlin plugin
- Requires INJECT_EVENTS permission (system app only for global injection)
- Falls back to accessibility service approach if needed

## Limitations

1. **Relative Mouse Movement**: libuiohook doesn't support relative moves directly; we use absolute positioning instead
2. **Android FFI**: Not supported; continues using MethodChannel approach
3. **Permissions**: Desktop platforms may require accessibility/input permissions
4. **Button Tracking**: Button state must be tracked for proper press/release events

## Testing

To test the FFI integration:

1. Build and run the app on macOS:
   ```bash
   flutter run -d macos
   ```

2. Connect to a remote session as controller

3. Send input events and verify they're injected on the host machine

4. Check logs for FFI vs MethodChannel usage:
   ```
   [InputInjector] Input injector initialized with FFI
   [InputInjector] Injected mouse abs (FFI): (960, 540) buttons=0
   [InputInjector] Injected keyboard (FFI): key=a vc=30 down=true mods=0
   ```

## Troubleshooting

### "Library not found" error
- Verify library is in correct location
- Check library path in uiohook_ffi.dart
- Try using absolute path or DynamicLibrary.process()

### Events not injecting
- Check platform permissions (Accessibility on macOS)
- Verify key code mappings are correct
- Check logs for error messages

### Button events not working
- Ensure button state tracking is working
- Verify button mask conversion in _buttonsToMask()
- Check that button changes are detected correctly
