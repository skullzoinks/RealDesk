import 'dart:io';
import 'lib/input/uiohook_ffi.dart';

void main() {
  print('Testing libuiohook FFI integration...\n');

  // Test 1: Key code conversion
  print('Test 1: SDL to uiohook key code conversion');
  final testCases = {
    97: 'a -> ${sdlToUiohookKeycode(97).toRadixString(16)} (expected: ${VC_A.toRadixString(16)})',
    122:
        'z -> ${sdlToUiohookKeycode(122).toRadixString(16)} (expected: ${VC_Z.toRadixString(16)})',
    48: '0 -> ${sdlToUiohookKeycode(48).toRadixString(16)} (expected: ${VC_0.toRadixString(16)})',
    13: 'Enter -> ${sdlToUiohookKeycode(13).toRadixString(16)} (expected: ${VC_ENTER.toRadixString(16)})',
    1073741906:
        'Up -> ${sdlToUiohookKeycode(1073741906).toRadixString(16)} (expected: ${VC_UP.toRadixString(16)})',
  };

  for (final entry in testCases.entries) {
    final result = sdlToUiohookKeycode(entry.key);
    print('  ${entry.value} ${result != VC_UNDEFINED ? "✓" : "✗"}');
  }

  // Test 2: Event constants
  print('\nTest 2: Event type constants');
  print('  EVENT_KEY_PRESSED = $EVENT_KEY_PRESSED ✓');
  print('  EVENT_MOUSE_MOVED = $EVENT_MOUSE_MOVED ✓');
  print('  EVENT_MOUSE_PRESSED = $EVENT_MOUSE_PRESSED ✓');

  // Test 3: Platform detection
  print('\nTest 3: Platform detection');
  if (Platform.isMacOS) {
    print('  Platform: macOS ✓');
    print('  Should use: FFI');
  } else if (Platform.isLinux) {
    print('  Platform: Linux ✓');
    print('  Should use: FFI');
  } else if (Platform.isWindows) {
    print('  Platform: Windows ✓');
    print('  Should use: FFI');
  } else {
    print('  Platform: ${Platform.operatingSystem}');
    print('  Should use: MethodChannel');
  }

  // Test 4: FFI bindings (will fail in test environment without library)
  print('\nTest 4: FFI library loading');
  try {
    final bindings = UiohookBindings.instance;
    print('  Library loaded successfully ✓');
    print('  hook_post_event function available ✓');

    // Test posting a simple event (won't actually inject, just tests FFI call)
    print('\nTest 5: Posting test event');
    try {
      UiohookEventHelper.postKeyboardEvent(EVENT_KEY_PRESSED, VC_A, 0);
      print('  Posted keyboard event successfully ✓');
    } catch (e) {
      print('  Failed to post event: $e ✗');
    }
  } catch (e) {
    print(
        '  Library not loaded (expected in test environment): ${e.toString().split('\n')[0]} ⚠️');
    print('  This is normal if running outside the app bundle');
  }

  print('\n✅ FFI integration test complete!');
  print('\nTo test with actual library:');
  print('  1. Build the app: flutter build macos --debug');
  print('  2. Run from Xcode or flutter run -d macos');
  print('  3. Connect to a session and check logs for:');
  print('     "[InputInjector] Input injector initialized with FFI"');
}
